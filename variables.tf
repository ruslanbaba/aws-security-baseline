# Variables for AWS Security Baseline

variable "aws_region" {
  description = "Primary AWS region for the security baseline"
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "ARN of the role to assume for managing the organization"
  type        = string
}

variable "organization_name" {
  description = "Name of the AWS Organization"
  type        = string
}

variable "organization_email" {
  description = "Email address for the AWS Organization"
  type        = string
}

variable "enabled_regions" {
  description = "List of AWS regions where security controls should be applied"
  type        = list(string)
  default = [
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
    "eu-west-1"
  ]
}

variable "service_control_policies" {
  description = "Map of Service Control Policies to apply"
  type = map(object({
    description = string
    policy      = string
    targets     = list(string)
  }))
}

variable "config_rules" {
  description = "List of AWS Config rules to enable"
  type = list(object({
    name        = string
    description = string
    input_parameters = map(string)
    scope       = map(string)
  }))
}

variable "kms_key_config" {
  description = "Configuration for KMS keys used in S3 encryption"
  type = object({
    deletion_window_in_days = number
    enable_key_rotation    = bool
    alias_prefix          = string
  })
  default = {
    deletion_window_in_days = 7
    enable_key_rotation    = true
    alias_prefix          = "security-baseline"
  }
}

variable "flow_logs_retention" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 90
}
