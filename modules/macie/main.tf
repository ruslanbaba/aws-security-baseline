# Macie Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "aws_regions" {
  description = "List of AWS regions where Macie should be enabled"
  type        = list(string)
}

variable "macie_config" {
  description = "Macie configuration settings"
  type = object({
    finding_publishing_frequency = string
    classification_job_schedule = object({
      frequency = string
      schedule_frequency = string
    })
  })
  default = {
    finding_publishing_frequency = "FIFTEEN_MINUTES"
    classification_job_schedule = {
      frequency = "ONE_TIME"
      schedule_frequency = "DAILY"
    }
  }
}

# Enable Macie
resource "aws_macie2_account" "main" {
  for_each = toset(var.aws_regions)
  provider = aws.regional[each.value]

  finding_publishing_frequency = var.macie_config.finding_publishing_frequency
  status                      = "ENABLED"
}

# Enable Macie for Organization
resource "aws_macie2_organization_admin_account" "admin" {
  for_each = toset(var.aws_regions)
  provider = aws.regional[each.value]

  admin_account_id = data.aws_caller_identity.current.account_id
}

# Create Classification Job for S3
resource "aws_macie2_classification_job" "s3_scan" {
  for_each = toset(var.aws_regions)
  provider = aws.regional[each.value]

  name = "org-wide-s3-scan"
  job_type = "SCHEDULED"
  
  schedule_frequency {
    daily_schedule = var.macie_config.classification_job_schedule.frequency == "DAILY" ? true : null
    weekly_schedule = var.macie_config.classification_job_schedule.frequency == "WEEKLY" ? true : null
    monthly_schedule = var.macie_config.classification_job_schedule.frequency == "MONTHLY" ? true : null
  }

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = ["*"]
    }
  }
}

data "aws_caller_identity" "current" {}

output "macie_enabled_regions" {
  description = "Regions where Macie is enabled"
  value       = aws_macie2_account.main[*]
}
