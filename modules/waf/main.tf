# WAF Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "waf_rules" {
  description = "WAF rules configuration"
  type = list(object({
    name        = string
    description = string
    priority    = number
    action      = string
    rules      = list(map(string))
  }))
  default = [
    {
      name        = "block-sql-injection"
      description = "Block SQL injection attempts"
      priority    = 1
      action      = "block"
      rules      = [
        {
          type    = "REGEX"
          pattern = "(?i)(select|insert|update|delete|drop|union|exec|declare)"
        }
      ]
    },
    {
      name        = "rate-limit"
      description = "Rate limit requests"
      priority    = 2
      action      = "block"
      rules      = [
        {
          type    = "RATE_BASED"
          limit   = "2000"
          period  = "FIVE_MINUTES"
        }
      ]
    }
  ]
}

# Create WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "organization-waf"
  description = "Organization-wide WAF rules"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name        = rule.value.name
      priority    = rule.value.priority

      override_action {
        none {}
      }

      statement {
        dynamic "regex_pattern_set_reference_statement" {
          for_each = [for r in rule.value.rules : r if r.type == "REGEX"]
          content {
            arn = aws_wafv2_regex_pattern_set.patterns[rule.value.name].arn
          }
        }

        dynamic "rate_based_statement" {
          for_each = [for r in rule.value.rules : r if r.type == "RATE_BASED"]
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = "IP"
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.name
        sampled_requests_enabled  = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "organization-waf"
    sampled_requests_enabled  = true
  }
}

# Create Regex Pattern Sets
resource "aws_wafv2_regex_pattern_set" "patterns" {
  for_each = { for rule in var.waf_rules : rule.name => rule
               if contains([for r in rule.rules : r.type], "REGEX") }

  name        = each.value.name
  description = each.value.description
  scope       = "REGIONAL"

  dynamic "regular_expression" {
    for_each = [for r in each.value.rules : r if r.type == "REGEX"]
    content {
      regex_string = regular_expression.value.pattern
    }
  }
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}
