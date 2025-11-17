# Follower Intelligence Platform - Infrastructure Design

## Executive Summary

This document outlines the complete DevOps, infrastructure, and deployment strategy for a scalable, cloud-native follower intelligence platform designed to handle millions of users and petabytes of social media data.

## 1. Cloud Provider Recommendation: AWS

### Rationale
- **Market Leader**: Most mature cloud provider with extensive service ecosystem
- **Cost-Effective**: Better pricing for data-intensive workloads
- **Machine Learning**: Superior ML/AI services (SageMaker, Comprehend) for social intelligence
- **Global Reach**: 32 geographic regions with low-latency access
- **Managed Services**: Excellent managed database, caching, and analytics services

### Core AWS Services
- **Compute**: EKS (Kubernetes), ECS Fargate, Lambda
- **Database**: RDS PostgreSQL (Multi-AZ), Aurora, DynamoDB
- **Caching**: ElastiCache (Redis)
- **Storage**: S3, EFS
- **Networking**: VPC, Route53, CloudFront, ALB/NLB
- **Analytics**: Kinesis, Athena, QuickSight
- **ML/AI**: SageMaker, Comprehend, Rekognition
- **Monitoring**: CloudWatch, X-Ray
- **Security**: IAM, Secrets Manager, KMS, WAF, Shield

### Alternative Considerations
- **GCP**: Better for BigQuery analytics, but higher costs
- **Azure**: Better for Microsoft ecosystem integration

---

## 2. Containerization Strategy

### Docker Architecture

```dockerfile
# Multi-stage builds for optimization
# Base image: Alpine Linux (5MB vs 120MB)
# Security: Non-root user, minimal dependencies
# Optimization: Layer caching, .dockerignore
```

### Container Registry
- **Primary**: AWS ECR (Elastic Container Registry)
  - Automatic vulnerability scanning
  - Image lifecycle policies
  - IAM integration
  - Cross-region replication

### Image Management
- **Tagging Strategy**:
  - Semantic versioning: `v1.2.3`
  - Git SHA: `abc123f`
  - Environment: `prod`, `staging`, `dev`
  - Latest: `latest` (production only)

### Security Hardening
- Distroless/minimal base images
- Multi-stage builds to exclude build tools
- Regular vulnerability scanning with Trivy
- Image signing with Cosign
- No secrets in images (use Secrets Manager)

---

## 3. Kubernetes Orchestration (EKS)

### Cluster Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS EKS Cluster                       │
├─────────────────────────────────────────────────────────────┤
│  Control Plane (AWS Managed)                                 │
│  - API Server (HA across 3 AZs)                             │
│  - etcd (Managed, encrypted)                                 │
│  - Scheduler & Controller Manager                            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼──────┐    ┌────────▼─────┐    ┌─────────▼────┐
│   AZ-1a      │    │    AZ-1b     │    │    AZ-1c     │
│              │    │              │    │              │
│ Node Group 1 │    │ Node Group 2 │    │ Node Group 3 │
│ (API/Web)    │    │ (API/Web)    │    │ (API/Web)    │
│ t3.xlarge    │    │ t3.xlarge    │    │ t3.xlarge    │
│ 2-10 nodes   │    │ 2-10 nodes   │    │ 2-10 nodes   │
│              │    │              │    │              │
│ Node Group 4 │    │ Node Group 5 │    │ Node Group 6 │
│ (Workers)    │    │ (Workers)    │    │ (Workers)    │
│ c5.2xlarge   │    │ c5.2xlarge   │    │ c5.2xlarge   │
│ 3-20 nodes   │    │ 3-20 nodes   │    │ 3-20 nodes   │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Node Groups
1. **API/Web Tier** (t3.xlarge): Frontend & API services
2. **Worker Tier** (c5.2xlarge): Data processing & analytics
3. **GPU Tier** (p3.2xlarge): ML inference (on-demand)
4. **Spot Instances**: Non-critical batch processing (70% cost savings)

### Auto-Scaling Strategy

#### Horizontal Pod Autoscaler (HPA)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
```

#### Cluster Autoscaler
- Automatically adjusts node count based on pod resource requests
- Integrates with AWS Auto Scaling Groups
- Scales down underutilized nodes after 10 minutes

#### Vertical Pod Autoscaler (VPA)
- Recommends and automatically adjusts CPU/memory requests
- Prevents resource waste and OOMKilled pods

#### KEDA (Event-Driven Autoscaling)
- Scales based on external metrics (SQS queue depth, Redis list length)
- Scales to zero for cost optimization

### Networking
- **CNI Plugin**: AWS VPC CNI (native VPC networking)
- **Service Mesh**: Istio (traffic management, security, observability)
- **Ingress Controller**: AWS ALB Ingress Controller
- **Network Policies**: Calico (pod-to-pod security)

### Storage
- **Persistent Volumes**: EBS CSI Driver (gp3, io2)
- **Shared Storage**: EFS CSI Driver (for multi-pod access)
- **Object Storage**: S3 CSI Driver

---

## 4. CI/CD Pipeline Design

### GitHub Actions Workflow

```
┌──────────────┐
│  Developer   │
│  Push/PR     │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Stage 1: CODE QUALITY                                    │
│  ├─ Linting (ESLint, Black, golangci-lint)              │
│  ├─ Unit Tests (Jest, pytest, go test)                   │
│  ├─ Code Coverage (80% minimum)                          │
│  ├─ Security Scan (Snyk, SonarQube)                      │
│  └─ Dependency Audit (npm audit, safety)                 │
│                                                           │
│  Stage 2: BUILD                                           │
│  ├─ Build Application                                     │
│  ├─ Build Docker Images (Multi-stage)                    │
│  ├─ Tag Images (SHA + semantic version)                  │
│  ├─ Scan Images (Trivy vulnerability scan)               │
│  └─ Push to ECR                                           │
│                                                           │
│  Stage 3: INTEGRATION TESTS                               │
│  ├─ Spin up test environment (Docker Compose)            │
│  ├─ Integration tests                                     │
│  ├─ API contract tests (Pact)                            │
│  └─ E2E tests (Playwright/Cypress)                       │
│                                                           │
│  Stage 4: DEPLOY TO DEV                                   │
│  ├─ Update Kubernetes manifests                          │
│  ├─ Deploy to Dev EKS cluster                            │
│  ├─ Health checks                                         │
│  └─ Smoke tests                                           │
│                                                           │
│  Stage 5: DEPLOY TO STAGING (on merge to main)           │
│  ├─ Deploy to Staging EKS cluster                        │
│  ├─ Run full test suite                                  │
│  ├─ Performance tests (k6)                               │
│  ├─ Load tests                                            │
│  └─ Security tests (OWASP ZAP)                           │
│                                                           │
│  Stage 6: DEPLOY TO PRODUCTION (manual approval)         │
│  ├─ Manual approval required                             │
│  ├─ Blue-Green deployment                                │
│  ├─ Canary release (5% → 25% → 50% → 100%)              │
│  ├─ Health checks at each stage                          │
│  ├─ Automated rollback on failure                        │
│  └─ Notify team (Slack/PagerDuty)                       │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### Deployment Strategies

#### Blue-Green Deployment
```yaml
# Route traffic instantly from blue to green
# Zero downtime
# Easy rollback (switch traffic back)
# Requires 2x resources temporarily

apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
    version: green  # Switch to 'blue' for rollback
```

#### Canary Deployment
```yaml
# Gradual rollout: 5% → 25% → 50% → 100%
# Monitor metrics at each stage
# Automatic rollback on errors
# Minimal user impact on issues

apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api-canary
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  progressDeadlineSeconds: 60
  service:
    port: 8080
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 5
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
    - name: request-duration
      thresholdRange:
        max: 500
```

### GitOps with ArgoCD
- Declarative Infrastructure
- Automatic synchronization with Git
- Rollback to any previous state
- Audit trail of all changes

---

## 5. Infrastructure as Code (IaC)

### Terraform Architecture

```
infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   └── production/
│   ├── modules/
│   │   ├── eks/
│   │   ├── rds/
│   │   ├── vpc/
│   │   ├── elasticache/
│   │   ├── s3/
│   │   └── monitoring/
│   ├── global/
│   │   ├── iam/
│   │   ├── route53/
│   │   └── cloudfront/
│   └── policies/
│       ├── sentinel/
│       └── opa/
```

### Key Features
- **State Management**: Remote state in S3 with DynamoDB locking
- **Workspaces**: Separate state per environment
- **Modules**: Reusable, versioned infrastructure components
- **Policy as Code**: Sentinel/OPA for compliance enforcement
- **Automated Testing**: Terratest for infrastructure testing
- **Cost Estimation**: Infracost for PR cost analysis

### Terraform Cloud Integration
- Automated plan/apply workflows
- Policy enforcement before apply
- Cost estimation in PRs
- Team access controls
- Audit logging

---

## 6. Environment Strategy

### Environment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     PRODUCTION                               │
│  Region: us-east-1 (Primary) + us-west-2 (DR)               │
│  EKS: 3 AZs, 30-100 nodes                                    │
│  RDS: Multi-AZ, Read Replicas (5)                           │
│  ElastiCache: Cluster mode, 6 shards                         │
│  Resources: High memory/CPU, reserved instances              │
│  Traffic: Real users                                         │
│  Monitoring: Full observability, PagerDuty 24/7             │
│  Backups: Hourly snapshots, 30-day retention                │
│  Cost: ~$50k-200k/month (scales with usage)                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      STAGING                                 │
│  Region: us-east-1                                           │
│  EKS: 2 AZs, 6-20 nodes                                      │
│  RDS: Multi-AZ, 1 Read Replica                              │
│  ElastiCache: Cluster mode, 2 shards                         │
│  Resources: Production-like but smaller                      │
│  Traffic: QA team, automated tests                           │
│  Monitoring: CloudWatch, Slack alerts                        │
│  Backups: Daily snapshots, 7-day retention                   │
│  Cost: ~$10k-30k/month                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       DEV                                     │
│  Region: us-east-1                                           │
│  EKS: 1 AZ, 3-6 nodes (Spot instances)                       │
│  RDS: Single-AZ, no replicas                                 │
│  ElastiCache: Single node                                    │
│  Resources: Minimal (t3/t4g instances)                       │
│  Traffic: Developers only                                    │
│  Monitoring: Basic CloudWatch                                │
│  Backups: Daily snapshots, 3-day retention                   │
│  Auto-shutdown: Nights/weekends to save costs                │
│  Cost: ~$2k-5k/month                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   LOCAL DEVELOPMENT                          │
│  Infrastructure: Docker Compose                              │
│  Services: All services containerized                        │
│  Database: PostgreSQL container + seed data                  │
│  Cache: Redis container                                      │
│  Tools: Localstack (AWS emulation)                          │
│  Cost: $0                                                    │
└─────────────────────────────────────────────────────────────┘
```

### Environment Promotion Flow

```
Developer → Feature Branch → Dev Environment
                               ↓
                        Integration Tests Pass
                               ↓
                     Merge to main → Staging Environment
                               ↓
                        Full Test Suite Pass
                               ↓
                       Manual Approval Required
                               ↓
                        Production Deployment
                          (Canary Release)
```

### Configuration Management
- **Environment Variables**: Stored in Kubernetes ConfigMaps
- **Secrets**: AWS Secrets Manager + External Secrets Operator
- **Feature Flags**: LaunchDarkly or custom solution
- **Environment Parity**: >95% similarity between staging and production

---

## 7. Monitoring and Alerting

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    MONITORING ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  APPLICATION METRICS (Prometheus + Grafana)                 │
│  ├─ Request rate, latency, error rate                       │
│  ├─ Business metrics (signups, analyses, revenue)           │
│  ├─ Custom application metrics                              │
│  └─ 30-day retention (local) + 2-year retention (Thanos)    │
│                                                              │
│  INFRASTRUCTURE METRICS (CloudWatch + Datadog)              │
│  ├─ CPU, memory, disk, network                              │
│  ├─ EKS cluster health                                       │
│  ├─ RDS performance metrics                                 │
│  ├─ Load balancer metrics                                    │
│  └─ Cost tracking                                            │
│                                                              │
│  DISTRIBUTED TRACING (Jaeger + AWS X-Ray)                   │
│  ├─ Request tracing across microservices                    │
│  ├─ Performance bottleneck identification                   │
│  ├─ Dependency mapping                                       │
│  └─ Error root cause analysis                               │
│                                                              │
│  REAL USER MONITORING (Datadog RUM / New Relic)            │
│  ├─ Page load times                                         │
│  ├─ User interactions                                        │
│  ├─ JavaScript errors                                        │
│  └─ Core Web Vitals                                          │
│                                                              │
│  SYNTHETIC MONITORING (Pingdom / Datadog Synthetics)        │
│  ├─ Uptime monitoring from multiple locations               │
│  ├─ API endpoint checks every 1 minute                      │
│  ├─ Multi-step user journey tests                           │
│  └─ SSL certificate expiration alerts                       │
│                                                              │
│  APM (Application Performance Monitoring)                    │
│  ├─ Datadog APM or New Relic                                │
│  ├─ Automatic instrumentation                               │
│  ├─ Service dependencies                                     │
│  └─ Database query analysis                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Metrics (Golden Signals)

#### Latency
```
P50: < 100ms
P95: < 500ms
P99: < 1000ms
P99.9: < 3000ms
```

#### Traffic
```
Requests per second
Concurrent users
Data throughput (GB/hour)
```

#### Errors
```
Error rate: < 0.1%
5xx errors: < 0.01%
4xx errors: < 1%
```

#### Saturation
```
CPU utilization: < 70%
Memory utilization: < 80%
Disk I/O: < 80%
Network bandwidth: < 70%
```

### Alerting Strategy

#### Severity Levels

**P0 - Critical (PagerDuty 24/7)**
- Service completely down
- Data loss occurring
- Security breach
- Response: Immediate, wake up on-call engineer

**P1 - High (PagerDuty business hours)**
- Degraded performance affecting >10% users
- Error rate >1%
- Database issues
- Response: Within 15 minutes

**P2 - Medium (Slack notification)**
- Performance degradation <10% users
- Non-critical service down
- Resource saturation warnings
- Response: Within 1 hour

**P3 - Low (Email/Slack)**
- Approaching thresholds
- Anomaly detection warnings
- Cost alerts
- Response: Next business day

### Alert Examples

```yaml
groups:
- name: api_alerts
  interval: 30s
  rules:
  
  # High error rate
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.01
    for: 5m
    labels:
      severity: P1
    annotations:
      summary: "High error rate on {{ $labels.service }}"
      description: "Error rate is {{ $value }}% (threshold: 1%)"
  
  # High latency
  - alert: HighLatency
    expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
    for: 10m
    labels:
      severity: P2
    annotations:
      summary: "High P95 latency on {{ $labels.service }}"
      description: "P95 latency is {{ $value }}s (threshold: 1s)"
  
  # Pod crash loop
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
    for: 5m
    labels:
      severity: P1
    annotations:
      summary: "Pod {{ $labels.pod }} is crash looping"
  
  # Database connections exhausted
  - alert: DatabaseConnectionsHigh
    expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.9
    for: 5m
    labels:
      severity: P0
    annotations:
      summary: "Database connections near limit"
      description: "{{ $value }}% of connections in use"
```

### Dashboards

**Executive Dashboard**
- System uptime
- Active users
- Revenue metrics
- Cost per user
- Error budgets

**Engineering Dashboard**
- Service health (all microservices)
- Deployment frequency
- MTTR (Mean Time To Recovery)
- Failed deployments
- Technical debt metrics

**SRE Dashboard**
- SLO compliance
- Error budgets
- Incident response times
- On-call rotation
- Toil metrics

**Business Dashboard**
- User acquisition
- Feature usage
- Conversion funnel
- Customer satisfaction
- Churn rate

---

## 8. Logging Aggregation

### Logging Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LOGS                          │
│  ├─ Structured JSON logs (ECS format)                       │
│  ├─ Correlation IDs for request tracing                     │
│  ├─ Log levels: DEBUG, INFO, WARN, ERROR, FATAL            │
│  └─ Automatic PII redaction                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FLUENTD/FLUENT BIT                        │
│  ├─ Log collection from all pods                            │
│  ├─ Log parsing and enrichment                              │
│  ├─ Kubernetes metadata injection                           │
│  └─ Multi-destination routing                               │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌──────────────┐
│ CloudWatch  │  │ OpenSearch  │  │      S3      │
│   Logs      │  │  (ELK)      │  │  (Archive)   │
│             │  │             │  │              │
│ Real-time   │  │ Search &    │  │ Long-term    │
│ monitoring  │  │ Analysis    │  │ storage      │
│ 7-day ret.  │  │ 30-day ret. │  │ 7-year ret.  │
│             │  │             │  │ (Compliance) │
└─────────────┘  └─────────────┘  └──────────────┘
```

### OpenSearch (Elasticsearch) Setup

**Index Strategy**
```
logs-api-2024.11.17
logs-worker-2024.11.17
logs-audit-2024.11.17
logs-security-2024.11.17
```

**Index Lifecycle Management (ILM)**
- Hot tier (0-7 days): SSD, real-time search
- Warm tier (7-30 days): HDD, occasional search
- Cold tier (30-90 days): S3, rare access
- Delete/Archive (>90 days): Move to Glacier

**Index Templates**
```json
{
  "index_patterns": ["logs-*"],
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "index.codec": "best_compression"
  },
  "mappings": {
    "properties": {
      "@timestamp": {"type": "date"},
      "level": {"type": "keyword"},
      "message": {"type": "text"},
      "service": {"type": "keyword"},
      "trace_id": {"type": "keyword"},
      "user_id": {"type": "keyword"},
      "request_id": {"type": "keyword"}
    }
  }
}
```

### Log Retention Policy

| Environment | CloudWatch | OpenSearch | S3 Archive |
|-------------|------------|------------|------------|
| Production  | 7 days     | 30 days    | 7 years    |
| Staging     | 7 days     | 14 days    | 1 year     |
| Dev         | 3 days     | 7 days     | 90 days    |

### Structured Logging Example

```json
{
  "@timestamp": "2024-11-17T10:30:45.123Z",
  "level": "ERROR",
  "service": "api-service",
  "version": "v1.2.3",
  "environment": "production",
  "message": "Failed to process follower analysis",
  "error": {
    "type": "DatabaseConnectionError",
    "message": "Connection timeout after 30s",
    "stack_trace": "..."
  },
  "context": {
    "user_id": "usr_abc123",
    "request_id": "req_xyz789",
    "trace_id": "trace_12345",
    "span_id": "span_67890",
    "ip_address": "192.168.1.100",
    "user_agent": "Mozilla/5.0...",
    "endpoint": "/api/v1/analyze",
    "method": "POST",
    "duration_ms": 30125,
    "status_code": 500
  },
  "kubernetes": {
    "namespace": "production",
    "pod": "api-service-7d8c9f-abcde",
    "container": "api",
    "node": "ip-10-0-1-23"
  }
}
```

### Cost Optimization
- Use Fluent Bit (20x lighter than Fluentd)
- Sample debug logs (10% in production)
- Compress logs before shipping
- Use CloudWatch Logs Insights for ad-hoc queries (cheaper than ES)
- Archive to S3 Glacier Deep Archive (7 years @ $0.99/TB/month)

---

## 9. Secret Management

### AWS Secrets Manager Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SECRET STORAGE                           │
│                   AWS Secrets Manager                        │
│  ├─ Database credentials (auto-rotation)                    │
│  ├─ API keys (Twitter, Instagram, etc.)                     │
│  ├─ Encryption keys                                          │
│  ├─ SSL/TLS certificates                                     │
│  └─ OAuth tokens                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Encrypted with KMS
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            EXTERNAL SECRETS OPERATOR (ESO)                   │
│  ├─ Syncs secrets from AWS to Kubernetes                    │
│  ├─ Automatic rotation detection                            │
│  ├─ No secrets in Git                                        │
│  └─ Namespace isolation                                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               KUBERNETES SECRETS                             │
│  ├─ Mounted as files in pods                                │
│  ├─ Injected as environment variables                       │
│  ├─ Encrypted at rest with KMS                              │
│  └─ RBAC controls access                                     │
└─────────────────────────────────────────────────────────────┘
```

### Secret Naming Convention

```
Environment / Service / Secret Type

production/api/database-password
production/api/twitter-api-key
production/worker/redis-password
staging/api/database-password
```

### Automatic Secret Rotation

**RDS Database Credentials**
- Rotate every 30 days
- Zero-downtime rotation
- Automatic application of new credentials

**API Keys**
- Manual rotation quarterly
- Blue-green approach (old + new valid simultaneously)
- Deprecation period: 7 days

### Secret Access Patterns

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-secrets
  namespace: production
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: api-secrets
    creationPolicy: Owner
  data:
  - secretKey: database-url
    remoteRef:
      key: production/api/database-url
  - secretKey: twitter-api-key
    remoteRef:
      key: production/api/twitter-api-key
```

### Security Best Practices
- **No secrets in code**: Scan commits with git-secrets
- **No secrets in Docker images**: Use multi-stage builds
- **Principle of least privilege**: IAM roles per service
- **Audit logging**: CloudTrail for all secret access
- **Encryption**: All secrets encrypted with KMS
- **Time-limited access**: Temporary credentials where possible

---

## 10. CDN Strategy for Frontend

### CloudFront Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER REQUEST                              │
│        (https://app.followerintel.com)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   ROUTE 53 (DNS)                             │
│  ├─ Geo-routing to nearest CloudFront edge                  │
│  ├─ Health checks                                            │
│  └─ Failover routing                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               CLOUDFRONT (CDN)                               │
│  ├─ 450+ edge locations worldwide                           │
│  ├─ Cache static assets (HTML, CSS, JS, images)            │
│  ├─ Cache TTL: 1 year for versioned assets                 │
│  ├─ Gzip/Brotli compression                                 │
│  ├─ HTTP/2 & HTTP/3 (QUIC)                                  │
│  ├─ AWS WAF integration                                      │
│  └─ AWS Shield (DDoS protection)                            │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │ (Cache MISS)  │ (Cache HIT)   │
         ▼               ▼               │
┌─────────────┐  ┌──────────────┐       │
│     S3      │  │     ALB      │       │
│   (Static)  │  │  (Dynamic)   │       │
│             │  │              │       │
│ React SPA   │  │ API requests │       │
│ Images      │  │ routed to    │       │
│ CSS/JS      │  │ EKS cluster  │       │
└─────────────┘  └──────────────┘       │
                                         │
                                         ▼
                              ┌──────────────────┐
                              │   Edge Cache     │
                              │   Served to      │
                              │   User (<50ms)   │
                              └──────────────────┘
```

### Caching Strategy

**Static Assets (S3 Origin)**
```
Path: /static/*
Cache-Control: public, max-age=31536000, immutable
CloudFront TTL: 1 year
Versioned URLs: /static/app.abc123.js
```

**HTML (S3 Origin)**
```
Path: /index.html, /about.html
Cache-Control: no-cache
CloudFront TTL: 0 (always revalidate)
ETag validation
```

**API Requests (ALB Origin)**
```
Path: /api/*
Cache-Control: no-store
CloudFront TTL: 0 (pass-through)
```

**Images (S3 Origin with Lambda@Edge)**
```
Path: /images/*
Cache-Control: public, max-age=2592000 (30 days)
On-the-fly resizing with Lambda@Edge
WebP conversion for supported browsers
```

### Performance Optimizations

**Compression**
- Gzip for text-based assets (HTML, CSS, JS)
- Brotli for browsers that support it (23% smaller)
- Automatic compression at CloudFront edge

**HTTP/3 (QUIC)**
- Enabled for all distributions
- Faster connection establishment
- Better performance on mobile networks

**Origin Shield**
- Additional caching layer before origin
- Reduces origin load by 80%
- Improves cache hit ratio

**Lambda@Edge Functions**
1. **Request Rewrite**: Route SPA routes to index.html
2. **Security Headers**: Add CSP, HSTS, X-Frame-Options
3. **A/B Testing**: Route users to different versions
4. **Image Optimization**: Resize and convert images
5. **Authentication**: Check auth tokens at edge

### Security

**AWS WAF Rules**
- Rate limiting (1000 requests/5min per IP)
- SQL injection protection
- XSS protection
- Geo-blocking (block suspicious countries)
- IP reputation lists

**SSL/TLS**
- TLS 1.2 minimum (disable TLS 1.0/1.1)
- Custom SSL certificate (ACM)
- HTTPS-only (redirect HTTP to HTTPS)

**Security Headers**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### Cost Optimization
- S3 Intelligent-Tiering for infrequently accessed files
- CloudFront Origin Shield reduces origin requests
- Compress assets before uploading (30-70% savings)
- Use CloudFront regional pricing classes (exclude expensive regions)
- Estimated cost: $500-2000/month for 10M requests/day

---

## 11. Database Backup and Recovery

### Backup Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                     BACKUP TYPES                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. AUTOMATED SNAPSHOTS (RDS)                               │
│     ├─ Frequency: Every 1 hour                              │
│     ├─ Retention: 30 days                                    │
│     ├─ Incremental after first full snapshot                │
│     ├─ Cost: $0.095/GB/month                                │
│     └─ RTO: 15-30 minutes                                    │
│                                                              │
│  2. MANUAL SNAPSHOTS                                         │
│     ├─ Before major deployments                             │
│     ├─ Before schema migrations                             │
│     ├─ Retention: Indefinite (until manually deleted)       │
│     └─ RTO: 15-30 minutes                                    │
│                                                              │
│  3. LOGICAL BACKUPS (pg_dump)                               │
│     ├─ Daily full database dump                             │
│     ├─ Compressed and encrypted                             │
│     ├─ Stored in S3 (multiple regions)                      │
│     ├─ Retention: 90 days                                    │
│     └─ RTO: 1-4 hours (depends on size)                     │
│                                                              │
│  4. CONTINUOUS BACKUP (Point-in-Time Recovery)              │
│     ├─ Transaction log backups every 5 minutes              │
│     ├─ Restore to any second in last 30 days               │
│     ├─ RPO: <5 minutes                                       │
│     └─ RTO: 15-30 minutes                                    │
│                                                              │
│  5. CROSS-REGION REPLICATION                                │
│     ├─ Automatic snapshot copy to us-west-2                │
│     ├─ Disaster recovery site                               │
│     ├─ RTO: 30-60 minutes                                    │
│     └─ RPO: 5-15 minutes                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Recovery Objectives

| Scenario | RPO | RTO | Strategy |
|----------|-----|-----|----------|
| Data corruption (recent) | <5 min | 15 min | Point-in-time recovery |
| Accidental deletion | <1 hour | 30 min | Automated snapshot restore |
| Regional failure | <15 min | 1 hour | Cross-region replica promotion |
| Complete disaster | <1 hour | 4 hours | Logical backup restore |

### Automated Backup Testing

```yaml
# Weekly backup restoration test
schedule: "0 2 * * 0"  # Every Sunday at 2 AM

steps:
  1. Create test RDS instance from latest snapshot
  2. Run data integrity checks
  3. Verify row counts match production
  4. Test application connectivity
  5. Cleanup test instance
  6. Report results to Slack
```

### Database High Availability

```
┌─────────────────────────────────────────────────────────────┐
│              RDS MULTI-AZ CONFIGURATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Primary AZ (us-east-1a)          Standby AZ (us-east-1b) │
│   ┌──────────────────┐             ┌──────────────────┐     │
│   │  Primary RDS     │             │  Standby RDS     │     │
│   │  PostgreSQL 15   │─────────────│  PostgreSQL 15   │     │
│   │  db.r6g.2xlarge  │ Sync Repl  │  db.r6g.2xlarge  │     │
│   │  Active          │             │  Passive         │     │
│   └────────┬─────────┘             └──────────────────┘     │
│            │                                                 │
│            │ Automatic failover in 60-120 seconds           │
│            │                                                 │
│   ┌────────▼───────────────────────────────────────┐        │
│   │           Read Replicas (5x)                   │        │
│   │  us-east-1a (2), us-east-1b (2), us-west-2 (1)│        │
│   │  Async replication, <1 second lag              │        │
│   │  Auto-scaling based on connection count         │        │
│   └─────────────────────────────────────────────────┘        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Data Lifecycle Management

**S3 Backup Lifecycle**
```
Day 0-30:    S3 Standard
Day 31-90:   S3 Infrequent Access
Day 91-365:  S3 Glacier Instant Retrieval
Day 366-2555: S3 Glacier Deep Archive (7 years for compliance)
Day 2555+:   Delete
```

**Cost Example**
- Database size: 1TB
- Daily change rate: 1%
- Automated snapshots: $95/month
- S3 logical backups: $23/month (Standard) + $2/month (Glacier)
- Total: ~$120/month

---

## 12. Load Balancing Strategy

### Multi-Layer Load Balancing

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 1: GLOBAL                           │
│                    Route 53 (DNS)                            │
│  ├─ Latency-based routing                                   │
│  ├─ Health checks (every 30s)                               │
│  ├─ Automatic failover to DR region                         │
│  └─ Weighted routing for A/B testing                        │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  us-east-1   │ │  us-west-2   │ │   eu-west-1  │
│   (Primary)  │ │     (DR)     │ │   (Future)   │
└──────┬───────┘ └──────────────┘ └──────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 2: REGIONAL                         │
│                CloudFront (CDN)                              │
│  ├─ Static content delivery                                 │
│  ├─ DDoS protection (Shield)                                │
│  ├─ WAF (Web Application Firewall)                          │
│  └─ SSL/TLS termination                                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 3: APPLICATION                      │
│         Application Load Balancer (ALB)                      │
│  ├─ HTTP/HTTPS layer 7 routing                              │
│  ├─ Path-based routing (/api/*, /admin/*)                  │
│  ├─ Host-based routing (api.domain.com, admin.domain.com)  │
│  ├─ SSL/TLS termination                                      │
│  ├─ Authentication (Cognito integration)                    │
│  ├─ Sticky sessions (for stateful apps)                     │
│  └─ Health checks (custom endpoints)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Target      │ │  Target      │ │  Target      │
│  Group 1     │ │  Group 2     │ │  Group 3     │
│  (API)       │ │  (Admin)     │ │  (Workers)   │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 4: POD                              │
│              Kubernetes Service (ClusterIP)                  │
│  ├─ Round-robin load balancing                              │
│  ├─ Session affinity (optional)                             │
│  └─ Service mesh (Istio) for advanced routing               │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Pod 1      │ │   Pod 2      │ │   Pod 3      │
│   (API)      │ │   (API)      │ │   (API)      │
└──────────────┘ └──────────────┘ └──────────────┘
```

### ALB Configuration

**Health Checks**
```yaml
HealthCheck:
  Protocol: HTTP
  Path: /health
  Port: 8080
  HealthyThreshold: 2
  UnhealthyThreshold: 3
  Interval: 30s
  Timeout: 5s
  Matcher: "200"
```

**Target Group Settings**
```yaml
TargetGroup:
  Protocol: HTTP
  Port: 8080
  TargetType: ip  # For EKS pods
  DeregistrationDelay: 30s
  LoadBalancingAlgorithm: least_outstanding_requests
  Stickiness:
    Enabled: true
    Type: app_cookie
    CookieName: SESSION
    Duration: 3600s
```

**Routing Rules**
```yaml
Rules:
  # API traffic
  - Condition: 
      PathPattern: /api/*
    Action:
      Type: forward
      TargetGroup: api-target-group
  
  # Admin traffic (requires auth)
  - Condition:
      PathPattern: /admin/*
    Action:
      Type: authenticate-cognito
      TargetGroup: admin-target-group
  
  # WebSocket traffic
  - Condition:
      PathPattern: /ws/*
    Action:
      Type: forward
      TargetGroup: websocket-target-group
      Stickiness: enabled
```

### Service Mesh (Istio)

**Advanced Traffic Management**
- **Circuit Breaking**: Prevent cascading failures
- **Retries**: Automatic retry with exponential backoff
- **Timeouts**: Per-service timeout configuration
- **Rate Limiting**: Protect services from overload
- **Load Balancing**: Consistent hashing, least request

**Example: Circuit Breaker**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-circuit-breaker
spec:
  host: api-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
```

### Load Balancing Algorithms

| Algorithm | Use Case | Example |
|-----------|----------|---------|
| Round Robin | Stateless apps, equal capacity | API servers |
| Least Connections | Long-lived connections | WebSockets |
| Least Outstanding Requests | Varying request complexity | Heavy API endpoints |
| IP Hash | Sticky sessions required | Stateful apps |
| Consistent Hashing | Caching layers | Redis proxy |

---

## 13. Cost Optimization Approaches

### Cost Optimization Strategies

```
┌─────────────────────────────────────────────────────────────┐
│                   COST OPTIMIZATION                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. COMPUTE OPTIMIZATION                                     │
│     ├─ Reserved Instances (1-year): 40% savings             │
│     ├─ Savings Plans (1-year compute): 52% savings          │
│     ├─ Spot Instances: 70-90% savings                       │
│     ├─ Graviton2 instances (ARM): 20% savings + better perf│
│     ├─ Auto-scaling: Scale to zero when not needed          │
│     └─ Right-sizing: Analyze and downsize over-provisioned  │
│                                                              │
│  2. STORAGE OPTIMIZATION                                     │
│     ├─ S3 Intelligent-Tiering: 68% savings                  │
│     ├─ EBS gp3 vs gp2: 20% cheaper, better performance     │
│     ├─ Lifecycle policies: Auto-move to Glacier             │
│     ├─ Compression: Reduce storage by 70%                   │
│     └─ Delete unused snapshots/volumes                      │
│                                                              │
│  3. DATABASE OPTIMIZATION                                    │
│     ├─ Aurora Serverless v2: Pay per second                 │
│     ├─ Read replicas only when needed                       │
│     ├─ Reserved instances: 45% savings                      │
│     ├─ Graviton-based instances: 35% better price/perf     │
│     └─ Query optimization: Reduce IOPS costs                │
│                                                              │
│  4. NETWORKING OPTIMIZATION                                  │
│     ├─ VPC endpoints: Avoid NAT gateway costs               │
│     ├─ S3 Transfer Acceleration: Only when needed           │
│     ├─ CloudFront: Reduce origin requests                   │
│     ├─ Direct Connect: For high egress (>50TB/month)       │
│     └─ IPv6: Free egress vs IPv4                            │
│                                                              │
│  5. DEVELOPMENT/STAGING COST REDUCTION                       │
│     ├─ Auto-shutdown: Nights & weekends (70% time savings) │
│     ├─ Smaller instance types: 50% cost reduction           │
│     ├─ Shared clusters: Multi-tenancy                       │
│     ├─ Spot instances: 90% cost reduction                   │
│     └─ Ephemeral environments: Delete after use             │
│                                                              │
│  6. MONITORING & TOOLS                                       │
│     ├─ AWS Cost Explorer: Daily cost analysis               │
│     ├─ AWS Budgets: Alerts at 80%, 100% of budget          │
│     ├─ Infracost: Cost estimation in PRs                    │
│     ├─ Kubecost: Kubernetes cost allocation                 │
│     └─ CloudHealth/CloudCheckr: Multi-cloud optimization    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Monthly Cost Breakdown (Example for 100K Users)

```
┌────────────────────────────────────────────────────────────┐
│                    PRODUCTION COSTS                         │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  COMPUTE (EKS)                                 $15,000      │
│  ├─ 30 nodes x t3.xlarge (Reserved)             $8,000     │
│  ├─ 20 nodes x c5.2xlarge (Reserved)            $6,000     │
│  └─ 10 nodes x p3.2xlarge (Spot)                $1,000     │
│                                                             │
│  DATABASE (RDS)                                $8,000       │
│  ├─ Primary: db.r6g.2xlarge (Reserved)          $4,000     │
│  ├─ Standby: db.r6g.2xlarge (Reserved)          $2,000     │
│  └─ Read Replicas (5x)                          $2,000     │
│                                                             │
│  CACHE (ElastiCache Redis)                    $2,500       │
│  └─ cache.r6g.xlarge x 6 nodes (Reserved)      $2,500     │
│                                                             │
│  STORAGE                                       $3,000       │
│  ├─ S3 (2TB, Intelligent-Tiering)                $400      │
│  ├─ EBS (10TB gp3)                              $800       │
│  ├─ RDS Storage (5TB)                          $1,150      │
│  └─ Backups & Snapshots                         $650       │
│                                                             │
│  NETWORKING                                    $4,000       │
│  ├─ CloudFront (10M requests/day)              $1,500      │
│  ├─ ALB                                          $500      │
│  ├─ Data Transfer Out                          $2,000      │
│  └─ Route53                                      $100      │
│                                                             │
│  MONITORING & LOGGING                          $2,000       │
│  ├─ Datadog (50 hosts)                         $1,500      │
│  ├─ CloudWatch                                   $300      │
│  └─ OpenSearch                                   $200      │
│                                                             │
│  OTHER SERVICES                                $2,500       │
│  ├─ SageMaker (ML inference)                   $1,000      │
│  ├─ Lambda                                       $200      │
│  ├─ Kinesis                                      $500      │
│  ├─ Secrets Manager                              $100      │
│  └─ Other (WAF, Shield, etc.)                   $700      │
│                                                             │
├────────────────────────────────────────────────────────────┤
│  TOTAL PRODUCTION                              $37,000      │
│                                                             │
│  STAGING                                       $8,000       │
│  DEV (with auto-shutdown)                      $2,000       │
│                                                             │
│  TOTAL MONTHLY COST                            $47,000      │
│  Cost per user (100K users)                    $0.47        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  POTENTIAL SAVINGS WITH OPTIMIZATION:                       │
│  ├─ Reserved Instances (1-year)       -$12,000 (25%)       │
│  ├─ Graviton2 Migration                -$5,000 (10%)       │
│  ├─ Spot Instances for Batch          -$3,000 (6%)        │
│  ├─ Storage Optimization               -$2,000 (4%)        │
│  ├─ Dev/Staging Auto-Shutdown          -$3,000 (6%)        │
│  └─ Network Optimization               -$2,000 (4%)        │
│                                                             │
│  OPTIMIZED MONTHLY COST                        $20,000      │
│  Savings                                       $27,000 (57%)│
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Auto-Shutdown Script for Dev/Staging

```python
# Lambda function to shut down dev/staging environments
# Runs: Mon-Fri 6 PM, starts Mon-Fri 8 AM
# Saves: 70% of compute costs (126 hours/week vs 168 hours)

import boto3
from datetime import datetime

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')
    eks = boto3.client('eks')
    
    # Define environments to auto-shutdown
    environments = ['dev', 'staging']
    
    current_hour = datetime.now().hour
    current_day = datetime.now().weekday()  # 0=Monday, 6=Sunday
    
    # Shutdown at 6 PM on weekdays
    if current_hour == 18 and current_day < 5:
        shutdown_environments(environments)
    
    # Startup at 8 AM on weekdays
    elif current_hour == 8 and current_day < 5:
        startup_environments(environments)
```

### Cost Alerts

```yaml
AWS Budget:
  Name: Monthly Production Budget
  Amount: $40,000
  Alerts:
    - Threshold: 80%
      Action: Email + Slack notification
    - Threshold: 90%
      Action: Email + Slack + PagerDuty
    - Threshold: 100%
      Action: Email + Slack + PagerDuty + CEO notification
    - Threshold: 110%
      Action: Auto-shutdown non-critical resources
```

---

## 14. Security Hardening

### Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  LAYER 1: NETWORK SECURITY                                  │
│  ├─ VPC isolation (private subnets)                         │
│  ├─ Security Groups (least privilege)                       │
│  ├─ Network ACLs (stateless firewall)                       │
│  ├─ AWS WAF (Layer 7 protection)                            │
│  ├─ AWS Shield Standard/Advanced (DDoS)                     │
│  ├─ VPC Flow Logs (network monitoring)                      │
│  └─ Private Link (no internet exposure)                     │
│                                                              │
│  LAYER 2: IDENTITY & ACCESS                                 │
│  ├─ IAM roles (no long-term credentials)                    │
│  ├─ MFA required for all users                              │
│  ├─ OIDC for GitHub Actions (no AWS keys)                   │
│  ├─ Service accounts per microservice                       │
│  ├─ RBAC in Kubernetes                                       │
│  └─ Session timeout (12 hours)                              │
│                                                              │
│  LAYER 3: DATA PROTECTION                                   │
│  ├─ Encryption at rest (KMS, AES-256)                       │
│  ├─ Encryption in transit (TLS 1.2+)                        │
│  ├─ Database encryption (RDS)                               │
│  ├─ S3 bucket encryption                                     │
│  ├─ EBS volume encryption                                    │
│  └─ Secrets Manager for credentials                         │
│                                                              │
│  LAYER 4: APPLICATION SECURITY                              │
│  ├─ OWASP Top 10 protection                                 │
│  ├─ Input validation & sanitization                         │
│  ├─ SQL injection prevention (parameterized queries)        │
│  ├─ XSS prevention (CSP headers)                            │
│  ├─ CSRF protection (tokens)                                │
│  ├─ Rate limiting (per IP, per user)                        │
│  └─ API authentication (JWT, OAuth2)                        │
│                                                              │
│  LAYER 5: CONTAINER SECURITY                                │
│  ├─ Non-root containers                                      │
│  ├─ Read-only filesystems                                    │
│  ├─ Pod Security Policies                                   │
│  ├─ Network policies (Calico)                               │
│  ├─ Image scanning (Trivy)                                  │
│  ├─ Runtime protection (Falco)                              │
│  └─ Service mesh mTLS (Istio)                               │
│                                                              │
│  LAYER 6: MONITORING & DETECTION                            │
│  ├─ GuardDuty (threat detection)                            │
│  ├─ Security Hub (compliance checking)                      │
│  ├─ CloudTrail (audit logging)                              │
│  ├─ Config (configuration monitoring)                       │
│  ├─ Macie (data loss prevention)                            │
│  ├─ Detective (security investigation)                      │
│  └─ SIEM integration (Splunk/Datadog)                       │
│                                                              │
│  LAYER 7: INCIDENT RESPONSE                                 │
│  ├─ Incident response playbooks                             │
│  ├─ Automated remediation (Lambda)                          │
│  ├─ Forensics snapshots                                      │
│  ├─ Security notification (PagerDuty)                       │
│  └─ Post-mortem process                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Security Best Practices

**1. Principle of Least Privilege**
```yaml
# Example IAM policy for EKS worker nodes
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::my-app-bucket/*"
    }
  ]
}
```

**2. Pod Security Standards**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000
    fsGroup: 10000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:v1.0.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

**3. Network Policies**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

**4. Security Scanning Pipeline**
```yaml
# GitHub Actions security scanning
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'myapp:${{ github.sha }}'
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail build on vulnerabilities

- name: Run Snyk security scan
  uses: snyk/actions/node@master
  with:
    args: --severity-threshold=high

- name: SonarQube scan
  uses: sonarsource/sonarcloud-github-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Security Checklist

- [ ] All data encrypted at rest and in transit
- [ ] MFA enabled for all user accounts
- [ ] No hard-coded secrets in code/configs
- [ ] Security groups follow least privilege
- [ ] All S3 buckets private by default
- [ ] CloudTrail enabled in all regions
- [ ] GuardDuty enabled for threat detection
- [ ] Regular security audits (quarterly)
- [ ] Penetration testing (annually)
- [ ] Vulnerability scanning in CI/CD
- [ ] Incident response plan documented
- [ ] Security training for all engineers
- [ ] Audit logs retained for 7 years
- [ ] DDoS protection enabled (Shield)
- [ ] WAF rules configured and tested

---

## 15. Compliance Considerations

### Compliance Framework

```
┌─────────────────────────────────────────────────────────────┐
│                    SOC 2 TYPE II                             │
├─────────────────────────────────────────────────────────────┤
│  Security                                                    │
│  ├─ Access controls (MFA, RBAC)                             │
│  ├─ Encryption (data at rest & in transit)                  │
│  ├─ Network security (firewalls, IDS/IPS)                   │
│  ├─ Vulnerability management                                │
│  └─ Incident response procedures                            │
│                                                              │
│  Availability                                                │
│  ├─ 99.9% uptime SLA                                        │
│  ├─ Disaster recovery plan                                  │
│  ├─ Redundancy (Multi-AZ, backups)                          │
│  ├─ Monitoring & alerting                                   │
│  └─ Capacity planning                                        │
│                                                              │
│  Processing Integrity                                        │
│  ├─ Data validation                                          │
│  ├─ Error handling                                           │
│  ├─ Transaction logs                                         │
│  └─ Quality assurance processes                             │
│                                                              │
│  Confidentiality                                             │
│  ├─ Data classification                                      │
│  ├─ Access restrictions                                      │
│  ├─ Non-disclosure agreements                               │
│  └─ Data retention policies                                 │
│                                                              │
│  Privacy                                                     │
│  ├─ Privacy policy                                           │
│  ├─ Consent management                                       │
│  ├─ Data subject rights (GDPR)                              │
│  └─ Third-party vendor management                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                         GDPR                                 │
├─────────────────────────────────────────────────────────────┤
│  Data Subject Rights                                         │
│  ├─ Right to access (data export)                           │
│  ├─ Right to rectification (data update)                    │
│  ├─ Right to erasure (data deletion)                        │
│  ├─ Right to data portability                               │
│  ├─ Right to object (opt-out)                               │
│  └─ Automated decision-making opt-out                       │
│                                                              │
│  Data Processing                                             │
│  ├─ Lawful basis for processing                             │
│  ├─ Data minimization                                        │
│  ├─ Purpose limitation                                       │
│  ├─ Storage limitation (retention)                          │
│  └─ Data processing agreements (DPAs)                        │
│                                                              │
│  Security & Breach Notification                             │
│  ├─ Security measures (encryption, pseudonymization)        │
│  ├─ Data protection impact assessment (DPIA)                │
│  ├─ Breach notification (72 hours)                          │
│  └─ Data Protection Officer (DPO)                           │
│                                                              │
│  International Transfers                                     │
│  ├─ Standard Contractual Clauses (SCCs)                     │
│  ├─ EU-US Data Privacy Framework                            │
│  ├─ Binding Corporate Rules (BCRs)                          │
│  └─ Data localization (EU-only storage)                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        ISO 27001                             │
├─────────────────────────────────────────────────────────────┤
│  ├─ Information Security Management System (ISMS)           │
│  ├─ Risk assessment & treatment                             │
│  ├─ Security policies & procedures                          │
│  ├─ Access control                                           │
│  ├─ Cryptography controls                                    │
│  ├─ Physical security                                        │
│  ├─ Operations security                                      │
│  ├─ Communications security                                  │
│  ├─ System acquisition & development                        │
│  ├─ Supplier relationships                                   │
│  ├─ Incident management                                      │
│  └─ Business continuity                                      │
└─────────────────────────────────────────────────────────────┘
```

### GDPR Implementation

**Data Subject Access Request (DSAR) Automation**
```python
# API endpoint to handle GDPR data export requests
@app.route('/api/gdpr/export', methods=['POST'])
@require_authentication
def gdpr_export():
    user_id = get_current_user_id()
    
    # Collect all user data from multiple sources
    data = {
        'profile': get_user_profile(user_id),
        'followers': get_follower_data(user_id),
        'analyses': get_analysis_history(user_id),
        'settings': get_user_settings(user_id),
        'billing': get_billing_info(user_id),
        'activity_logs': get_activity_logs(user_id),
    }
    
    # Generate PDF report
    pdf = generate_pdf_report(data)
    
    # Upload to S3 with expiring link
    url = upload_to_s3_with_expiration(pdf, expires_in=7*24*60*60)
    
    # Log GDPR request
    log_gdpr_request(user_id, 'export', timestamp=now())
    
    # Send email with download link
    send_email(user.email, 'Your data export is ready', url)
    
    return {'status': 'processing', 'estimated_time': '15 minutes'}


# API endpoint to handle GDPR deletion requests
@app.route('/api/gdpr/delete', methods=['POST'])
@require_authentication
def gdpr_delete():
    user_id = get_current_user_id()
    
    # Verify user identity (require password + MFA)
    if not verify_identity(user_id, request.json['password'], request.json['mfa_code']):
        return {'error': 'Identity verification failed'}, 401
    
    # Schedule deletion (30-day grace period)
    schedule_deletion(user_id, execute_at=now() + timedelta(days=30))
    
    # Log GDPR request
    log_gdpr_request(user_id, 'deletion', timestamp=now())
    
    # Send confirmation email
    send_email(user.email, 'Account deletion scheduled', 
               'Your account will be deleted in 30 days. You can cancel this request anytime.')
    
    return {'status': 'scheduled', 'deletion_date': now() + timedelta(days=30)}
```

**Data Retention Policy**
```yaml
Data Retention:
  User Profiles:
    Active Users: Indefinite
    Deleted Users: 30 days grace period, then purge
    
  User Content:
    Active: Indefinite
    After Deletion: 30 days, then purge
    
  Analytics Data:
    Aggregated: 7 years (for compliance)
    Individual: 2 years, then anonymize
    
  Logs:
    Application Logs: 90 days
    Security Logs: 7 years (compliance)
    Audit Logs: 7 years (compliance)
    
  Backups:
    Database Snapshots: 30 days
    Archive Backups: 7 years (encrypted)
    
  Billing Records:
    Active Subscriptions: Indefinite
    Cancelled Subscriptions: 7 years (tax/legal)
```

### Compliance Monitoring

```yaml
# Automated compliance checks
AWS Config Rules:
  - s3-bucket-public-read-prohibited
  - s3-bucket-public-write-prohibited
  - encrypted-volumes
  - rds-encryption-enabled
  - iam-password-policy
  - mfa-enabled-for-iam-console-access
  - root-account-mfa-enabled
  - cloudtrail-enabled
  - guardduty-enabled-centralized

Custom Compliance Checks:
  - GDPR: Data retention policies enforced
  - GDPR: Data subject rights API functional
  - SOC 2: MFA enabled for 100% of users
  - SOC 2: Encryption enabled for all data stores
  - SOC 2: Audit logs retained for 7 years
  - SOC 2: Incident response tested quarterly
  - ISO 27001: Access reviews completed monthly
  - ISO 27001: Vulnerability scans run weekly

Compliance Dashboard:
  - Overall compliance score: 98%
  - Open compliance issues: 3
  - Remediation time (average): 2.5 days
  - Last audit: 2024-Q3
  - Next audit: 2025-Q1
```

### Audit Logging

```yaml
# CloudTrail configuration for audit logging
CloudTrail:
  Name: production-audit-trail
  S3Bucket: audit-logs-bucket-encrypted
  LogFileValidation: Enabled
  MultiRegionTrail: Enabled
  IncludeGlobalServiceEvents: Enabled
  EventSelectors:
    - ReadWriteType: All
      IncludeManagementEvents: true
      DataResources:
        - Type: AWS::S3::Object
          Values: ["arn:aws:s3:::*/"]
        - Type: AWS::Lambda::Function
          Values: ["arn:aws:lambda:*:*:function/*"]
  Insights:
    - ErrorRateInsight: Enabled
    - ApiCallRateInsight: Enabled

# Application audit logging
Application Audit Events:
  - User login/logout
  - User registration
  - Password changes
  - MFA enrollment
  - Permission changes
  - Data exports (GDPR)
  - Data deletions (GDPR)
  - Admin actions
  - API key generation
  - Billing changes
  - Configuration changes

Log Format:
  {
    "timestamp": "2024-11-17T10:30:45.123Z",
    "event_type": "user.login",
    "actor": {
      "user_id": "usr_abc123",
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0..."
    },
    "resource": {
      "type": "user",
      "id": "usr_abc123"
    },
    "action": "login",
    "result": "success",
    "metadata": {
      "mfa_used": true,
      "login_method": "password"
    }
  }
```

---

## 16. Disaster Recovery (DR)

### DR Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    DISASTER RECOVERY                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  RTO (Recovery Time Objective): 1 hour                      │
│  RPO (Recovery Point Objective): 5 minutes                  │
│                                                              │
│  Primary Region: us-east-1                                   │
│  DR Region: us-west-2                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    PRIMARY REGION (us-east-1)                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  EKS Cluster (Production)                              │ │
│  │  30-100 nodes, Multi-AZ                                │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  RDS Primary (Multi-AZ)                                │ │
│  │  Continuous replication to DR region                   │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  S3 Buckets                                            │ │
│  │  Cross-region replication to us-west-2                │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│                    Continuous Data Sync                      │
│                            │                                 │
│                            ▼                                 │
│                                                              │
│                    DR REGION (us-west-2)                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  EKS Cluster (Standby)                                 │ │
│  │  Minimal: 3-6 nodes                                    │ │
│  │  Scales to production size on failover                 │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  RDS Read Replica                                      │ │
│  │  Promotes to primary on failover                       │ │
│  │  Lag: <1 second                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  S3 Buckets (Replica)                                  │ │
│  │  Receives continuous replication                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### DR Procedures

**Automated Failover Process**
```bash
#!/bin/bash
# DR failover script (automated by Route53 health checks)

# 1. Detect primary region failure
# Route53 health check fails after 3 consecutive failures (90 seconds)

# 2. Update DNS to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.followerintel.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z0987654321XYZ",
          "DNSName": "dr-alb-us-west-2.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'

# 3. Promote RDS read replica to primary
aws rds promote-read-replica \
  --db-instance-identifier followerdb-dr \
  --region us-west-2

# 4. Scale up DR EKS cluster
aws eks update-nodegroup-config \
  --cluster-name production-dr \
  --nodegroup-name api-nodegroup \
  --scaling-config minSize=10,maxSize=100,desiredSize=30 \
  --region us-west-2

# 5. Deploy latest application version
kubectl apply -f k8s/production/ --namespace=production

# 6. Run smoke tests
./scripts/smoke-tests.sh --env=dr

# 7. Notify team
curl -X POST https://hooks.slack.com/services/XXX \
  -d '{"text": "🚨 DR FAILOVER COMPLETE. System running in us-west-2."}'

# Total time: ~15-30 minutes
# RTO met: 1 hour ✓
```

**Failback Process (Return to Primary Region)**
```bash
#!/bin/bash
# Execute after primary region is restored

# 1. Verify primary region is healthy
./scripts/health-check.sh --region=us-east-1

# 2. Setup replication from DR to primary
aws rds create-db-instance-read-replica \
  --db-instance-identifier followerdb-primary-replica \
  --source-db-instance-identifier followerdb-dr \
  --region us-east-1

# Wait for replication to catch up (monitor lag)
while [ $(get_replication_lag) -gt 1 ]; do
  echo "Waiting for replication lag to decrease..."
  sleep 60
done

# 3. Scheduled maintenance window: Promote primary
aws rds promote-read-replica \
  --db-instance-identifier followerdb-primary-replica \
  --region us-east-1

# 4. Update DNS to point back to primary
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.followerintel.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z1234567890ABC",
          "DNSName": "alb-us-east-1.elb.amazonaws.com"
        }
      }
    }]
  }'

# 5. Scale down DR cluster to standby mode
aws eks update-nodegroup-config \
  --cluster-name production-dr \
  --nodegroup-name api-nodegroup \
  --scaling-config minSize=3,maxSize=10,desiredSize=3 \
  --region us-west-2

# 6. Notify team
curl -X POST https://hooks.slack.com/services/XXX \
  -d '{"text": "✅ FAILBACK COMPLETE. System back to primary region (us-east-1)."}'
```

### DR Testing

**Quarterly DR Drills**
```yaml
DR Test Plan:
  Frequency: Quarterly (4 times per year)
  Duration: 4 hours
  
  Test Scenarios:
    1. Complete region failure
    2. Database failure
    3. Network partition
    4. Ransomware attack simulation
    5. Data center fire
  
  Success Criteria:
    - RTO < 1 hour ✓
    - RPO < 5 minutes ✓
    - All critical services functional
    - Data integrity verified
    - No data loss
  
  Participants:
    - SRE team
    - Engineering team
    - Product team
    - Executive team (observer)
  
  Post-Test:
    - Detailed report within 48 hours
    - Action items for improvements
    - Update runbooks
    - Team retrospective
```

---

## Summary

This infrastructure design provides:

✅ **Scalability**: Auto-scales from 10 to 10,000+ users seamlessly
✅ **High Availability**: 99.9% uptime with multi-AZ and multi-region
✅ **Security**: Defense-in-depth with multiple security layers
✅ **Compliance**: SOC 2, GDPR, ISO 27001 ready
✅ **Cost-Effective**: Optimized for 57% cost savings
✅ **Fast**: <100ms API latency, <50ms CDN delivery
✅ **Observable**: Full monitoring, logging, and tracing
✅ **Automated**: CI/CD, auto-scaling, auto-healing
✅ **Resilient**: 1-hour RTO, 5-minute RPO
✅ **Developer-Friendly**: Local development environment, GitOps workflow

**Next Steps**:
1. Review and approve infrastructure design
2. Provision AWS accounts and set up billing
3. Implement Terraform modules
4. Set up CI/CD pipeline
5. Deploy to dev environment
6. Security audit
7. Load testing
8. Deploy to production

**Estimated Timeline**: 6-8 weeks for full implementation
**Team Required**: 2 DevOps engineers, 1 Security engineer, 1 SRE

