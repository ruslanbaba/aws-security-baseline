import requests
import json

def send_slack_notification(webhook_url, message):
    payload = {"text": message}
    response = requests.post(webhook_url, json=payload)
    if response.status_code == 200:
        print("Notification sent to Slack")
    else:
        print(f"Failed to send notification: {response.text}")

if __name__ == "__main__":
    WEBHOOK_URL = "YOUR_SLACK_WEBHOOK_URL"
    MESSAGE = "AWS Security Baseline: Non-compliance detected!"
    send_slack_notification(WEBHOOK_URL, MESSAGE)
