# VPC Flow Logs Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "aws_regions" {
  description = "List of AWS regions where VPC Flow Logs should be enabled"
  type        = list(string)
}

variable "log_retention" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 90
}

# Create CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_log" {
  for_each = toset(var.aws_regions)

  name              = "/aws/vpc/flow-logs/${each.key}"
  retention_in_days = var.log_retention
}

# Create IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "VPCFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "VPCFlowLogsPolicy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Create organization-wide policy to enforce VPC Flow Logs
resource "aws_organizations_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "RequireVPCFlowLogs"
        Effect   = "Deny"
        Action   = "ec2:CreateVpc"
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/EnableFlowLogs": "true"
          }
        }
      }
    ]
  })
}

output "log_group_arns" {
  description = "ARNs of created CloudWatch Log Groups by region"
  value       = { for k, v in aws_cloudwatch_log_group.flow_log : k => v.arn }
}

output "flow_logs_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.flow_log_role.arn
}
