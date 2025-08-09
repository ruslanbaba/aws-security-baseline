# AWS Enterprise Security Baseline Automation

## Overview
This project automates the enforcement of AWS security baselines across a multi-account AWS Organization using Terraform Enterprise. It includes over 200 reusable Terraform modules for:
- Service Control Policies (SCPs)
- Mandatory AWS Config rules
- GuardDuty enablement
- S3 encryption
- VPC flow logging

The solution integrates with Jenkins for deployment and Slack for non-compliance alerts.

## Features
- **SCP Enforcement:** Restricts and manages permissions organization-wide.
- **Config Rules:** Ensures compliance with security configurations.
- **GuardDuty:** Enables threat detection in all accounts.
- **S3 Encryption:** Enforces default encryption for all S3 buckets.
- **VPC Flow Logging:** Captures network traffic logs for all VPCs.
- **Jenkins Integration:** Automates deployment and compliance checks.
- **Slack Alerts:** Notifies on non-compliance and remediation events.

## Architecture
- **Terraform Enterprise:** Centralized infrastructure management and policy enforcement.
- **AWS Organization:** Security controls applied across 50+ accounts using OUs.
- **Jenkins:** Orchestrates Terraform runs and compliance checks.
- **Slack:** Receives notifications for non-compliance events.

## Getting Started
1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   ```
2. **Configure AWS Organization:**
   - Add all accounts to the organization and set required permissions.
3. **Terraform Enterprise Setup:**
   - Import modules and configure workspaces per account/OU.
4. **Jenkins Integration:**
   - Set up pipelines for Terraform runs and compliance checks.
5. **Slack Integration:**
   - Configure Slack webhooks for alerting.

## Module Structure
- `modules/scp/` - SCP enforcement
- `modules/config_rules/` - AWS Config rules
- `modules/guardduty/` - GuardDuty enablement
- `modules/s3_encryption/` - S3 encryption
- `modules/vpc_flow_logs/` - VPC flow logging

## Example Usage
```hcl
module "scp_enforcement" {
  source = "./modules/scp"
  # ...module variables...
}

module "config_rules" {
  source = "./modules/config_rules"
  # ...module variables...
}
```

## Compliance & Monitoring
- Modules are reusable and parameterized for different accounts/OUs.
- Non-compliance detected via AWS Config and GuardDuty, with Slack alerts.
- Remediation can be automated or manual.


