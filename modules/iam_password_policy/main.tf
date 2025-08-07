# IAM Password Policy Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "password_policy" {
  description = "Password policy configuration"
  type = object({
    minimum_password_length        = number
    require_lowercase             = bool
    require_numbers               = bool
    require_uppercase             = bool
    require_symbols               = bool
    allow_users_to_change_password = bool
    max_password_age              = number
    password_reuse_prevention     = number
  })
  default = {
    minimum_password_length        = 14
    require_lowercase             = true
    require_numbers               = true
    require_uppercase             = true
    require_symbols               = true
    allow_users_to_change_password = true
    max_password_age              = 90
    password_reuse_prevention     = 24
  }
}

# Set organization-wide password policy
resource "aws_organizations_policy" "password_policy" {
  name = "organization-password-policy"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforcePasswordPolicy"
        Effect = "Deny"
        Action = [
          "iam:CreateLoginProfile",
          "iam:UpdateLoginProfile"
        ]
        Resource = "*"
        Condition = {
          NumericLessThan = {
            "iam:PasswordLength": var.password_policy.minimum_password_length
          }
        }
      }
    ]
  })
}

# Apply password policy to all member accounts
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = var.password_policy.minimum_password_length
  require_lowercase             = var.password_policy.require_lowercase
  require_numbers               = var.password_policy.require_numbers
  require_uppercase             = var.password_policy.require_uppercase
  require_symbols               = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  max_password_age              = var.password_policy.max_password_age
  password_reuse_prevention     = var.password_policy.password_reuse_prevention
}
