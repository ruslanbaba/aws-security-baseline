# Service-Specific Security Controls Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

# RDS Security Controls
resource "aws_organizations_policy" "rds_security" {
  name = "rds-security-controls"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceRDSEncryption"
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "rds:StorageEncrypted": "false"
          }
        }
      },
      {
        Sid    = "EnforceRDSBackup"
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          NumericLessThan = {
            "rds:BackupRetentionPeriod": 7
          }
        }
      }
    ]
  })
}

# ECS Security Controls
resource "aws_organizations_policy" "ecs_security" {
  name = "ecs-security-controls"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceECSEncryption"
        Effect = "Deny"
        Action = [
          "ecs:CreateCluster",
          "ecs:RunTask",
          "ecs:StartTask"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "ecs:EnableContainerInsights": "true"
          }
        }
      }
    ]
  })
}

# Lambda Security Controls
resource "aws_organizations_policy" "lambda_security" {
  name = "lambda-security-controls"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceLambdaVPC"
        Effect = "Deny"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "lambda:VpcIds": "true"
          }
        }
      }
    ]
  })
}

# DynamoDB Security Controls
resource "aws_organizations_policy" "dynamodb_security" {
  name = "dynamodb-security-controls"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceDynamoDBEncryption"
        Effect = "Deny"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTable"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "dynamodb:Encrypted": "true"
          }
        }
      }
    ]
  })
}

# EKS Security Controls
resource "aws_organizations_policy" "eks_security" {
  name = "eks-security-controls"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceEKSEncryption"
        Effect = "Deny"
        Action = [
          "eks:CreateCluster"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "eks:Encrypted": "true"
          }
        }
      }
    ]
  })
}

output "policy_arns" {
  description = "ARNs of created service-specific security policies"
  value = {
    rds      = aws_organizations_policy.rds_security.arn
    ecs      = aws_organizations_policy.ecs_security.arn
    lambda   = aws_organizations_policy.lambda_security.arn
    dynamodb = aws_organizations_policy.dynamodb_security.arn
    eks      = aws_organizations_policy.eks_security.arn
  }
}
