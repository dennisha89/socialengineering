# Infrastructure Implementation Guide

## Phase 1: Foundation (Week 1-2)

### AWS Account Setup
```bash
# 1. Create AWS accounts (separate for prod, staging, dev)
# 2. Enable AWS Organizations
# 3. Set up consolidated billing
# 4. Configure AWS CloudTrail in all regions
# 5. Enable AWS Config
# 6. Set up AWS GuardDuty
# 7. Configure AWS Security Hub
```

### IAM Setup
```bash
# 1. Create admin group with MFA enforcement
# 2. Create developer group with limited permissions
# 3. Set up OIDC provider for GitHub Actions
# 4. Create service roles for EKS, RDS, Lambda
# 5. Implement password policy (12+ chars, rotation)
```

### Network Foundation
```bash
# 1. Deploy VPC with Terraform
cd infrastructure/terraform/environments/production
terraform init
terraform plan
terraform apply

# 2. Verify VPC components
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-route-tables
```

## Phase 2: Core Infrastructure (Week 3-4)

### EKS Cluster Deployment
```bash
# 1. Deploy EKS cluster
terraform apply -target=module.eks

# 2. Configure kubectl
aws eks update-kubeconfig --name followerintel-production

# 3. Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces

# 4. Install essential add-ons
kubectl apply -f infrastructure/kubernetes/base/
```

### Database Deployment
```bash
# 1. Deploy RDS PostgreSQL
terraform apply -target=module.rds

# 2. Create database schema
psql -h <rds-endpoint> -U dbadmin -d followerintel < schema.sql

# 3. Configure backups
aws rds create-db-snapshot --db-instance-identifier followerintel-prod

# 4. Set up read replicas
terraform apply -target=module.rds.read_replicas
```

### Cache Deployment
```bash
# 1. Deploy ElastiCache Redis
terraform apply -target=module.elasticache

# 2. Test connectivity
redis-cli -h <redis-endpoint> ping
```

## Phase 3: Application Deployment (Week 5-6)

### Container Registry Setup
```bash
# 1. Create ECR repositories
aws ecr create-repository --repository-name followerintel/api
aws ecr create-repository --repository-name followerintel/worker

# 2. Build and push initial images
docker build -t followerintel/api:v1.0.0 .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/followerintel/api:v1.0.0
```

### Application Deployment
```bash
# 1. Create Kubernetes secrets
kubectl create secret generic api-secrets \
  --from-literal=database-url=<url> \
  --from-literal=redis-url=<url> \
  -n production

# 2. Deploy application
kubectl apply -f infrastructure/kubernetes/production/

# 3. Verify deployment
kubectl get pods -n production
kubectl logs -f deployment/api-service -n production
```

### Load Balancer Setup
```bash
# 1. Deploy ALB
terraform apply -target=module.alb

# 2. Configure DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://dns-record.json

# 3. Test endpoint
curl -f https://api.followerintel.com/health
```

## Phase 4: Monitoring & Logging (Week 7-8)

### Prometheus Setup
```bash
# 1. Install Prometheus Operator
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml

# 2. Deploy Prometheus
kubectl apply -f infrastructure/monitoring/prometheus-config.yaml

# 3. Verify metrics collection
kubectl port-forward svc/prometheus 9090:9090
# Visit http://localhost:9090
```

### Grafana Setup
```bash
# 1. Install Grafana
helm install grafana grafana/grafana -n monitoring

# 2. Get admin password
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode

# 3. Import dashboards
# Import from infrastructure/monitoring/dashboards/
```

### Logging Setup
```bash
# 1. Deploy FluentBit
kubectl apply -f infrastructure/logging/fluentbit-config.yaml

# 2. Deploy OpenSearch
helm install opensearch opensearch/opensearch -n logging

# 3. Verify log collection
curl -u admin:admin https://opensearch.followerintel.com/_cat/indices
```

## Phase 5: Security Hardening (Week 9-10)

### Secrets Management
```bash
# 1. Deploy External Secrets Operator
helm install external-secrets external-secrets/external-secrets -n external-secrets

# 2. Create secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name production/api/database-password \
  --secret-string <generated-password>

# 3. Configure External Secrets
kubectl apply -f infrastructure/kubernetes/production/external-secrets.yaml
```

### Network Policies
```bash
# 1. Install Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 2. Apply network policies
kubectl apply -f infrastructure/kubernetes/production/network-policies.yaml

# 3. Verify policies
kubectl get networkpolicies -n production
```

### WAF Configuration
```bash
# 1. Create WAF rules
terraform apply -target=module.waf

# 2. Associate with CloudFront
aws wafv2 associate-web-acl \
  --web-acl-arn <waf-arn> \
  --resource-arn <cloudfront-arn>

# 3. Test WAF rules
# Trigger rate limit, SQL injection attempts
```

## Phase 6: CI/CD Pipeline (Week 11-12)

### GitHub Actions Setup
```bash
# 1. Configure OIDC provider in AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

# 2. Create GitHub Actions role
terraform apply -target=module.iam.github_actions_role

# 3. Add secrets to GitHub
# SONAR_TOKEN, SNYK_TOKEN, AWS_ACCOUNT_ID, etc.

# 4. Test pipeline
git push origin main
# Monitor in GitHub Actions tab
```

### Automated Testing
```bash
# 1. Set up test environments
# Ensure postgres and redis services in CI

# 2. Configure test coverage
# Require 80% coverage

# 3. Security scanning
# Trivy, Snyk, SonarQube

# 4. Performance testing
# k6 load tests in staging
```

## Phase 7: Disaster Recovery (Week 13-14)

### DR Region Setup
```bash
# 1. Deploy infrastructure to us-west-2
cd infrastructure/terraform/environments/production
terraform workspace new dr
terraform apply -var="region=us-west-2"

# 2. Set up cross-region replication
# S3 CRR, RDS read replica, etc.

# 3. Configure Route53 failover
terraform apply -target=module.route53.failover

# 4. Test DR failover
./scripts/dr-failover-test.sh
```

### Backup Verification
```bash
# 1. Test RDS snapshot restore
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier test-restore \
  --db-snapshot-identifier latest-snapshot

# 2. Verify data integrity
psql -h test-restore... -c "SELECT COUNT(*) FROM users;"

# 3. Clean up test resources
aws rds delete-db-instance --db-instance-identifier test-restore
```

## Phase 8: Cost Optimization (Week 15-16)

### Reserved Instances
```bash
# 1. Analyze usage patterns
aws ce get-reservation-utilization \
  --time-period Start=2024-01-01,End=2024-11-17

# 2. Purchase RIs (1-year convertible)
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id <offering-id> \
  --instance-count 10

# 3. Monitor RI utilization
# Set up CloudWatch dashboard
```

### Auto-Shutdown
```bash
# 1. Deploy Lambda function for auto-shutdown
cd scripts/auto-shutdown
terraform apply

# 2. Configure schedule
# EventBridge rules: Start 8 AM, Stop 6 PM weekdays

# 3. Verify savings
aws ce get-cost-and-usage \
  --time-period Start=2024-10-01,End=2024-11-01 \
  --granularity MONTHLY
```

## Phase 9: Compliance (Week 17-18)

### SOC 2 Preparation
```bash
# 1. Enable AWS Audit Manager
# 2. Configure security controls
# 3. Set up evidence collection
# 4. Prepare for audit
```

### GDPR Implementation
```bash
# 1. Implement data export API
# 2. Implement data deletion API
# 3. Configure audit logging
# 4. Set up data retention policies
# 5. Create privacy policy
```

## Phase 10: Production Launch (Week 19-20)

### Pre-Launch Checklist
- [ ] All infrastructure deployed
- [ ] Application deployed and tested
- [ ] Monitoring and alerting configured
- [ ] Security hardening complete
- [ ] Backups verified
- [ ] DR tested
- [ ] CI/CD pipeline working
- [ ] Documentation complete
- [ ] Team trained
- [ ] Runbooks created

### Launch Day
```bash
# 1. Final smoke tests
./scripts/smoke-tests.sh --env=production

# 2. Monitor all metrics
# Grafana, Datadog, CloudWatch

# 3. Be ready for rollback
# Keep previous version ready

# 4. Communicate with team
# Slack #launches channel

# 5. Celebrate! 🎉
```

## Post-Launch Activities

### Week 1 Post-Launch
- Daily cost reviews
- Performance optimization
- User feedback collection
- Bug fixes

### Month 1 Post-Launch
- First cost optimization review
- Security audit
- DR drill
- Team retrospective

### Ongoing
- Weekly deployments
- Monthly cost reviews
- Quarterly DR drills
- Annual security audits

## Success Metrics

### Technical
- Uptime: > 99.9%
- P95 latency: < 500ms
- Error rate: < 0.1%
- Deployment frequency: Daily
- MTTR: < 1 hour

### Business
- Cost per user: < $1
- Infrastructure cost: $28k/month
- User satisfaction: > 90%
- Revenue growth: Track monthly

### Team
- Deployment confidence: High
- On-call incidents: < 5/month
- Postmortems: All incidents
- Team satisfaction: > 80%

## Troubleshooting

### Common Issues

#### EKS Nodes Not Joining Cluster
```bash
# Check IAM role
aws iam get-role --role-name eks-node-role

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check CloudWatch logs
aws logs tail /aws/eks/followerintel-production/cluster
```

#### RDS Connection Issues
```bash
# Check security group
aws rds describe-db-instances --db-instance-identifier followerintel-prod

# Test connectivity
nc -zv <rds-endpoint> 5432

# Check credentials
aws secretsmanager get-secret-value --secret-id production/api/database-password
```

#### High Costs
```bash
# Check Cost Explorer
aws ce get-cost-and-usage --time-period Start=2024-11-01,End=2024-11-17

# Identify expensive resources
aws ce get-cost-and-usage-with-resources

# Review untagged resources
aws resourcegroupstaggingapi get-resources --resource-type-filters ec2:instance
```

## Next Steps

1. **Review** all documentation
2. **Customize** for your specific needs
3. **Test** in development environment first
4. **Deploy** to staging
5. **Validate** before production
6. **Launch** with confidence
7. **Monitor** and optimize continuously

## Support

- **Documentation**: Full docs in `docs/` directory
- **Issues**: Create GitHub issue
- **Emergency**: PagerDuty on-call
- **Questions**: #infrastructure Slack channel

Good luck with your deployment! 🚀
