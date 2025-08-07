# Resource Access Manager (RAM) Module

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "ram_shares" {
  description = "Resource shares configuration"
  type = list(object({
    name           = string
    resource_type  = string
    resource_arns  = list(string)
    principals     = list(string)
    tags          = map(string)
  }))
  default = []
}

# Enable RAM for Organization
resource "aws_ram_resource_share" "org_share" {
  for_each = { for share in var.ram_shares : share.name => share }

  name                      = each.value.name
  allow_external_principals = false

  tags = merge(
    {
      "Name" = each.value.name
    },
    each.value.tags
  )
}

# Associate resources with shares
resource "aws_ram_resource_association" "share_resources" {
  for_each = {
    for pair in flatten([
      for share in var.ram_shares : [
        for arn in share.resource_arns : {
          share_name = share.name
          arn       = arn
        }
      ]
    ]) : "${pair.share_name}-${pair.arn}" => pair
  }

  resource_arn       = each.value.arn
  resource_share_arn = aws_ram_resource_share.org_share[each.value.share_name].arn
}

# Share with principals
resource "aws_ram_principal_association" "share_principals" {
  for_each = {
    for pair in flatten([
      for share in var.ram_shares : [
        for principal in share.principals : {
          share_name = share.name
          principal  = principal
        }
      ]
    ]) : "${pair.share_name}-${pair.principal}" => pair
  }

  principal          = each.value.principal
  resource_share_arn = aws_ram_resource_share.org_share[each.value.share_name].arn
}

output "resource_shares" {
  description = "Created RAM resource shares"
  value       = aws_ram_resource_share.org_share
}
