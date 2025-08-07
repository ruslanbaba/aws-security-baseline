# Automated Remediation Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "remediation_config" {
  description = "Configuration for automated remediation actions"
  type = map(object({
    finding_type = string
    action       = string
    parameters   = map(string)
    sns_topic    = string
  }))
}

# Create EventBridge rules for findings
resource "aws_cloudwatch_event_rule" "security_finding" {
  for_each = var.remediation_config

  name        = "remediate-${each.key}"
  description = "Trigger remediation for ${each.value.finding_type}"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Types = [each.value.finding_type]
      }
    }
  })
}

# Lambda function for remediation
resource "aws_lambda_function" "remediation" {
  for_each = var.remediation_config

  filename         = "${path.module}/lambda/remediation.zip"
  function_name    = "security-remediation-${each.key}"
  role            = aws_iam_role.remediation_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      ACTION_TYPE = each.value.action
      PARAMETERS  = jsonencode(each.value.parameters)
      SNS_TOPIC   = each.value.sns_topic
    }
  }
}

# IAM role for Lambda
resource "aws_iam_role" "remediation_lambda" {
  name = "SecurityRemediationLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# EventBridge target
resource "aws_cloudwatch_event_target" "remediation" {
  for_each = var.remediation_config

  rule      = aws_cloudwatch_event_rule.security_finding[each.key].name
  target_id = "SecurityRemediationLambda"
  arn       = aws_lambda_function.remediation[each.key].arn
}

# SNS Topic for remediation notifications
resource "aws_sns_topic" "remediation" {
  for_each = var.remediation_config
  name     = each.value.sns_topic
}

output "lambda_functions" {
  description = "Map of created Lambda functions for remediation"
  value       = { for k, v in aws_lambda_function.remediation : k => v.arn }
}

output "sns_topics" {
  description = "Map of created SNS topics for remediation notifications"
  value       = { for k, v in aws_sns_topic.remediation : k => v.arn }
}
