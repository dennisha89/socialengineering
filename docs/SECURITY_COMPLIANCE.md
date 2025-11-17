# Security & Compliance Implementation Guide

## Overview
Comprehensive security architecture and GDPR compliance strategy for the platform.

---

## 1. Security Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Perimeter Security                                │
│  - DDoS Protection (CloudFlare/AWS Shield)                  │
│  - WAF (Web Application Firewall)                           │
│  - Rate Limiting                                            │
│  - Geographic Restrictions                                  │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Network Security                                  │
│  - VPC with Private Subnets                                 │
│  - Security Groups / Network Policies                       │
│  - Service Mesh (mTLS)                                      │
│  - VPN for Admin Access                                     │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Application Security                              │
│  - Authentication (OAuth 2.0 / OIDC)                        │
│  - Authorization (RBAC)                                     │
│  - Input Validation                                         │
│  - Output Encoding                                          │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────┐
│  Layer 4: Data Security                                     │
│  - Encryption at Rest (AES-256)                             │
│  - Encryption in Transit (TLS 1.3)                          │
│  - Secrets Management (Vault)                               │
│  - Data Masking / Anonymization                             │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────┐
│  Layer 5: Monitoring & Response                             │
│  - Security Information and Event Management (SIEM)         │
│  - Intrusion Detection (IDS)                                │
│  - Audit Logging                                            │
│  - Incident Response Plan                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Authentication & Authorization

### 2.1 OAuth 2.0 / OpenID Connect Flow

**Implementation with Keycloak**:

```
User → Frontend App → API Gateway → Keycloak
                            │
                            ▼
                    Validate JWT Token
                            │
                            ▼
                    Extract user claims
                            │
                            ▼
                    Check permissions (RBAC)
                            │
                            ▼
                    Route to service
```

### 2.2 JWT Token Structure

**Access Token** (15-minute expiry):
```json
{
  "iss": "https://auth.platform.com",
  "sub": "user-uuid",
  "aud": "platform-api",
  "exp": 1700233200,
  "iat": 1700232300,
  "email": "user@example.com",
  "roles": ["user", "pro_subscriber"],
  "org_id": "org-uuid",
  "tier": "pro"
}
```

**Refresh Token** (30-day expiry):
- Stored securely in HTTP-only cookie
- Single-use (rotation on refresh)
- Revocable via database

### 2.3 Role-Based Access Control (RBAC)

**Roles**:
- `system_admin`: Full system access
- `org_owner`: Organization owner
- `org_admin`: Organization administrator
- `org_member`: Organization member (read/write)
- `org_viewer`: Organization viewer (read-only)
- `user`: Individual user

**Permission Matrix**:

| Resource | Owner | Admin | Member | Viewer |
|----------|-------|-------|--------|--------|
| View campaigns | ✓ | ✓ | ✓ | ✓ |
| Create campaigns | ✓ | ✓ | ✓ | ✗ |
| Delete campaigns | ✓ | ✓ | ✗ | ✗ |
| Manage billing | ✓ | ✓ | ✗ | ✗ |
| Invite members | ✓ | ✓ | ✗ | ✗ |
| View analytics | ✓ | ✓ | ✓ | ✓ |

**Implementation**:
```python
# Decorator-based authorization
@require_permission("campaigns:write")
async def create_campaign(user: User, campaign_data: dict):
    # Check if user has permission
    if not user.has_permission("campaigns:write"):
        raise ForbiddenError("Insufficient permissions")
    
    # Check organization membership
    if not user.is_member_of(campaign_data.org_id):
        raise ForbiddenError("Not a member of this organization")
    
    # Proceed with creation
    ...
```

### 2.4 API Key Authentication (Programmatic Access)

**Structure**:
```
pkey_live_abc123def456ghi789...  (production)
pkey_test_xyz789uvw456rst123...  (test)
```

**Features**:
- Scoped permissions (read-only, write, admin)
- IP whitelisting
- Rate limiting per key
- Expiration dates
- Audit logging

**Storage**:
- Hash API keys in database (bcrypt)
- Never store plaintext keys
- Show key only once during creation

---

## 3. Data Encryption

### 3.1 Encryption at Rest

**Database Encryption**:
- **PostgreSQL**: Transparent Data Encryption (TDE) via AWS RDS/Cloud SQL
- **MongoDB**: Encryption at rest via MongoDB Atlas or manual setup
- **Redis**: Encryption via ElastiCache or Redis Enterprise

**Sensitive Field Encryption** (Application-level):
```python
from cryptography.fernet import Fernet
import os

# Load encryption key from secrets manager
ENCRYPTION_KEY = os.getenv("FIELD_ENCRYPTION_KEY")
cipher = Fernet(ENCRYPTION_KEY)

class SocialAccount:
    def __init__(self, access_token: str):
        # Encrypt tokens before storage
        self.access_token_encrypted = cipher.encrypt(access_token.encode())
    
    def get_access_token(self) -> str:
        # Decrypt when needed
        return cipher.decrypt(self.access_token_encrypted).decode()
```

**Fields to Encrypt**:
- Social media access tokens
- Social media refresh tokens
- Payment card details (if stored)
- User PII (if required)

**Key Management**:
- AWS KMS or Google Cloud KMS
- Key rotation every 90 days
- Separate keys per environment (dev, staging, prod)

### 3.2 Encryption in Transit

**External Communication**:
- **TLS 1.3** for all external APIs
- Perfect Forward Secrecy (PFS)
- Certificate pinning for mobile apps
- HSTS (HTTP Strict Transport Security)

**Internal Communication**:
- **mTLS** (mutual TLS) via service mesh (Istio/Linkerd)
- Certificate-based authentication between services
- Automatic certificate rotation

**Certificate Management**:
- Let's Encrypt for public-facing services
- cert-manager for Kubernetes cluster
- 90-day certificate rotation

---

## 4. Secrets Management

### 4.1 HashiCorp Vault Setup

**Architecture**:
```
Applications
    │
    ├──► Vault (HA Cluster)
    │       │
    │       ├──► Secret Engine: KV (API keys, credentials)
    │       ├──► Secret Engine: Database (dynamic DB credentials)
    │       ├──► Secret Engine: PKI (certificates)
    │       └──► Audit Log
    │
    └──► Kubernetes Secrets (injected by Vault)
```

**Secret Types**:
1. **Static Secrets**: API keys, OAuth secrets
2. **Dynamic Secrets**: Database credentials (auto-generated, short-lived)
3. **Encryption Keys**: Field-level encryption keys

**Access Control**:
```hcl
# Policy for AI Processing Service
path "secret/data/ai-processing/*" {
  capabilities = ["read"]
}

path "database/creds/mongodb-readonly" {
  capabilities = ["read"]
}
```

**Secret Rotation**:
- Database credentials: Every 24 hours (dynamic)
- API keys: Every 90 days (manual)
- Encryption keys: Every 180 days (automatic)

### 4.2 Kubernetes Secrets Integration

**Vault Injector** (Sidecar pattern):
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "ai-processing"
    vault.hashicorp.com/agent-inject-secret-config: "secret/data/ai-processing/config"
spec:
  containers:
  - name: app
    image: ai-processing:latest
    env:
    - name: OPENAI_API_KEY
      valueFrom:
        secretKeyRef:
          name: vault-secret
          key: openai_api_key
```

---

## 5. Input Validation & Output Encoding

### 5.1 Input Validation

**API Gateway Level** (JSON Schema):
```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 255,
      "pattern": "^[a-zA-Z0-9\\s-_]+$"
    },
    "email": {
      "type": "string",
      "format": "email"
    }
  },
  "required": ["name", "email"]
}
```

**Application Level**:
```python
from pydantic import BaseModel, EmailStr, validator

class CreateCampaignRequest(BaseModel):
    name: str
    description: str | None
    budget_amount: float
    
    @validator('name')
    def validate_name(cls, v):
        if len(v) < 1 or len(v) > 255:
            raise ValueError('Name must be 1-255 characters')
        if not v.replace(' ', '').replace('-', '').replace('_', '').isalnum():
            raise ValueError('Name contains invalid characters')
        return v
    
    @validator('budget_amount')
    def validate_budget(cls, v):
        if v < 0 or v > 1000000:
            raise ValueError('Budget must be between $0 and $1,000,000')
        return v
```

**SQL Injection Prevention**:
```python
# ✓ GOOD: Parameterized queries
cursor.execute(
    "SELECT * FROM users WHERE email = %s",
    (email,)
)

# ✗ BAD: String concatenation
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

### 5.2 Output Encoding

**XSS Prevention**:
```python
from markupsafe import escape

def render_user_content(content: str) -> str:
    # Escape HTML entities
    return escape(content)

# In templates
<div>{{ user_bio | escape }}</div>
```

**Content Security Policy (CSP)**:
```
Content-Security-Policy: 
  default-src 'self'; 
  script-src 'self' 'unsafe-inline' https://cdn.example.com; 
  img-src 'self' https://s3.amazonaws.com data:; 
  style-src 'self' 'unsafe-inline';
  connect-src 'self' https://api.platform.com wss://api.platform.com;
```

---

## 6. GDPR Compliance

### 6.1 Data Subject Rights

#### Right to Access (Article 15)
**Implementation**:
```python
async def export_user_data(user_id: str) -> dict:
    """Export all user data in JSON format"""
    
    # Collect from all services
    user_profile = await user_service.get_profile(user_id)
    social_accounts = await social_service.get_accounts(user_id)
    followers = await follower_service.get_all_followers(user_id)
    campaigns = await campaign_service.get_campaigns(user_id)
    analytics = await analytics_service.get_data(user_id)
    
    # Structure data
    export_data = {
        "profile": user_profile,
        "social_accounts": social_accounts,
        "followers": followers,
        "campaigns": campaigns,
        "analytics": analytics,
        "export_date": datetime.utcnow().isoformat(),
        "format_version": "1.0"
    }
    
    # Upload to S3 with expiring link
    s3_key = f"exports/{user_id}/{uuid.uuid4()}.json"
    await s3.upload_json(s3_key, export_data)
    download_url = await s3.generate_presigned_url(s3_key, expires_in=86400)
    
    return {"download_url": download_url}
```

#### Right to Erasure (Article 17)
**Implementation**:
```python
async def delete_user_account(user_id: str, reason: str):
    """Delete user account and all associated data"""
    
    # Step 1: Soft delete (mark as deleted)
    await user_service.soft_delete(user_id)
    
    # Step 2: Cancel subscriptions
    await billing_service.cancel_subscription(user_id, immediate=True)
    
    # Step 3: Schedule hard deletion (30 days)
    await job_queue.enqueue(
        "hard_delete_user",
        user_id=user_id,
        scheduled_at=datetime.utcnow() + timedelta(days=30)
    )
    
    # Step 4: Anonymize immediately in analytics
    await analytics_service.anonymize_user_data(user_id)
    
    # Step 5: Log deletion request (for audit)
    await audit_log.log_event(
        event_type="user_deletion_requested",
        user_id=user_id,
        reason=reason,
        scheduled_deletion=True
    )

async def hard_delete_user(user_id: str):
    """Permanent deletion after grace period"""
    
    # Delete from all services
    await user_service.hard_delete(user_id)
    await social_service.delete_accounts(user_id)
    await follower_service.delete_followers(user_id)
    await campaign_service.delete_campaigns(user_id)
    await segment_service.delete_segments(user_id)
    
    # Keep billing records (legal requirement)
    await billing_service.anonymize_records(user_id)
    
    # Delete from vector database
    await vector_db.delete_user_embeddings(user_id)
    
    # Delete files from S3
    await s3.delete_user_files(user_id)
```

#### Right to Data Portability (Article 20)
**Format**: JSON (machine-readable)
**Delivery**: Download link via email (24-hour expiry)

#### Right to Rectification (Article 16)
**Implementation**: Standard update endpoints with audit logging

### 6.2 Consent Management

**Consent Types**:
1. **Account Creation**: Terms of Service, Privacy Policy
2. **Social Media Connection**: Platform-specific permissions
3. **Marketing Communications**: Email, SMS (opt-in)
4. **Data Processing**: AI analysis, persona generation
5. **Third-party Sharing**: If applicable

**Database Schema**:
```sql
CREATE TABLE user_consents (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    consent_type VARCHAR(100), -- tos, privacy_policy, marketing_email, etc.
    consent_version VARCHAR(50), -- track consent version
    granted BOOLEAN,
    granted_at TIMESTAMP,
    revoked_at TIMESTAMP,
    ip_address VARCHAR(50),
    user_agent TEXT,
    
    INDEX idx_user_consents (user_id, consent_type)
);
```

**Consent Withdrawal**:
```python
async def revoke_consent(user_id: str, consent_type: str):
    """Revoke a specific consent"""
    
    # Update consent record
    await consent_service.revoke(user_id, consent_type)
    
    # Take action based on consent type
    if consent_type == "marketing_email":
        await email_service.unsubscribe(user_id)
    
    elif consent_type == "data_processing":
        # Stop AI analysis
        await ai_service.stop_processing(user_id)
        await segment_service.remove_from_segments(user_id)
    
    elif consent_type == "social_connection":
        # Disconnect social accounts
        await social_service.disconnect_all(user_id)
```

### 6.3 Data Minimization

**Principles**:
1. Only collect data necessary for functionality
2. Delete data when no longer needed
3. Aggregate data when possible (analytics)

**Implementation**:
```python
# ✓ GOOD: Only collect necessary fields
follower_data = {
    "username": follower.username,
    "follower_count": follower.follower_count,
    "bio": follower.bio,
    # Do NOT store: email, phone, address (unless explicitly needed)
}

# ✓ GOOD: Aggregate before storing
daily_metrics = {
    "date": "2025-11-17",
    "total_impressions": 5000,
    "avg_ctr": 0.025,
    # Individual user-level data not stored
}
```

### 6.4 Privacy by Design

**Data Protection Impact Assessment (DPIA)**:
- Required for high-risk processing
- Document risks and mitigation strategies
- Review annually

**Privacy Features**:
1. **Anonymization**: Remove PII from analytics
2. **Pseudonymization**: Replace user IDs with random IDs in logs
3. **Data Segregation**: Separate EU user data (if multi-region)
4. **Access Logs**: Track who accesses what data

---

## 7. Security Monitoring & Incident Response

### 7.1 Security Information and Event Management (SIEM)

**Events to Monitor**:
- Failed login attempts (brute force detection)
- Privilege escalation attempts
- Unusual API access patterns
- Database query anomalies
- File access violations
- Configuration changes

**SIEM Stack**:
- **Collection**: Fluentd/Fluent Bit
- **Storage**: Elasticsearch
- **Analysis**: Kibana + Alerting
- **SOAR**: TheHive or Cortex

### 7.2 Intrusion Detection

**Tools**:
- **Network IDS**: Suricata or Snort
- **Host IDS**: OSSEC or Wazuh
- **Container Security**: Falco

**Detection Rules**:
```yaml
# Example: Detect privilege escalation
- rule: Privilege Escalation Attempt
  desc: Detect sudo or su execution in container
  condition: >
    spawned_process and 
    (proc.name = "sudo" or proc.name = "su") and 
    container.id != host
  priority: CRITICAL
  output: "Privilege escalation in container (user=%user.name command=%proc.cmdline)"
```

### 7.3 Audit Logging

**What to Log**:
- User authentication (login, logout, failed attempts)
- Data access (who accessed what, when)
- Data modifications (create, update, delete)
- Permission changes
- Configuration changes
- API calls (especially sensitive endpoints)

**Log Format** (Structured JSON):
```json
{
  "timestamp": "2025-11-17T10:30:00Z",
  "event_type": "user_login",
  "user_id": "uuid",
  "email": "user@example.com",
  "ip_address": "203.0.113.42",
  "user_agent": "Mozilla/5.0...",
  "success": true,
  "mfa_used": true,
  "session_id": "session_uuid",
  "location": {
    "country": "US",
    "city": "San Francisco"
  }
}
```

**Log Retention**:
- Security logs: 1 year
- Audit logs: 2 years (compliance)
- Application logs: 90 days

**Immutable Logging**:
- Append-only storage
- Write to separate logging service
- No deletion capability (except automated retention)

### 7.4 Incident Response Plan

**Phases**:
1. **Preparation**: Define roles, tools, playbooks
2. **Detection**: SIEM alerts, user reports
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat, patch vulnerabilities
5. **Recovery**: Restore services, verify integrity
6. **Lessons Learned**: Post-mortem, improve defenses

**Incident Severity Levels**:
- **P0 (Critical)**: Data breach, complete service outage
- **P1 (High)**: Partial service outage, security vulnerability
- **P2 (Medium)**: Performance degradation, minor security issue
- **P3 (Low)**: Informational, no immediate impact

**Breach Notification**:
- **GDPR**: Notify authorities within 72 hours
- **Users**: Notify affected users without undue delay
- **Documentation**: Maintain breach register

---

## 8. Penetration Testing & Vulnerability Management

### 8.1 Regular Security Assessments

**Frequency**:
- **Automated Scans**: Weekly (OWASP ZAP, Nessus)
- **Manual Penetration Tests**: Quarterly
- **Third-party Audits**: Annually
- **Bug Bounty Program**: Continuous

### 8.2 Vulnerability Scanning

**Tools**:
- **Container Images**: Trivy, Clair, Snyk
- **Dependencies**: Dependabot, npm audit, safety (Python)
- **Infrastructure**: Nessus, OpenVAS
- **SAST**: SonarQube, Semgrep
- **DAST**: OWASP ZAP, Burp Suite

**CI/CD Integration**:
```yaml
# GitHub Actions
- name: Scan Docker Image
  run: |
    docker pull aquasec/trivy
    trivy image --severity HIGH,CRITICAL myapp:${{ github.sha }}
    
- name: Check Dependencies
  run: |
    npm audit --audit-level=high
    safety check --json
```

### 8.3 Patch Management

**SLA**:
- **Critical vulnerabilities**: Patch within 24 hours
- **High vulnerabilities**: Patch within 7 days
- **Medium vulnerabilities**: Patch within 30 days
- **Low vulnerabilities**: Patch in next release cycle

---

## 9. Compliance Certifications

### 9.1 SOC 2 Type II
- Annual audit by third-party auditor
- Focus: Security, Availability, Confidentiality

### 9.2 ISO 27001
- Information Security Management System (ISMS)
- Risk assessment and treatment

### 9.3 GDPR
- EU data protection regulation
- DPO (Data Protection Officer) if required

### 9.4 PCI DSS (if handling payments)
- Payment Card Industry Data Security Standard
- Required if storing card data

---

## 10. Security Checklist

### Development Phase
- [ ] Secure coding guidelines documented
- [ ] Code review process includes security checks
- [ ] SAST integrated in CI/CD
- [ ] Dependency scanning automated
- [ ] Secrets never committed to Git

### Deployment Phase
- [ ] Container images scanned
- [ ] Network policies configured
- [ ] TLS certificates valid
- [ ] Secrets injected via Vault
- [ ] Least privilege access configured

### Production Phase
- [ ] SIEM monitoring active
- [ ] Audit logging enabled
- [ ] Backups automated and tested
- [ ] Incident response plan documented
- [ ] Security training completed

### Compliance Phase
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Cookie consent implemented
- [ ] Data export/deletion endpoints working
- [ ] Consent management system active
- [ ] DPO appointed (if required)
- [ ] Data processing agreements signed

---

## Summary

This security and compliance architecture provides:
- **Defense in Depth**: Multiple security layers
- **GDPR Compliance**: Data subject rights, consent management
- **Proactive Security**: Monitoring, scanning, testing
- **Incident Response**: Prepared for security events
- **Continuous Improvement**: Regular audits and updates

Security is not a one-time implementation but an ongoing process of assessment, improvement, and vigilance.

