#!/usr/bin/env python3

import boto3
import csv
from datetime import datetime
import json

def generate_compliance_report():
    # Initialize clients
    config = boto3.client('config')
    securityhub = boto3.client('securityhub')
    guardduty = boto3.client('guardduty')
    macie = boto3.client('macie2')
    
    report_data = []
    
    # Get Config compliance
    config_rules = config.describe_config_rules()
    for rule in config_rules['ConfigRules']:
        compliance = config.get_compliance_details_by_config_rule(
            ConfigRuleName=rule['ConfigRuleName']
        )
        for result in compliance['EvaluationResults']:
            report_data.append({
                'Service': 'AWS Config',
                'Rule': rule['ConfigRuleName'],
                'ResourceType': result['EvaluationResultIdentifier']['EvaluationResultQualifier']['ResourceType'],
                'ResourceId': result['EvaluationResultIdentifier']['EvaluationResultQualifier']['ResourceId'],
                'Status': result['ComplianceType'],
                'LastChecked': result['ResultRecordedTime'].strftime('%Y-%m-%d %H:%M:%S')
            })
    
    # Get SecurityHub findings
    findings = securityhub.get_findings()
    for finding in findings['Findings']:
        report_data.append({
            'Service': 'Security Hub',
            'Rule': finding['Title'],
            'ResourceType': finding['Resources'][0]['Type'],
            'ResourceId': finding['Resources'][0]['Id'],
            'Status': finding['Workflow']['Status'],
            'LastChecked': finding['UpdatedAt']
        })
    
    # Get GuardDuty findings
    detectors = guardduty.list_detectors()
    for detector_id in detectors['DetectorIds']:
        findings = guardduty.list_findings(DetectorId=detector_id)
        for finding_id in findings['FindingIds']:
            finding_detail = guardduty.get_findings(
                DetectorId=detector_id,
                FindingIds=[finding_id]
            )['Findings'][0]
            report_data.append({
                'Service': 'GuardDuty',
                'Rule': finding_detail['Type'],
                'ResourceType': finding_detail['Resource']['ResourceType'],
                'ResourceId': finding_detail['Resource'].get('ResourceId', 'N/A'),
                'Status': finding_detail['Service']['Action']['ActionType'],
                'LastChecked': finding_detail['UpdatedAt']
            })
    
    # Generate CSV report
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'compliance_report_{timestamp}.csv'
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['Service', 'Rule', 'ResourceType', 'ResourceId', 'Status', 'LastChecked']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for row in report_data:
            writer.writerow(row)
    
    return filename, len(report_data)

if __name__ == "__main__":
    print("Generating compliance report...")
    filename, count = generate_compliance_report()
    print(f"Report generated: {filename}")
    print(f"Total findings: {count}")
    
    # Send notification to Slack
    import requests
    import os
    
    WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
    if WEBHOOK_URL:
        message = f"New compliance report generated: {filename}\nTotal findings: {count}"
        response = requests.post(
            WEBHOOK_URL,
            json={"text": message},
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            print("Slack notification sent successfully")
        else:
            print(f"Failed to send Slack notification: {response.text}")
