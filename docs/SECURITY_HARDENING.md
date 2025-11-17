# Security Hardening Guide

## Security Checklist

### Network Security
- [x] VPC with private subnets
- [x] Security groups (least privilege)
- [x] Network ACLs
- [x] AWS WAF enabled
- [x] DDoS protection (Shield)
- [x] VPC Flow Logs
- [x] Private Link for AWS services

### Identity & Access Management
- [x] IAM roles (no long-term credentials)
- [x] MFA required for all users
- [x] OIDC for GitHub Actions
- [x] Service accounts per microservice
- [x] RBAC in Kubernetes
- [x] Session timeout (12 hours)

### Data Protection
- [x] Encryption at rest (KMS)
- [x] Encryption in transit (TLS 1.2+)
- [x] Database encryption
- [x] S3 bucket encryption
- [x] EBS volume encryption
- [x] Secrets Manager

### Container Security
- [x] Non-root containers
- [x] Read-only filesystems
- [x] Pod Security Policies
- [x] Network policies
- [x] Image scanning
- [x] Runtime protection

### Monitoring & Detection
- [x] GuardDuty (threat detection)
- [x] Security Hub
- [x] CloudTrail (audit logging)
- [x] Config (compliance)
- [x] Macie (data loss prevention)

## Security Implementation

### 1. Pod Security Standards

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-api-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000
    fsGroup: 10000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: api
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### 2. Network Policies

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
    - namespaceSelector:
        matchLabels:
          name: production
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

### 3. Secrets Management

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name production/api/database-password \
  --secret-string "$(openssl rand -base64 32)"

# Retrieve in Kubernetes using External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: api-secrets
  data:
  - secretKey: database-password
    remoteRef:
      key: production/api/database-password
```

### 4. Security Scanning Pipeline

```yaml
# .github/workflows/security-scan.yml
- name: Trivy vulnerability scan
  run: |
    trivy image \
      --severity CRITICAL,HIGH \
      --exit-code 1 \
      myapp:latest

- name: Snyk security test
  run: |
    snyk test \
      --severity-threshold=high \
      --fail-on=all

- name: OWASP ZAP scan
  run: |
    docker run -t owasp/zap2docker-stable \
      zap-baseline.py -t https://staging.app.com
```

## Compliance & Audit

### SOC 2 Requirements
- Access controls (MFA, RBAC)
- Encryption (at rest & in transit)
- Network security
- Vulnerability management
- Incident response

### GDPR Requirements
- Data subject rights (export, delete)
- Data encryption
- Audit logging
- Data retention policies
- Breach notification (72 hours)

### Security Audit Schedule
- **Daily**: Automated vulnerability scanning
- **Weekly**: Security patch review
- **Monthly**: Access review
- **Quarterly**: Penetration testing
- **Annually**: Full security audit

