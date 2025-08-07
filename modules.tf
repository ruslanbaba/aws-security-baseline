# Additional modules for security baseline

# IAM Password Policy
module "iam_password_policy" {
  source = "./modules/iam_password_policy"
  
  organization_id = module.organization.org_id
  password_policy = var.password_policy
}

# CloudTrail
module "cloudtrail" {
  source = "./modules/cloudtrail"
  
  organization_id    = module.organization.org_id
  aws_regions       = var.enabled_regions
  cloudtrail_config = var.cloudtrail_config
}

# WAF
module "waf" {
  source = "./modules/waf"
  
  organization_id = module.organization.org_id
  waf_rules      = var.waf_rules
}
