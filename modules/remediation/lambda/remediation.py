import boto3
import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Handle security finding events and perform automated remediation."""
    
    action_type = os.environ['ACTION_TYPE']
    parameters = json.loads(os.environ['PARAMETERS'])
    sns_topic = os.environ['SNS_TOPIC']
    
    finding = event['detail']['findings'][0]
    resource_id = finding['Resources'][0]['Id']
    
    try:
        if action_type == "S3_ENCRYPT":
            remediate_s3_encryption(resource_id)
        elif action_type == "SG_RESTRICT":
            remediate_security_group(resource_id, parameters)
        elif action_type == "IAM_ROTATE":
            remediate_iam_keys(resource_id)
        elif action_type == "CONFIG_ENABLE":
            remediate_config_recorder(resource_id)
        
        # Send notification
        send_notification(sns_topic, "Remediation successful", finding)
        return {
            "statusCode": 200,
            "body": "Remediation completed successfully"
        }
    except Exception as e:
        logger.error(f"Remediation failed: {str(e)}")
        send_notification(sns_topic, f"Remediation failed: {str(e)}", finding)
        raise

def remediate_s3_encryption(bucket_name):
    """Enable default encryption for S3 bucket."""
    s3 = boto3.client('s3')
    s3.put_bucket_encryption(
        Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            'Rules': [
                {
                    'ApplyServerSideEncryptionByDefault': {
                        'SSEAlgorithm': 'AES256'
                    }
                }
            ]
        }
    )

def remediate_security_group(group_id, parameters):
    """Restrict security group rules."""
    ec2 = boto3.client('ec2')
    ec2.revoke_security_group_ingress(
        GroupId=group_id,
        IpPermissions=[
            {
                'IpProtocol': '-1',
                'FromPort': -1,
                'ToPort': -1,
                'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
            }
        ]
    )

def remediate_iam_keys(user_name):
    """Rotate IAM access keys."""
    iam = boto3.client('iam')
    keys = iam.list_access_keys(UserName=user_name)['AccessKeyMetadata']
    
    for key in keys:
        if key['Status'] == 'Active':
            # Create new key
            new_key = iam.create_access_key(UserName=user_name)
            # Deactivate old key
            iam.update_access_key(
                UserName=user_name,
                AccessKeyId=key['AccessKeyId'],
                Status='Inactive'
            )

def remediate_config_recorder(region):
    """Enable AWS Config recorder."""
    config = boto3.client('config')
    config.put_configuration_recorder(
        ConfigurationRecorder={
            'name': 'config-recorder',
            'roleARN': os.environ['CONFIG_ROLE_ARN'],
            'recordingGroup': {
                'allSupported': True,
                'includeGlobalResources': True
            }
        }
    )
    config.start_configuration_recorder(
        ConfigurationRecorderName='config-recorder'
    )

def send_notification(topic_arn, message, finding):
    """Send SNS notification about remediation action."""
    sns = boto3.client('sns')
    sns.publish(
        TopicArn=topic_arn,
        Message=json.dumps({
            'message': message,
            'finding': finding,
            'timestamp': finding['UpdatedAt']
        }),
        Subject='Security Finding Remediation'
    )
