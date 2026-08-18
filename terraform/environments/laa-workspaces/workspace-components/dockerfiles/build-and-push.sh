#!/bin/bash
set -e

# Docker Image Build & Push Script for LAA MP WorkSpaces MFA
# Builds and pushes LinOTP and FreeRADIUS images to ECR

# Configuration
export AWS_REGION=${AWS_REGION:-eu-west-2}
export AWS_PROFILE=${AWS_PROFILE:-mp-workspaces-dev}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== LAA WorkSpaces MFA - Build & Push Docker Images ===${NC}\n"

# Get AWS account ID dynamically
echo -e "${YELLOW}Getting AWS account ID...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}Failed to get AWS account ID. Check your AWS profile.${NC}"
    exit 1
fi
echo -e "Account ID: ${ACCOUNT_ID}\n"

export ECR_BASE=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Authenticate to ECR
echo -e "${GREEN}Authenticating to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} \
  | docker login --username AWS --password-stdin ${ECR_BASE}

# Build LinOTP
echo -e "\n${GREEN}Building LinOTP image...${NC}"
cd linotp3 || exit 1
docker build --platform linux/amd64 -f Dockerfile.opensource -t laa-workspaces/linotp3:latest . || exit 1
echo -e "${GREEN}✓ LinOTP image built${NC}"

# Build FreeRADIUS
echo -e "\n${GREEN}Building FreeRADIUS image...${NC}"
cd ../freeradius || exit 1
docker build --platform linux/amd64 -t laa-workspaces/freeradius-linotp:latest . || exit 1
echo -e "${GREEN}✓ FreeRADIUS image built${NC}"

cd .. || exit 1

# Tag images
echo -e "\n${GREEN}Tagging images...${NC}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

docker tag laa-workspaces/linotp3:latest ${ECR_BASE}/laa-workspaces/linotp3:latest
docker tag laa-workspaces/linotp3:latest ${ECR_BASE}/laa-workspaces/linotp3:${TIMESTAMP}

docker tag laa-workspaces/freeradius-linotp:latest ${ECR_BASE}/laa-workspaces/freeradius-linotp:latest
docker tag laa-workspaces/freeradius-linotp:latest ${ECR_BASE}/laa-workspaces/freeradius-linotp:${TIMESTAMP}

# Push to ECR
echo -e "\n${GREEN}Pushing images to ECR...${NC}"
docker push ${ECR_BASE}/laa-workspaces/linotp3:latest
docker push ${ECR_BASE}/laa-workspaces/linotp3:${TIMESTAMP}
echo -e "${GREEN}✓ LinOTP pushed${NC}"

docker push ${ECR_BASE}/laa-workspaces/freeradius-linotp:latest
docker push ${ECR_BASE}/laa-workspaces/freeradius-linotp:${TIMESTAMP}
echo -e "${GREEN}✓ FreeRADIUS pushed${NC}"

echo -e "\n${GREEN}=== Success! ===${NC}"
echo -e "${YELLOW}Images pushed with tags:${NC}"
echo "  - latest"
echo "  - ${TIMESTAMP}"
echo ""
echo -e "${YELLOW}ECR will automatically scan the images (takes 5-10 minutes)${NC}"
echo ""
echo "Check scan results:"
echo "  aws ecr describe-image-scan-findings --repository-name laa-workspaces/linotp3 --image-id imageTag=latest --region ${AWS_REGION} --profile ${AWS_PROFILE} --no-cli-pager --query 'imageScanFindings.findingSeverityCounts'"

