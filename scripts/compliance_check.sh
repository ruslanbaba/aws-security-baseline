#!/bin/bash

aws configservice describe-config-rules --region us-east-1 | grep NON_COMPLIANT
if [ $? -eq 0 ]; then
    python3 scripts/slack_notify.py
fi
