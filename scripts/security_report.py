#!/usr/bin/env python3

import boto3
import json
import os
from datetime import datetime, timedelta

def get_security_findings():
    findings = {
        'SecurityHub': [],
        'GuardDuty': [],
        'Macie': [],
        'Config': []
    }
    
    # SecurityHub findings
    securityhub = boto3.client('securityhub')
    response = securityhub.get_findings(
        Filters={
            'CreatedAt': [{
                'Start': (datetime.now() - timedelta(days=1)).isoformat(),
                'End': datetime.now().isoformat()
            }],
            'SeverityLabel': [{
                'Value': 'HIGH',
                'Comparison': 'EQUALS'
            }]
        }
    )
    findings['SecurityHub'] = response['Findings']
    
    # GuardDuty findings
    guardduty = boto3.client('guardduty')
    detectors = guardduty.list_detectors()
    for detector_id in detectors['DetectorIds']:
        response = guardduty.list_findings(
            DetectorId=detector_id,
            FindingCriteria={
                'Criterion': {
                    'severity': {
                        'Eq': ['8', '9', '10']
                    }
                }
            }
        )
        findings['GuardDuty'].extend(response['FindingIds'])
    
    # Macie findings
    macie = boto3.client('macie2')
    response = macie.get_findings(
        findingCriteria={
            'severity': {
                'eq': ['HIGH']
            }
        }
    )
    findings['Macie'] = response['findings']
    
    # Config compliance
    config = boto3.client('config')
    response = config.get_compliance_details_by_config_rule(
        ComplianceTypes=['NON_COMPLIANT']
    )
    findings['Config'] = response['EvaluationResults']
    
    return findings

def format_slack_message(findings):
    message = "Security Findings Report\n"
    message += "=" * 30 + "\n\n"
    
    for service, service_findings in findings.items():
        message += f"*{service}*\n"
        if service_findings:
            message += f"Found {len(service_findings)} high-severity issues\n"
            for finding in service_findings[:5]:  # Limit to 5 findings per service
                if service == 'SecurityHub':
                    message += f"- {finding.get('Title', 'No title')}\n"
                elif service == 'GuardDuty':
                    message += f"- Finding ID: {finding}\n"
                elif service == 'Macie':
                    message += f"- {finding.get('description', 'No description')}\n"
                elif service == 'Config':
                    message += f"- {finding.get('EvaluationResultIdentifier', {}).get('EvaluationResultQualifier', {}).get('ConfigRuleName', 'No rule name')}\n"
        else:
            message += "No high-severity findings\n"
        message += "\n"
    
    return message

if __name__ == "__main__":
    WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
    if not WEBHOOK_URL:
        print("Error: SLACK_WEBHOOK_URL environment variable not set")
        exit(1)
        
    findings = get_security_findings()
    message = format_slack_message(findings)
    
    import requests
    response = requests.post(
        WEBHOOK_URL,
        json={"text": message},
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print("Security report sent to Slack successfully")
    else:
        print(f"Failed to send report: {response.text}")
