#!/usr/bin/env python3

import boto3
import json
import os
from datetime import datetime, timedelta
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from jinja2 import Template

class ComplianceReportGenerator:
    def __init__(self):
        self.findings = {
            'SecurityHub': [],
            'GuardDuty': [],
            'Config': [],
            'Macie': [],
            'IAM': []
        }
        self.report_data = {}
        
    def collect_data(self):
        """Collect security findings and compliance data."""
        self._get_securityhub_findings()
        self._get_guardduty_findings()
        self._get_config_findings()
        self._get_macie_findings()
        self._get_iam_compliance()
        
    def _get_securityhub_findings(self):
        client = boto3.client('securityhub')
        response = client.get_findings(
            Filters={
                'UpdatedAt': [{
                    'Start': (datetime.now() - timedelta(days=30)).isoformat(),
                    'End': datetime.now().isoformat()
                }]
            }
        )
        self.findings['SecurityHub'] = response['Findings']
        
    def _get_guardduty_findings(self):
        client = boto3.client('guardduty')
        detectors = client.list_detectors()
        for detector_id in detectors['DetectorIds']:
            findings = client.list_findings(DetectorId=detector_id)
            self.findings['GuardDuty'].extend(findings['FindingIds'])
            
    def _get_config_findings(self):
        client = boto3.client('config')
        rules = client.describe_config_rules()
        for rule in rules['ConfigRules']:
            results = client.get_compliance_details_by_config_rule(
                ConfigRuleName=rule['ConfigRuleName']
            )
            self.findings['Config'].extend(results['EvaluationResults'])
            
    def _get_macie_findings(self):
        client = boto3.client('macie2')
        findings = client.get_findings()
        self.findings['Macie'] = findings['findings']
        
    def _get_iam_compliance(self):
        client = boto3.client('iam')
        credential_report = client.get_credential_report()
        self.findings['IAM'] = credential_report['Content']
        
    def generate_metrics(self):
        """Generate compliance metrics and visualizations."""
        # Security Hub metrics
        security_hub_df = pd.DataFrame(self.findings['SecurityHub'])
        severity_counts = security_hub_df['Severity']['Label'].value_counts()
        
        # Create severity distribution pie chart
        fig_severity = px.pie(
            values=severity_counts.values,
            names=severity_counts.index,
            title='Finding Severity Distribution'
        )
        
        # Create findings timeline
        findings_timeline = px.line(
            security_hub_df,
            x='UpdatedAt',
            y='Severity.Normalized',
            title='Findings Severity Timeline'
        )
        
        # Save visualizations
        fig_severity.write_html('report_assets/severity_distribution.html')
        findings_timeline.write_html('report_assets/findings_timeline.html')
        
        return {
            'total_findings': len(self.findings['SecurityHub']),
            'critical_findings': len(security_hub_df[security_hub_df['Severity']['Label'] == 'CRITICAL']),
            'high_findings': len(security_hub_df[security_hub_df['Severity']['Label'] == 'HIGH']),
            'compliant_resources': len([f for f in self.findings['Config'] if f['ComplianceType'] == 'COMPLIANT']),
            'non_compliant_resources': len([f for f in self.findings['Config'] if f['ComplianceType'] == 'NON_COMPLIANT'])
        }
        
    def generate_html_report(self):
        """Generate HTML compliance report."""
        metrics = self.generate_metrics()
        
        template_str = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>AWS Security Compliance Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .metric-box { border: 1px solid #ddd; padding: 20px; margin: 10px; display: inline-block; }
                .critical { color: red; }
                .high { color: orange; }
                .chart { margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>AWS Security Compliance Report</h1>
            <div class="metrics">
                <div class="metric-box">
                    <h3>Total Findings</h3>
                    <p>{{ metrics.total_findings }}</p>
                </div>
                <div class="metric-box">
                    <h3>Critical Findings</h3>
                    <p class="critical">{{ metrics.critical_findings }}</p>
                </div>
                <div class="metric-box">
                    <h3>High Findings</h3>
                    <p class="high">{{ metrics.high_findings }}</p>
                </div>
                <div class="metric-box">
                    <h3>Resource Compliance</h3>
                    <p>Compliant: {{ metrics.compliant_resources }}<br>
                       Non-Compliant: {{ metrics.non_compliant_resources }}</p>
                </div>
            </div>
            
            <div class="chart">
                <iframe src="report_assets/severity_distribution.html" width="100%" height="400px"></iframe>
            </div>
            
            <div class="chart">
                <iframe src="report_assets/findings_timeline.html" width="100%" height="400px"></iframe>
            </div>
        </body>
        </html>
        """
        
        template = Template(template_str)
        report_html = template.render(metrics=metrics)
        
        # Save report
        os.makedirs('report_assets', exist_ok=True)
        with open('compliance_report.html', 'w') as f:
            f.write(report_html)
            
        return 'compliance_report.html'

if __name__ == "__main__":
    generator = ComplianceReportGenerator()
    generator.collect_data()
    report_file = generator.generate_html_report()
    print(f"Report generated: {report_file}")
    
    # Send notification to Slack if webhook URL is configured
    if 'SLACK_WEBHOOK_URL' in os.environ:
        import requests
        message = f"New compliance report generated: {report_file}"
        response = requests.post(
            os.environ['SLACK_WEBHOOK_URL'],
            json={"text": message}
        )
        if response.status_code == 200:
            print("Slack notification sent successfully")
