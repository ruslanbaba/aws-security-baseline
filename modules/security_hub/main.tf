# Security Hub Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "aws_regions" {
  description = "List of AWS regions where Security Hub should be enabled"
  type        = list(string)
}

variable "security_standards" {
  description = "Security standards to enable"
  type = list(object({
    name    = string
    enabled = bool
  }))
  default = [
    {
      name    = "AWS Foundational Security Best Practices v1.0.0"
      enabled = true
    },
    {
      name    = "CIS AWS Foundations Benchmark v1.4.0"
      enabled = true
    },
    {
      name    = "PCI DSS v3.2.1"
      enabled = true
    }
  ]
}

# Enable Security Hub
resource "aws_securityhub_account" "main" {
  for_each = toset(var.aws_regions)
  provider = aws.regional[each.value]
}

# Enable Security Hub Organization Admin Account
resource "aws_securityhub_organization_admin_account" "admin" {
  for_each = toset(var.aws_regions)
  provider = aws.regional[each.value]

  admin_account_id = data.aws_caller_identity.current.account_id
}

# Enable Security Standards
resource "aws_securityhub_standards_subscription" "standards" {
  for_each = {
    for pair in setproduct(var.aws_regions, var.security_standards) :
    "${pair[0]}-${pair[1].name}" => {
      region   = pair[0]
      standard = pair[1]
    }
    if pair[1].enabled
  }

  provider      = aws.regional[each.value.region]
  standards_arn = "arn:aws:securityhub:${each.value.region}::standards/${each.value.standard.name}"
  depends_on    = [aws_securityhub_account.main]
}

# Configure automatic aggregation
resource "aws_securityhub_finding_aggregator" "aggregator" {
  linking_mode = "ALL_REGIONS"
  depends_on   = [aws_securityhub_account.main]
}

data "aws_caller_identity" "current" {}

output "security_hub_enabled_regions" {
  description = "Regions where Security Hub is enabled"
  value       = aws_securityhub_account.main[*]
}
