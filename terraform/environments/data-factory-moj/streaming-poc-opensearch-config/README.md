# Deployning opensearch resources via terraform

Terraform project to configure the AWS OpenSearch domain created by the [opensearch](../streaming-poc-opensearch/) project. This includes role mappings, index creation and importing saved objects.

## Prerequisites

- AWS CLI v2
- Terraform ~> 1.9
- Port forwarding to ECS - streaming-pov-ecs-sdg container 
- Access to MOJ aws environments

## Important

The OpenSearch domain is only accessible from within the VPC, so this project must be run locally with an active portforwad to container running in ECS (deployed in same private subnet). It cannot be run from CI/CD pipelines but code is still maintained in github as subfolder of streaming-poc-opensearch-config i.e os-resources. Terraform state of the deployment is maintained in project specific S3 and not platform provided s3 backend. Project specific S3 is created as part of app_s3.tf

## Setup

### 1. Authenticate and connect

```bash
aws sso login --sso-session <session>

```
# port forward script 

```bash 
#!/bin/sh

AWS_REGION="eu-west-2"
CLUSTER_NAME="streaming-pov-ecs-cluster"
SDG_SERVICE_NAME="streaming-pov-ecs-sdg"
SDG_CONTAINER_NAME="streaming-pov-ecs-sdg"

SDG_TASK_ARN=$(
  aws ecs list-tasks \
    --region "$AWS_REGION" \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SDG_SERVICE_NAME" \
    --desired-status RUNNING \
    --query 'taskArns[0]' \
    --output text
)

SDG_TASK_ID="${SDG_TASK_ARN##*/}"

SDG_RUNTIME_ID=$(
  aws ecs describe-tasks \
    --region "$AWS_REGION" \
    --cluster "$CLUSTER_NAME" \
    --tasks "$SDG_TASK_ARN" \
    --query "tasks[0].containers[?name=='$SDG_CONTAINER_NAME'].runtimeId | [0]" \
    --output text
)

SSM_TARGET_SDG="ecs:${CLUSTER_NAME}_${SDG_TASK_ID}_${SDG_RUNTIME_ID}"

OS_DOMAIN_NAME=$(aws opensearch describe-domain --domain-name streaming-pov-opensearch --query "DomainStatus.Endpoints.vpc" --region eu-west-2 --output text)

aws ssm start-session \
  --region "$AWS_REGION" \
  --target "$SSM_TARGET_SDG" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$OS_DOMAIN_NAME\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"9200\"]}"

```

### 2. Deploy

```bash
cd os-resources
un-comment the backend block in 2_terraform.tf  # this is work around until we get stretegic solution on platform 
terraform init
terraform plan
terraform apply
comment the backend block in 2_terraform.tf
push changes backup to repo.
```