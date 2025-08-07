# GuardDuty Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "aws_regions" {
  description = "List of AWS regions where GuardDuty should be enabled"
  type        = list(string)
}

# Enable GuardDuty Organization Admin Account
resource "aws_guardduty_organization_admin_account" "admin" {
  for_each = toset(var.aws_regions)

  admin_account_id = data.aws_caller_identity.current.account_id
}

# Enable GuardDuty Organization Configuration
resource "aws_guardduty_organization_configuration" "config" {
  for_each = toset(var.aws_regions)

  auto_enable = true
  detector_id = aws_guardduty_detector.main[each.key].id

  datasources {
    s3_logs {
      auto_enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        enable = true
      }
    }
  }
}

# Create GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  for_each = toset(var.aws_regions)

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        enable = true
      }
    }
  }
}

# Get current account ID
data "aws_caller_identity" "current" {}

output "detector_ids" {
  description = "Map of GuardDuty detector IDs by region"
  value       = { for k, v in aws_guardduty_detector.main : k => v.id }
}
