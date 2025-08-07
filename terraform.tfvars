# Example terraform.tfvars file

aws_region         = "us-east-1"
assume_role_arn    = "arn:aws:iam::ACCOUNT_ID:role/OrganizationAccountAccessRole"
organization_name  = "example-org"
organization_email = "admin@example.com"

enabled_regions = [
  "us-east-1",
  "us-east-2",
  "us-west-1",
  "us-west-2",
  "eu-west-1"
]

service_control_policies = {
  prevent_root_access = {
    description = "Prevents usage of root account"
    policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootAccess",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": ["arn:aws:iam::*:root"]
        }
      }
    }
  ]
}
EOF
    targets     = ["ou-example-1", "ou-example-2"]
  },
  enforce_encryption = {
    description = "Enforces encryption for services"
    policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireEncryption",
      "Effect": "Deny",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": ["AES256", "aws:kms"]
        }
      }
    }
  ]
}
EOF
    targets     = ["ou-example-1", "ou-example-2"]
  }
}

config_rules = [
  {
    name        = "encrypted-volumes"
    description = "Checks if EBS volumes are encrypted"
    input_parameters = {
      "encrypted": "true"
    }
    scope = {
      resource_types = ["AWS::EC2::Volume"]
    }
  },
  {
    name        = "s3-bucket-public-read-prohibited"
    description = "Checks if S3 buckets allow public read access"
    input_parameters = {}
    scope = {
      resource_types = ["AWS::S3::Bucket"]
    }
  }
]

kms_key_config = {
  deletion_window_in_days = 7
  enable_key_rotation    = true
  alias_prefix          = "security-baseline"
}

flow_logs_retention = 90
