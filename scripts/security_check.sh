#!/bin/bash

# Get AWS regions
regions=$(aws ec2 describe-regions --output text --query 'Regions[*].[RegionName]')

echo "Security Baseline Compliance Check"
echo "================================"

for region in $regions; do
    echo -e "\nChecking region: $region"
    echo "------------------------"

    # Check GuardDuty status
    echo "GuardDuty Status:"
    aws guardduty get-detector --region $region 2>/dev/null || echo "Not enabled"

    # Check SecurityHub status
    echo -e "\nSecurityHub Status:"
    aws securityhub get-enabled-standards --region $region 2>/dev/null || echo "Not enabled"

    # Check Macie status
    echo -e "\nMacie Status:"
    aws macie2 get-macie-session --region $region 2>/dev/null || echo "Not enabled"

    # Check Config status
    echo -e "\nConfig Recorder Status:"
    aws configservice describe-configuration-recorder-status --region $region 2>/dev/null || echo "Not enabled"

    # Check CloudTrail status
    echo -e "\nCloudTrail Status:"
    aws cloudtrail get-trail-status --name aws-cloudtrail-logs --region $region 2>/dev/null || echo "Not enabled"

    # Check WAF rules
    echo -e "\nWAF Rules Status:"
    aws wafv2 list-web-acls --scope REGIONAL --region $region 2>/dev/null || echo "No WAF rules found"
done

# Check organization-wide settings
echo -e "\nOrganization-wide Settings"
echo "==========================="

# Check SCP policies
echo "Service Control Policies:"
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Check IAM password policy
echo -e "\nIAM Password Policy:"
aws iam get-account-password-policy 2>/dev/null || echo "No custom password policy set"

# Check for non-compliant resources
echo -e "\nNon-compliant Resources:"
aws configservice get-aggregate-compliance-details-by-config-rule 2>/dev/null || echo "No aggregated config data available"

# Send results to Slack
if [ -f "scripts/slack_notify.py" ]; then
    echo -e "\nSending results to Slack..."
    python3 scripts/slack_notify.py
fi
