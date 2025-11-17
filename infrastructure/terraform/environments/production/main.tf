# Production Environment - Main Terraform Configuration
# This configuration demonstrates the complete infrastructure for production
# See full design doc at /docs/INFRASTRUCTURE_DESIGN.md

terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "followerintel-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Project     = "follower-intelligence"
    }
  }
}

# VPC, EKS, RDS, ElastiCache, S3, CloudFront, ALB configurations
# See modules/ directory for detailed implementations
