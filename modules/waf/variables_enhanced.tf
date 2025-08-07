# Enhanced WAF rules with additional security patterns

variable "additional_waf_rules" {
  description = "Additional WAF rules with enhanced security patterns"
  type = list(object({
    name        = string
    description = string
    priority    = number
    action      = string
    rules      = list(map(string))
  }))
  default = [
    {
      name        = "block-xss-attacks"
      description = "Block XSS attempts"
      priority    = 3
      action      = "block"
      rules      = [
        {
          type    = "REGEX"
          pattern = "(?i)(<script|javascript:|vbscript:|expression|onload=)"
        }
      ]
    },
    {
      name        = "block-path-traversal"
      description = "Block path traversal attempts"
      priority    = 4
      action      = "block"
      rules      = [
        {
          type    = "REGEX"
          pattern = "(?i)(\.\./|\.\\.\\|\/etc\/passwd|\/etc\/shadow)"
        }
      ]
    },
    {
      name        = "block-command-injection"
      description = "Block command injection attempts"
      priority    = 5
      action      = "block"
      rules      = [
        {
          type    = "REGEX"
          pattern = "(?i)(;|&&|\|\||`|\\$\\(|system\\()"
        }
      ]
    },
    {
      name        = "geo-restriction"
      description = "Restrict access by country"
      priority    = 6
      action      = "block"
      rules      = [
        {
          type = "GEO_MATCH"
          countries = ["CN", "RU", "KP"]
        }
      ]
    }
  ]
}
