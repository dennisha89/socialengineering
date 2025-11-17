# Cost Optimization Guide

## Executive Summary

This guide provides detailed strategies to optimize AWS infrastructure costs for the Follower Intelligence Platform, achieving up to **57% cost reduction** while maintaining performance and reliability.

## Current Cost Baseline (Before Optimization)

| Category | Monthly Cost | Percentage |
|----------|--------------|------------|
| Compute (EKS) | $25,000 | 38% |
| Database (RDS) | $12,000 | 18% |
| Cache (ElastiCache) | $4,000 | 6% |
| Storage (S3, EBS) | $5,000 | 8% |
| Network (CloudFront, Data Transfer) | $6,000 | 9% |
| Monitoring (Datadog, CloudWatch) | $3,000 | 5% |
| Other Services | $3,000 | 5% |
| Dev/Staging | $10,000 | 15% |
| **TOTAL** | **$65,000** | **100%** |

## Optimization Strategies

### 1. Compute Optimization ($20,000/month savings)

#### Reserved Instances (RI)
```
Strategy: Purchase 1-year or 3-year RIs for predictable workloads

Savings:
- API tier (10 x t3.xlarge): $8,000 → $4,800 (40% off)
- Worker tier (15 x c5.2xlarge): $12,000 → $7,200 (40% off)

Action Items:
1. Analyze instance usage patterns (min 75% utilization)
2. Purchase convertible RIs for flexibility
3. Review and adjust every 6 months

Annual Savings: ~$100,000
```

#### Graviton2 Migration
```
Strategy: Migrate to ARM-based Graviton2 instances

Savings:
- db.r5.2xlarge → db.r6g.2xlarge: $4,000 → $2,800 (30% off)
- cache.r5.xlarge → cache.r6g.xlarge: $4,000 → $2,800 (30% off)
- t3.xlarge → t4g.xlarge: 20% cheaper + 40% better performance

Implementation:
1. Test application compatibility (most apps work without changes)
2. Update Terraform to use Graviton2 instance types
3. Gradual migration starting with dev/staging

Annual Savings: ~$60,000
```

#### Spot Instances for Batch Processing
```
Strategy: Use Spot instances for fault-tolerant workloads

Savings:
- c5.2xlarge on-demand: $0.34/hour
- c5.2xlarge spot: $0.10/hour (70% savings)
- 20 instances × 730 hours × $0.24 savings = $3,500/month

Workloads suitable for Spot:
- Data processing pipelines
- Batch analytics jobs
- Machine learning training
- Non-critical background tasks

Implementation:
kubectl apply -f spot-nodegroup.yaml
# Configure pod tolerations for spot instances

Annual Savings: ~$42,000
```

#### Auto-Scaling Optimization
```
Strategy: Scale down during low-traffic periods

Current: 30 nodes 24/7 = 21,900 node-hours/month
Optimized: 
  - Peak (8am-8pm weekdays): 30 nodes
  - Off-peak (nights): 15 nodes
  - Weekends: 10 nodes
  
New total: ~14,000 node-hours/month (36% reduction)

Configure:
# HPA with aggressive scale-down
behavior:
  scaleDown:
    stabilizationWindowSeconds: 60
    policies:
    - type: Percent
      value: 50
      periodSeconds: 60

Annual Savings: ~$25,000
```

### 2. Storage Optimization ($4,500/month savings)

#### S3 Intelligent-Tiering
```
Strategy: Automatically move data to cheaper storage classes

Current Cost:
- 10TB × $23/TB (Standard) = $230/month
- 50TB × $23/TB (Standard) = $1,150/month

With Intelligent-Tiering:
- Hot tier (0-30 days): $23/TB
- Cool tier (30-90 days): $12.50/TB
- Archive tier (90+ days): $1/TB

Estimated Savings: 68% on infrequently accessed data
Annual Savings: ~$35,000
```

#### EBS Volume Optimization
```
Strategy: Migrate from gp2 to gp3 volumes

Savings:
- gp2: $0.10/GB-month
- gp3: $0.08/GB-month (20% cheaper + better performance)
- 5TB × $0.02 × 1024 GB/TB = $102/month per TB
- Total: $510/month for 5TB

Additional: Delete unused snapshots and volumes
aws ec2 describe-snapshots --owner-self \
  --query 'Snapshots[?StartTime<`2024-01-01`]' \
  --output json

Annual Savings: ~$12,000
```

#### Data Lifecycle Policies
```
Strategy: Automatically transition data to cheaper storage

S3 Lifecycle Rules:
- 0-30 days: S3 Standard
- 31-90 days: S3 Infrequent Access (50% cheaper)
- 91-365 days: S3 Glacier Instant Retrieval (68% cheaper)
- 366-2555 days: S3 Glacier Deep Archive (95% cheaper)

Annual Savings: ~$20,000
```

### 3. Dev/Staging Cost Reduction ($7,000/month savings)

#### Auto-Shutdown Strategy
```bash
#!/bin/bash
# Auto-shutdown script for dev/staging environments

# Weekday schedule:
# Start: 8 AM (before team arrives)
# Stop: 6 PM (after team leaves)

# Weekend schedule:
# Completely shut down

# Savings calculation:
# Current: 168 hours/week
# Optimized: 50 hours/week (Mon-Fri 8am-6pm)
# Reduction: 70%

# Implementation:
crontab -e
# Start at 8 AM weekdays
0 8 * * 1-5 /scripts/start-env.sh dev
# Stop at 6 PM weekdays
0 18 * * 1-5 /scripts/stop-env.sh dev

Annual Savings: ~$84,000
```

#### Smaller Instance Types
```
Strategy: Right-size dev/staging to match actual usage

Production: db.r6g.2xlarge (8 vCPU, 64GB RAM)
Staging: db.t4g.xlarge (4 vCPU, 16GB RAM) - 75% cheaper
Dev: db.t4g.medium (2 vCPU, 8GB RAM) - 90% cheaper

Annual Savings: ~$36,000
```

### 4. Network Optimization ($2,000/month savings)

#### VPC Endpoints
```
Strategy: Use VPC endpoints to avoid NAT Gateway costs

NAT Gateway cost: $0.045/hour + $0.045/GB
VPC Endpoint cost: $0.01/hour + $0.01/GB (78% cheaper)

For S3, DynamoDB, ECR: Use VPC endpoints
Annual Savings: ~$15,000
```

#### CloudFront Optimization
```
Strategy: Optimize cache hit ratio to reduce origin requests

Current cache hit ratio: 60%
Target: 85%

Actions:
1. Increase cache TTL for static assets
2. Enable gzip/brotli compression
3. Use query string whitelisting
4. Implement versioned URLs for cache busting

Origin requests reduction: 40%
Annual Savings: ~$9,000
```

### 5. Database Optimization ($3,000/month savings)

#### Aurora Serverless v2 (for staging/dev)
```
Strategy: Pay per second instead of paying for idle capacity

Current staging RDS: $2,000/month (running 24/7)
Aurora Serverless v2: $500/month (scales to zero)

Annual Savings: ~$18,000
```

#### Query Optimization
```
Strategy: Reduce IOPS costs through query optimization

Actions:
1. Add missing indexes
2. Optimize slow queries
3. Implement query result caching
4. Use read replicas for analytics

IOPS reduction: 30%
Annual Savings: ~$12,000
```

### 6. Monitoring & Tools Optimization ($1,000/month savings)

#### CloudWatch Logs Optimization
```
Strategy: Reduce log retention and sampling

Actions:
1. Reduce retention: 30 days → 7 days
2. Sample debug logs: 100% → 10%
3. Use CloudWatch Logs Insights instead of shipping all logs

Annual Savings: ~$8,000
```

#### Datadog Optimization
```
Strategy: Optimize host and metric usage

Current: 50 hosts × $31/host = $1,550/month
Optimized: 
- Use Datadog Agent filters
- Exclude non-critical metrics
- Use CloudWatch for some metrics

Reduced to: 35 hosts × $31 = $1,085/month
Annual Savings: ~$5,500
```

## Cost Monitoring & Alerts

### AWS Budgets
```bash
aws budgets create-budget \
  --account-id ACCOUNT_ID \
  --budget file://budget.json

# budget.json
{
  "BudgetName": "Monthly-Production-Budget",
  "BudgetLimit": {
    "Amount": "40000",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

### Cost Anomaly Detection
```
Enable AWS Cost Anomaly Detection:
1. Go to AWS Cost Management
2. Enable Cost Anomaly Detection
3. Set alert threshold: $500 (0.5% of budget)
4. Configure SNS topic for alerts
5. Review daily cost reports
```

### Infracost in CI/CD
```yaml
# Add to GitHub Actions
- name: Infracost
  uses: infracost/actions/setup@v2
  with:
    api-key: ${{ secrets.INFRACOST_API_KEY }}

- name: Generate cost estimate
  run: |
    infracost breakdown --path=infrastructure/ \
      --format=diff \
      --compare-to=main
```

## Optimization Timeline

### Month 1: Quick Wins (25% savings)
- [ ] Implement auto-shutdown for dev/staging
- [ ] Delete unused resources (snapshots, volumes)
- [ ] Enable S3 Intelligent-Tiering
- [ ] Migrate to EBS gp3

### Month 2: Medium Effort (40% savings)
- [ ] Purchase Reserved Instances
- [ ] Implement Spot instances for batch jobs
- [ ] Add VPC endpoints
- [ ] Optimize CloudWatch logs

### Month 3: Long-term (57% savings)
- [ ] Migrate to Graviton2 instances
- [ ] Implement aggressive auto-scaling
- [ ] Optimize database queries
- [ ] Fine-tune monitoring tools

## Cost Allocation Tags

```
Required tags for all resources:
- Environment: production | staging | dev
- CostCenter: engineering | marketing | sales
- Project: follower-intelligence
- Owner: team-name
- AutoShutdown: true | false

Terraform example:
default_tags {
  tags = {
    Environment = var.environment
    CostCenter  = "engineering"
    Project     = "follower-intelligence"
    ManagedBy   = "terraform"
  }
}
```

## Monthly Cost Review Process

1. **Week 1**: Review previous month's costs
2. **Week 2**: Identify cost anomalies and optimization opportunities
3. **Week 3**: Implement optimizations
4. **Week 4**: Measure impact and adjust

## Expected ROI

| Optimization | Investment | Monthly Savings | ROI |
|--------------|-----------|-----------------|-----|
| Reserved Instances | $50,000 upfront | $12,000 | 5 months |
| Graviton2 Migration | $10,000 (eng time) | $5,000 | 2 months |
| Auto-Shutdown | $5,000 (automation) | $7,000 | 0.7 months |
| Spot Instances | $3,000 (setup) | $3,500 | 0.9 months |
| **Total** | **$68,000** | **$27,500** | **2.5 months** |

**Annual savings: $330,000**
**57% cost reduction: $65,000 → $28,000/month**

