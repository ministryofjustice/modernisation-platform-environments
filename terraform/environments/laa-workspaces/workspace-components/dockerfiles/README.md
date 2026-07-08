# Docker Images Build & Push Guide

This directory contains Docker configurations for the LinOTP 3.x + FreeRADIUS ECS deployment.

## Prerequisites

- Docker installed and running
- AWS CLI configured with appropriate profile
- ECR repositories created (via Terraform)
- Permissions to push to ECR in the target account

## Images

### 1. LinOTP 3.x (`linotp3/`)

Official LinOTP 3.4.4 base image with:
- pymysql driver for MySQL connectivity
- Custom entrypoint for secrets injection and database initialization
- Bootstrap process for audit keys and admin user creation

### 2. FreeRADIUS (`freeradius/`)

FreeRADIUS 3.x with LinOTP Perl module integration:
- Perl modules for LinOTP authentication
- LinOTP auth module from GitHub
- Custom configuration for RADIUS + LinOTP validation

## Build & Push Process

### Step 1: Authenticate to ECR

```bash
# Set variables
export AWS_REGION=eu-west-2
export AWS_PROFILE=mp-workspaces-dev
export ACCOUNT_ID=945484575162

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} \
  | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Step 2: Build LinOTP Image

```bash
cd linotp3

# Build for linux/amd64 (required for Fargate)
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .

# Tag for ECR
docker tag laa-workspaces/linotp3:latest \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/laa-workspaces/linotp3:latest

# Push to ECR
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/laa-workspaces/linotp3:latest
```

### Step 3: Build FreeRADIUS Image

```bash
cd ../freeradius

# Build for linux/amd64
docker build --platform linux/amd64 -t laa-workspaces/freeradius-linotp .

# Tag for ECR
docker tag laa-workspaces/freeradius-linotp:latest \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/laa-workspaces/freeradius-linotp:latest

# Push to ECR
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/laa-workspaces/freeradius-linotp:latest
```

### Step 4: Deploy to ECS

After pushing new images, force ECS service redeployment to pick them up:

```bash
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE} \
  --no-cli-pager
```

## Quick Reference - Full Build Script

```bash
#!/bin/bash
set -e

# Configuration
export AWS_REGION=eu-west-2
export AWS_PROFILE=mp-workspaces-dev
export ACCOUNT_ID=945484575162
export ECR_BASE=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Authenticate
echo "Authenticating to ECR..."
aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} \
  | docker login --username AWS --password-stdin ${ECR_BASE}

# Build and push LinOTP
echo "Building LinOTP image..."
cd linotp3
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .
docker tag laa-workspaces/linotp3:latest ${ECR_BASE}/laa-workspaces/linotp3:latest
docker push ${ECR_BASE}/laa-workspaces/linotp3:latest

# Build and push FreeRADIUS
echo "Building FreeRADIUS image..."
cd ../freeradius
docker build --platform linux/amd64 -t laa-workspaces/freeradius-linotp .
docker tag laa-workspaces/freeradius-linotp:latest ${ECR_BASE}/laa-workspaces/freeradius-linotp:latest
docker push ${ECR_BASE}/laa-workspaces/freeradius-linotp:latest

# Force ECS redeployment
echo "Triggering ECS redeployment..."
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region ${AWS_REGION} \
  --profile ${AWS_PROFILE} \
  --no-cli-pager

echo "Done! Check ECS service status for deployment progress."
```

## Troubleshooting

### ECR Authentication Issues

If you see "no basic auth credentials" error:
```bash
# Re-authenticate to ECR
aws ecr get-login-password --region eu-west-2 --profile mp-workspaces-dev \
  | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com
```

### Platform Architecture Mismatch

If building on Apple Silicon (M1/M2/M3), always use `--platform linux/amd64`:
```bash
docker build --platform linux/amd64 -t image-name .
```

Without this flag, images built on ARM64 hosts won't run on Fargate (which uses x86_64).

### Image Not Updating in ECS

After pushing new images, ECS won't automatically pull them. Force a new deployment:
```bash
aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
```

### Checking Image Digests

Verify pushed image:
```bash
aws ecr describe-images \
  --repository-name laa-workspaces/linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

## ECR Repository URLs

- LinOTP: `945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3`
- FreeRADIUS: `945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/freeradius-linotp`

## Notes

- Images are tagged as `latest` - no versioning currently implemented
- ECR lifecycle policy keeps last 5 images and deletes older ones
- Both images must be pushed together before ECS redeployment
- Terraform manages ECR repositories, don't create them manually
