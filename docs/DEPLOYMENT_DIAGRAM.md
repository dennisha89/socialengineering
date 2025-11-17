# Infrastructure Architecture Diagrams

## 1. High-Level Architecture

```
                                   ┌─────────────┐
                                   │   Route 53  │
                                   │     DNS     │
                                   └──────┬──────┘
                                          │
                       ┌──────────────────┼──────────────────┐
                       │                  │                  │
                  ┌────▼────┐      ┌─────▼──────┐    ┌─────▼──────┐
                  │CloudFront│     │CloudFront  │    │   Route53  │
                  │ (Static) │     │   (API)    │    │ Failover   │
                  └────┬─────┘      └─────┬──────┘    └─────┬──────┘
                       │                  │                  │
                  ┌────▼────┐       ┌────▼────┐       ┌─────▼──────┐
                  │    S3   │       │   ALB   │       │ ALB (DR)   │
                  │ Static  │       │         │       │ us-west-2  │
                  │ Assets  │       └────┬────┘       └────────────┘
                  └─────────┘            │
                                    ┌────▼────────────────────┐
                                    │    EKS Cluster          │
                                    │  ┌──────────────────┐   │
                                    │  │  API Pods (3-100)│   │
                                    │  └──────────────────┘   │
                                    │  ┌──────────────────┐   │
                                    │  │Worker Pods(3-60) │   │
                                    │  └──────────────────┘   │
                                    │  ┌──────────────────┐   │
                                    │  │ ML Pods (0-10)   │   │
                                    │  └──────────────────┘   │
                                    └─────────┬───────────────┘
                                              │
                       ┌──────────────────────┼───────────────────┐
                       │                      │                   │
                  ┌────▼────┐          ┌─────▼──────┐      ┌─────▼──────┐
                  │   RDS   │          │ElastiCache │      │     S3     │
                  │PostgreSQL│         │   Redis    │      │User Content│
                  │Multi-AZ │          │  Cluster   │      │  Backups   │
                  └─────────┘          └────────────┘      └────────────┘
```

## 2. Network Architecture

```
VPC: 10.0.0.0/16 (us-east-1)
├── Public Subnets (Internet-facing)
│   ├── 10.0.101.0/24 (us-east-1a) - ALB, NAT Gateway
│   ├── 10.0.102.0/24 (us-east-1b) - ALB, NAT Gateway
│   └── 10.0.103.0/24 (us-east-1c) - ALB, NAT Gateway
│
├── Private Subnets (Application tier)
│   ├── 10.0.1.0/24 (us-east-1a) - EKS nodes
│   ├── 10.0.2.0/24 (us-east-1b) - EKS nodes
│   └── 10.0.3.0/24 (us-east-1c) - EKS nodes
│
└── Database Subnets (Data tier)
    ├── 10.0.201.0/24 (us-east-1a) - RDS, ElastiCache
    ├── 10.0.202.0/24 (us-east-1b) - RDS, ElastiCache
    └── 10.0.203.0/24 (us-east-1c) - RDS, ElastiCache

Internet Gateway: igw-xxxxx
NAT Gateways: 3 (one per AZ for high availability)
VPC Endpoints: S3, ECR, Secrets Manager, CloudWatch
```

## 3. Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                              │
└────────────────────┬────────────────────────────────────┘
                     │
            ┌────────▼────────┐
            │   AWS Shield    │  DDoS Protection
            │   (Standard)    │
            └────────┬────────┘
                     │
            ┌────────▼────────┐
            │    AWS WAF      │  Web Application Firewall
            │  - Rate Limit   │  - SQL Injection
            │  - Geo-Block    │  - XSS Protection
            └────────┬────────┘
                     │
            ┌────────▼────────┐
            │   CloudFront    │  CDN + Edge Security
            └────────┬────────┘
                     │
            ┌────────▼────────┐
            │       ALB       │  Application Load Balancer
            │   Security SG   │  - HTTPS only (443)
            └────────┬────────┘
                     │
            ┌────────▼─────────────────────┐
            │      EKS Cluster              │
            │  ┌─────────────────────────┐  │
            │  │  Network Policies       │  │
            │  │  (Calico)               │  │
            │  │  - Pod isolation        │  │
            │  │  - Namespace isolation  │  │
            │  └─────────────────────────┘  │
            │  ┌─────────────────────────┐  │
            │  │  Pod Security           │  │
            │  │  - Non-root containers  │  │
            │  │  - Read-only FS         │  │
            │  │  - No privilege esc.    │  │
            │  └─────────────────────────┘  │
            └───────────┬──────────────────┘
                        │
            ┌───────────▼──────────────┐
            │  Database Security       │
            │  - Private subnets       │
            │  - Encryption at rest    │
            │  - Encryption in transit │
            │  - Automated backups     │
            └──────────────────────────┘

All data encrypted with AWS KMS
All access logged to CloudTrail
All secrets in AWS Secrets Manager
```

## 4. CI/CD Pipeline Flow

```
Developer      ┌──────────────┐
Push Code ────▶│   GitHub     │
               └──────┬───────┘
                      │
               ┌──────▼────────────────────────────┐
               │    GitHub Actions CI/CD           │
               ├───────────────────────────────────┤
               │ 1. Code Quality                   │
               │    ├─ Linting                     │
               │    ├─ Unit Tests (80% coverage)   │
               │    ├─ Security Scan (Snyk)        │
               │    └─ SonarQube                   │
               │                                    │
               │ 2. Build                           │
               │    ├─ Docker build (multi-stage)  │
               │    ├─ Image scan (Trivy)          │
               │    ├─ Image signing (Cosign)      │
               │    └─ Push to ECR                 │
               │                                    │
               │ 3. Integration Tests               │
               │    ├─ API tests                   │
               │    ├─ E2E tests                   │
               │    └─ Contract tests              │
               └──────┬────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────▼────┐  ┌─────▼──────┐  ┌──▼─────────┐
   │   Dev   │  │  Staging   │  │Production  │
   │  Auto   │  │   Auto     │  │  Manual    │
   │ Deploy  │  │  Deploy    │  │ Approval   │
   └─────────┘  └─────┬──────┘  └──┬─────────┘
                      │             │
               ┌──────▼─────────────▼───────┐
               │  Canary Deployment         │
               │  5% → 25% → 50% → 100%    │
               │                            │
               │  Auto-rollback on errors   │
               └────────────────────────────┘
```

## 5. Disaster Recovery Architecture

```
Primary Region (us-east-1)              DR Region (us-west-2)
┌─────────────────────────┐            ┌─────────────────────┐
│   EKS Cluster           │            │  EKS Cluster        │
│   (Active)              │            │  (Standby)          │
│   30-100 nodes          │            │  3-6 nodes          │
└───────┬─────────────────┘            └─────────────────────┘
        │                                        ▲
        │                                        │
┌───────▼─────────────────┐            ┌────────┴────────────┐
│   RDS Primary           │            │  RDS Read Replica   │
│   Multi-AZ              │───────────▶│  (Cross-region)     │
│   db.r6g.2xlarge        │  Async     │  Promoted on DR     │
│                         │  Repl      │  RTO: 1 hour        │
└───────┬─────────────────┘  <1s lag   └─────────────────────┘
        │                                        ▲
        │                                        │
┌───────▼─────────────────┐            ┌────────┴────────────┐
│   S3 Buckets            │            │  S3 Buckets         │
│   (Primary)             │───────────▶│  (Replica)          │
│   User data, backups    │  CRR       │  Cross-region       │
└─────────────────────────┘            └─────────────────────┘

Failover Process:
1. Route53 health check detects failure (90 seconds)
2. DNS updated to point to DR region (60 seconds)
3. RDS read replica promoted to primary (5-15 minutes)
4. EKS cluster scaled up to production size (10-20 minutes)
5. Total RTO: ~30-60 minutes
6. RPO: <5 minutes (replication lag)
```

## 6. Monitoring & Observability Stack

```
┌──────────────────────────────────────────────────────────┐
│              Application & Infrastructure                 │
│  ┌────────┐  ┌────────┐  ┌─────┐  ┌──────┐  ┌────────┐ │
│  │  API   │  │Worker  │  │ RDS │  │Redis │  │  EKS   │ │
│  └───┬────┘  └───┬────┘  └──┬──┘  └──┬───┘  └───┬────┘ │
└──────┼───────────┼──────────┼────────┼──────────┼──────┘
       │           │          │        │          │
       │ Metrics   │ Logs     │ Traces │ Events   │
       └───────────┼──────────┼────────┼──────────┘
                   │          │        │
        ┌──────────▼──────────▼────────▼──────────┐
        │        Collection Layer                  │
        │  ┌──────────┐  ┌──────────┐  ┌────────┐│
        │  │Prometheus│  │FluentBit │  │ Jaeger ││
        │  └────┬─────┘  └────┬─────┘  └───┬────┘│
        └───────┼─────────────┼────────────┼──────┘
                │             │            │
        ┌───────▼─────────────▼────────────▼──────┐
        │         Storage Layer                    │
        │  ┌──────────┐  ┌───────────┐  ┌───────┐│
        │  │ Thanos   │  │OpenSearch │  │ S3    ││
        │  │(30 days) │  │(30 days)  │  │(7yrs) ││
        │  └────┬─────┘  └────┬──────┘  └───────┘│
        └───────┼─────────────┼───────────────────┘
                │             │
        ┌───────▼─────────────▼───────────────────┐
        │      Visualization Layer                 │
        │  ┌──────────┐  ┌──────────┐  ┌────────┐│
        │  │ Grafana  │  │ Datadog  │  │Kibana  ││
        │  └────┬─────┘  └────┬─────┘  └───┬────┘│
        └───────┼─────────────┼────────────┼──────┘
                │             │            │
        ┌───────▼─────────────▼────────────▼──────┐
        │        Alerting Layer                    │
        │  ┌─────────────┐    ┌──────────────────┐│
        │  │AlertManager │───▶│   PagerDuty      ││
        │  └─────────────┘    │   Slack          ││
        │                     │   Email          ││
        └─────────────────────┴──────────────────┘
```

## 7. Cost Optimization Strategy

```
┌──────────────────────────────────────────────────────────┐
│              Cost Optimization Approach                   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  COMPUTE SAVINGS (40-70%)                                │
│  ├─ Reserved Instances (1-year): $12k/month saved       │
│  ├─ Graviton2 instances: $5k/month saved                │
│  ├─ Spot instances for batch: $3k/month saved           │
│  └─ Auto-scaling to zero: $2k/month saved               │
│                                                           │
│  STORAGE SAVINGS (50-70%)                                │
│  ├─ S3 Intelligent-Tiering: $2k/month saved             │
│  ├─ EBS gp3 vs gp2: $1k/month saved                     │
│  ├─ Lifecycle policies: $1k/month saved                 │
│  └─ Compression: $500/month saved                       │
│                                                           │
│  DEV/STAGING SAVINGS (70%)                               │
│  ├─ Auto-shutdown (nights/weekends): $7k/month saved    │
│  ├─ Smaller instance types: $2k/month saved             │
│  └─ Shared resources: $1k/month saved                   │
│                                                           │
│  Total Monthly Savings: $37,000 (57% reduction)          │
│  Original Cost: $65,000/month                            │
│  Optimized Cost: $28,000/month                           │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

