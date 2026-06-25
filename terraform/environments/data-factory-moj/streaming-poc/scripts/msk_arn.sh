#!/bin/sh

CLUSTER_NAME=$(jq -r '.cluster_name')
ARN=$(aws kafka list-clusters-v2 --cluster-name-filter "$CLUSTER_NAME" --query 'ClusterInfoList[0].ClusterArn' --output text --region eu-west-2)
jq -n --arg arn "$ARN" '{"arn": $arn}'
