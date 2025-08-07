# Main Terraform configuration for AWS Security Baseline

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org-name"

    workspaces {
      prefix = "aws-security-baseline-"
    }
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.assume_role_arn
  }
}

# Organization Management
module "organization" {
  source = "./modules/organization"
  
  org_name    = var.organization_name
  org_email   = var.organization_email
  aws_regions = var.enabled_regions
}

# Service Control Policies
module "service_control_policies" {
  source = "./modules/scp"
  
  organization_id = module.organization.org_id
  scps_config    = var.service_control_policies
}

# AWS Config Rules
module "config_rules" {
  source = "./modules/config_rules"
  
  organization_id = module.organization.org_id
  enabled_rules  = var.config_rules
  aws_regions    = var.enabled_regions
}

# GuardDuty
module "guardduty" {
  source = "./modules/guardduty"
  
  organization_id = module.organization.org_id
  aws_regions    = var.enabled_regions
}

# S3 Encryption
module "s3_encryption" {
  source = "./modules/s3_encryption"
  
  organization_id = module.organization.org_id
  kms_key_config = var.kms_key_config
}

# VPC Flow Logs
module "vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  
  organization_id = module.organization.org_id
  aws_regions    = var.enabled_regions
  log_retention  = var.flow_logs_retention
}
