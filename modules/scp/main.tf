# Service Control Policies Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "scps_config" {
  description = "Service Control Policies configuration"
  type = map(object({
    description = string
    policy      = string
    targets     = list(string)
  }))
}

# Create Service Control Policies
resource "aws_organizations_policy" "scp" {
  for_each = var.scps_config

  name        = each.key
  description = each.value.description
  content     = each.value.policy
  type        = "SERVICE_CONTROL_POLICY"
}

# Attach policies to targets
resource "aws_organizations_policy_attachment" "attach_scp" {
  for_each = {
    for pair in flatten([
      for policy_name, config in var.scps_config : [
        for target in config.targets : {
          policy_name = policy_name
          target     = target
        }
      ]
    ]) : "${pair.policy_name}-${pair.target}" => pair
  }

  policy_id = aws_organizations_policy.scp[each.value.policy_name].id
  target_id = each.value.target
}

output "policy_ids" {
  description = "Map of created SCP IDs"
  value       = { for k, v in aws_organizations_policy.scp : k => v.id }
}
