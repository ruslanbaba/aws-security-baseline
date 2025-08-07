# S3 Encryption Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "kms_key_config" {
  description = "Configuration for KMS keys"
  type = object({
    deletion_window_in_days = number
    enable_key_rotation    = bool
    alias_prefix          = string
  })
}

# Create KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = var.kms_key_config.deletion_window_in_days
  enable_key_rotation     = var.kms_key_config.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# Create alias for the KMS key
resource "aws_kms_alias" "s3" {
  name          = "alias/${var.kms_key_config.alias_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# Create S3 bucket encryption configuration
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = "*"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create organization-wide S3 default encryption policy
resource "aws_organizations_policy" "s3_encryption" {
  name = "s3-encryption-policy"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedS3PutObject"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption": ["AES256", "aws:kms"]
          }
        }
      }
    ]
  })
}

# Get current account ID
data "aws_caller_identity" "current" {}

output "kms_key_arn" {
  description = "ARN of the created KMS key"
  value       = aws_kms_key.s3.arn
}

output "kms_key_alias" {
  description = "Alias of the created KMS key"
  value       = aws_kms_alias.s3.name
}
