# Deployment & Infrastructure Guide

## Overview
Production deployment guide for Kubernetes-based infrastructure with Infrastructure as Code (Terraform).

---

## 1. Infrastructure Architecture

### 1.1 Cloud Provider: AWS (Primary) / GCP (Alternative)

**Multi-Region Setup**:
```
┌─────────────────────────────────────────────────────────────┐
│                         Route 53 / Cloud DNS                 │
│                      (Global Load Balancing)                 │
└─────────────────────────────────────────────────────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────┐          ┌──────────────────────┐
│   US-EAST-1 (Primary)│          │   EU-WEST-1 (GDPR)   │
│                      │          │                      │
│  ┌────────────────┐ │          │  ┌────────────────┐  │
│  │  EKS Cluster   │ │          │  │  EKS Cluster   │  │
│  │  - 3 Availability│          │  │  - 3 Availability│ │
│  │    Zones       │ │          │  │    Zones       │  │
│  └────────────────┘ │          │  └────────────────┘  │
│                      │          │                      │
│  ┌────────────────┐ │          │  ┌────────────────┐  │
│  │  RDS Postgres  │ │          │  │  RDS Postgres  │  │
│  │  (Multi-AZ)    │ │          │  │  (Multi-AZ)    │  │
│  └────────────────┘ │          │  └────────────────┘  │
│                      │          │                      │
│  ┌────────────────┐ │          │  ┌────────────────┐  │
│  │  ElastiCache   │ │          │  │  ElastiCache   │  │
│  │  Redis Cluster │ │          │  │  Redis Cluster │  │
│  └────────────────┘ │          │  └────────────────┘  │
│                      │          │                      │
│  ┌────────────────┐ │          │  ┌────────────────┐  │
│  │  S3 Buckets    │ │◄─────────┤  │  S3 Buckets    │  │
│  │  (Replication) │ │          │  │  (Replication) │  │
│  └────────────────┘ │          │  └────────────────┘  │
└──────────────────────┘          └──────────────────────┘
```

### 1.2 Kubernetes Cluster Configuration

**EKS Cluster Specifications**:
```yaml
Cluster Name: platform-prod-us-east-1
K8s Version: 1.28
Control Plane: Managed by AWS

Node Groups:
  - general-purpose:
      instance_type: t3.xlarge (4 vCPU, 16 GB RAM)
      min_size: 3
      max_size: 20
      disk_size: 100 GB
      labels:
        workload: general
  
  - ai-processing:
      instance_type: g5.2xlarge (8 vCPU, 32 GB RAM, 1 GPU)
      min_size: 2
      max_size: 10
      disk_size: 200 GB
      labels:
        workload: ai
        gpu: nvidia-a10g
  
  - memory-intensive:
      instance_type: r6i.2xlarge (8 vCPU, 64 GB RAM)
      min_size: 2
      max_size: 8
      labels:
        workload: analytics
```

---

## 2. Terraform Infrastructure as Code

### 2.1 Directory Structure

```
terraform/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── elasticache/
│   ├── s3/
│   └── monitoring/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── production/
└── backend.tf
```

### 2.2 VPC Module

**terraform/modules/vpc/main.tf**:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Public Subnets (for Load Balancers)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.environment}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
  }
}

# Private Subnets (for EKS nodes)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                           = "${var.environment}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.environment}-nat-${count.index + 1}"
  }
}
```

### 2.3 EKS Cluster Module

**terraform/modules/eks/main.tf**:
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      name = "general-purpose"
      
      instance_types = ["t3.xlarge"]
      capacity_type  = "ON_DEMAND"
      
      min_size     = 3
      max_size     = 20
      desired_size = 5
      
      disk_size = 100
      
      labels = {
        workload = "general"
      }
      
      tags = {
        Environment = var.environment
      }
    }
    
    ai_processing = {
      name = "ai-processing"
      
      instance_types = ["g5.2xlarge"]
      ami_type       = "AL2_x86_64_GPU"
      capacity_type  = "ON_DEMAND" # Consider SPOT for cost savings
      
      min_size     = 2
      max_size     = 10
      desired_size = 3
      
      disk_size = 200
      
      labels = {
        workload = "ai"
        gpu      = "nvidia-a10g"
      }
      
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }

  # AWS Auth ConfigMap
  manage_aws_auth_configmap = true
  
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevOpsRole"
      username = "devops"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# NVIDIA Device Plugin (for GPU support)
resource "helm_release" "nvidia_device_plugin" {
  name       = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  namespace  = "kube-system"
  
  set {
    name  = "runtimeClassName"
    value = "nvidia"
  }
  
  depends_on = [module.eks]
}
```

### 2.4 RDS PostgreSQL Module

**terraform/modules/rds/main.tf**:
```hcl
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.instance_class # db.r6g.xlarge for production
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.database_name
  username = var.master_username
  password = random_password.db_password.result
  
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = "${var.environment}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "${var.environment}-postgres"
    Environment = var.environment
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.environment}/database/postgres/master-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}
```

### 2.5 ElastiCache Redis Module

**terraform/modules/elasticache/main.tf**:
```hcl
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.environment}-redis"
  replication_group_description = "Redis cluster for ${var.environment}"

  engine         = "redis"
  engine_version = "7.0"
  node_type      = var.node_type # cache.r6g.large for production

  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"

  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
  }
}

resource "random_password" "redis_auth_token" {
  length  = 64
  special = false
}
```

### 2.6 S3 Buckets

**terraform/modules/s3/main.tf**:
```hcl
# Generated ads storage
resource "aws_s3_bucket" "ads_storage" {
  bucket = "${var.environment}-platform-ads"

  tags = {
    Name        = "${var.environment}-platform-ads"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "ads_storage" {
  bucket = aws_s3_bucket.ads_storage.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ads_storage" {
  bucket = aws_s3_bucket.ads_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ads_storage" {
  bucket = aws_s3_bucket.ads_storage.id

  rule {
    id     = "archive-old-ads"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ads_storage" {
  bucket = aws_s3_bucket.ads_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cross-region replication for disaster recovery
resource "aws_s3_bucket_replication_configuration" "ads_storage" {
  count = var.enable_replication ? 1 : 0
  
  bucket = aws_s3_bucket.ads_storage.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.ads_storage_replica[0].arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

---

## 3. Kubernetes Manifests

### 3.1 Namespace Configuration

**k8s/base/namespaces.yaml**:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: platform-services
  labels:
    name: platform-services
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: platform-ai
  labels:
    name: platform-ai
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    name: monitoring
```

### 3.2 Service Deployment Example (AI Processing)

**k8s/services/ai-processing/deployment.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-processing-service
  namespace: platform-ai
  labels:
    app: ai-processing
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: ai-processing
  template:
    metadata:
      labels:
        app: ai-processing
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ai-processing"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/ai-processing/config"
    spec:
      serviceAccountName: ai-processing
      
      # GPU node affinity
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - ai
      
      tolerations:
      - key: nvidia.com/gpu
        operator: Equal
        value: "true"
        effect: NoSchedule
      
      containers:
      - name: ai-processing
        image: YOUR_ECR_REPO/ai-processing:latest
        imagePullPolicy: Always
        
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "INFO"
        - name: POSTGRES_HOST
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: host
        - name: REDIS_HOST
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: host
        
        # GPU resources
        resources:
          requests:
            memory: "16Gi"
            cpu: "4"
            nvidia.com/gpu: 1
          limits:
            memory: "32Gi"
            cpu: "8"
            nvidia.com/gpu: 1
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Startup probe for slow-starting containers
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
```

### 3.3 Horizontal Pod Autoscaler

**k8s/services/ai-processing/hpa.yaml**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-processing-hpa
  namespace: platform-ai
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-processing-service
  minReplicas: 3
  maxReplicas: 20
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
  # Custom metric: GPU utilization
  - type: Pods
    pods:
      metric:
        name: gpu_utilization
      target:
        type: AverageValue
        averageValue: "75"
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
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### 3.4 Service & Ingress

**k8s/services/ai-processing/service.yaml**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ai-processing-service
  namespace: platform-ai
  labels:
    app: ai-processing
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: ai-processing
```

**k8s/ingress/api-ingress.yaml**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: platform-services
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.platform.com
    secretName: api-tls-cert
  rules:
  - host: api.platform.com
    http:
      paths:
      - path: /v1/ai
        pathType: Prefix
        backend:
          service:
            name: ai-processing-service
            port:
              number: 80
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
```

---

## 4. CI/CD Pipeline

### 4.1 GitHub Actions Workflow

**.github/workflows/deploy.yml**:
```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: platform-ai-processing
  EKS_CLUSTER_NAME: platform-prod-us-east-1

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: pytest --cov=./ --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.xml

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        severity: 'CRITICAL,HIGH'
    
    - name: Check dependencies
      run: |
        pip install safety
        safety check --json

  build-and-push:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build, tag, and push image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    - name: Scan Docker image
      run: |
        docker pull aquasec/trivy
        docker run aquasec/trivy image --severity HIGH,CRITICAL $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

  deploy-staging:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v3
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}
    
    - name: Deploy to staging
      run: |
        kubectl set image deployment/ai-processing-service \
          ai-processing=$ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }} \
          -n platform-ai
        
        kubectl rollout status deployment/ai-processing-service -n platform-ai

  deploy-production:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v3
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG_PROD }}
    
    - name: Canary deployment (10%)
      run: |
        # Update canary deployment
        kubectl set image deployment/ai-processing-service-canary \
          ai-processing=$ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }} \
          -n platform-ai
        
        kubectl scale deployment/ai-processing-service-canary --replicas=1 -n platform-ai
    
    - name: Wait and monitor canary
      run: |
        sleep 600 # 10 minutes
        # Check error rate, latency, etc. (integrate with monitoring)
    
    - name: Full deployment
      run: |
        kubectl set image deployment/ai-processing-service \
          ai-processing=$ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }} \
          -n platform-ai
        
        kubectl rollout status deployment/ai-processing-service -n platform-ai
    
    - name: Scale down canary
      run: kubectl scale deployment/ai-processing-service-canary --replicas=0 -n platform-ai
```

---

## 5. Monitoring Setup

### 5.1 Prometheus & Grafana (Helm)

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values prometheus-values.yaml

# Install Grafana (included in kube-prometheus-stack)
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**prometheus-values.yaml**:
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 500Gi

grafana:
  adminPassword: "CHANGE_ME"
  persistence:
    enabled: true
    size: 10Gi
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        options:
          path: /var/lib/grafana/dashboards/default

alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack'
    receivers:
    - name: 'slack'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#platform-alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
```

---

## 6. Cost Estimation

### 6.1 AWS Cost Breakdown (Monthly, Production)

**Compute (EKS)**:
- General Purpose nodes (5x t3.xlarge): $365/month
- AI Processing nodes (3x g5.2xlarge): $2,490/month
- Analytics nodes (2x r6i.2xlarge): $870/month
- EKS Control Plane: $73/month
- **Subtotal: $3,798/month**

**Databases**:
- RDS PostgreSQL (db.r6g.xlarge, Multi-AZ): $580/month
- MongoDB Atlas (M30, 3-node replica): $750/month
- ElastiCache Redis (cache.r6g.large, 3 nodes): $390/month
- **Subtotal: $1,720/month**

**Storage**:
- S3 Standard (1 TB): $23/month
- S3 Glacier (5 TB archive): $20/month
- EBS Volumes (2 TB): $200/month
- **Subtotal: $243/month**

**Networking**:
- Data Transfer Out (10 TB/month): $900/month
- NAT Gateway (3 AZs): $97/month
- Application Load Balancer: $23/month
- **Subtotal: $1,020/month**

**AI/ML APIs** (Variable):
- OpenAI API (GPT-4, 10M tokens/month): $600/month
- DALL-E 3 (10K images/month): $400/month
- **Subtotal: $1,000/month**

**Monitoring & Logging**:
- CloudWatch Logs (100 GB/month): $50/month
- Prometheus/Grafana (self-hosted on EKS): Included
- **Subtotal: $50/month**

**Security**:
- AWS Shield Standard: Free
- AWS WAF: $50/month
- Secrets Manager (50 secrets): $20/month
- **Subtotal: $70/month**

**TOTAL MONTHLY COST: ~$7,900/month**

### 6.2 Cost Optimization Strategies

1. **Use Spot Instances** for AI processing (50-70% savings)
2. **Reserved Instances** for baseline capacity (30-40% savings)
3. **S3 Lifecycle Policies** to move old data to Glacier
4. **Autoscaling** to scale down during off-peak hours
5. **CDN** (CloudFront) to reduce data transfer costs
6. **Right-sizing** instances based on actual usage
7. **Self-hosted LLMs** (LLaMA, Mixtral) for high-volume use cases

**Optimized Monthly Cost: ~$5,000/month** (37% reduction)

---

## 7. Disaster Recovery Plan

### 7.1 Backup Strategy

**Automated Backups**:
- RDS: Daily automated backups, 30-day retention, PITR
- MongoDB: Continuous backups via Atlas
- Redis: Daily snapshots, 7-day retention
- S3: Versioning + cross-region replication
- EBS: Daily snapshots, 30-day retention

**Backup Testing**: Monthly restore drills

### 7.2 Failover Procedures

**Database Failover**:
1. RDS Multi-AZ automatic failover (30-60 seconds)
2. MongoDB Atlas automatic failover (< 30 seconds)
3. Application retry logic handles transient failures

**Regional Failover**:
1. Route53 health checks detect region failure
2. Automatic DNS failover to secondary region (< 60 seconds)
3. Data replication keeps regions in sync (< 5-minute lag)

**RPO**: 5 minutes (max data loss)
**RTO**: 1 hour (max downtime)

---

## Summary

This deployment guide provides:
- **Infrastructure as Code**: Terraform modules for repeatable deployments
- **Kubernetes Best Practices**: Health checks, autoscaling, resource limits
- **CI/CD Pipeline**: Automated testing, security scanning, deployment
- **Monitoring**: Prometheus, Grafana, alerting
- **Cost Optimization**: Strategies to reduce cloud spend
- **Disaster Recovery**: Backup and failover procedures

The architecture is designed for high availability, scalability, and operational excellence.

