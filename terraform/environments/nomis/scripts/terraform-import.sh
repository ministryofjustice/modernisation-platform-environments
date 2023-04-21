#!/bin/bash
echo terraform import 'module.baseline.aws_iam_service_linked_role.this["autoscaling.amazonaws.com"]' "arn:aws:iam::${ACCOUNT_NUMBER}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
