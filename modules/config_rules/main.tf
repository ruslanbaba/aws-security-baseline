# AWS Config Rules Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "enabled_rules" {
  description = "List of AWS Config rules to enable"
  type = list(object({
    name             = string
    description      = string
    input_parameters = map(string)
    scope           = map(string)
  }))
}

variable "aws_regions" {
  description = "List of AWS regions where Config rules should be applied"
  type        = list(string)
}

# Enable AWS Config Recording
resource "aws_config_configuration_recorder" "org" {
  for_each = toset(var.aws_regions)

  name     = "config-recorder-${each.key}"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resources = true
  }
}

# Create Config Rules
resource "aws_config_organization_managed_rule" "rules" {
  for_each = {
    for rule in var.enabled_rules : rule.name => rule
  }

  name            = each.value.name
  description     = each.value.description
  organization_id = var.organization_id

  input_parameters = jsonencode(each.value.input_parameters)

  dynamic "scope" {
    for_each = each.value.scope != null ? [each.value.scope] : []
    content {
      compliance_resource_types = scope.value.resource_types
    }
  }
}

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "AWSConfigRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies to the IAM role
resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

output "config_rule_arns" {
  description = "ARNs of created Config rules"
  value       = { for k, v in aws_config_organization_managed_rule.rules : k => v.arn }
}
