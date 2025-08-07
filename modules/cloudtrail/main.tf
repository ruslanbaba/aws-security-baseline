# CloudTrail Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "aws_regions" {
  description = "List of AWS regions where CloudTrail should be enabled"
  type        = list(string)
}

variable "cloudtrail_config" {
  description = "CloudTrail configuration settings"
  type = object({
    retention_period          = number
    enable_log_file_validation = bool
    include_global_events     = bool
    is_multi_region          = bool
    enable_sns               = bool
    sns_topic_name           = string
  })
  default = {
    retention_period          = 365
    enable_log_file_validation = true
    include_global_events     = true
    is_multi_region          = true
    enable_sns               = true
    sns_topic_name           = "cloudtrail-alerts"
  }
}

# Create S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "aws-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

# Enable S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create CloudTrail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "organization-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = var.cloudtrail_config.include_global_events
  is_multi_region_trail        = var.cloudtrail_config.is_multi_region
  enable_log_file_validation   = var.cloudtrail_config.enable_log_file_validation
  is_organization_trail        = true

  dynamic "event_selector" {
    for_each = var.cloudtrail_config.is_multi_region ? [1] : []
    content {
      read_write_type           = "All"
      include_management_events = true

      data_resource {
        type   = "AWS::S3::Object"
        values = ["arn:aws:s3:::"]
      }
    }
  }

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail_cloudwatch.arn
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/organization-logs"
  retention_in_days = var.cloudtrail_config.retention_period
}

# IAM role for CloudTrail to CloudWatch integration
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "CloudTrailToCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# SNS Topic for CloudTrail alerts
resource "aws_sns_topic" "cloudtrail_alerts" {
  count = var.cloudtrail_config.enable_sns ? 1 : 0
  name  = var.cloudtrail_config.sns_topic_name
}

# Get current account ID
data "aws_caller_identity" "current" {}

output "cloudtrail_arn" {
  description = "ARN of the created CloudTrail"
  value       = aws_cloudtrail.organization_trail.arn
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudTrail alerts"
  value       = var.cloudtrail_config.enable_sns ? aws_sns_topic.cloudtrail_alerts[0].arn : null
}
