# Additional variables for new security modules

variable "password_policy" {
  description = "IAM password policy configuration"
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
