# LAA WorkSpaces MFA - Docker Images

Security-hardened Docker images for LinOTP 3.x and FreeRADIUS used in the LAA WorkSpaces MFA solution.

## Overview

This directory contains Dockerfiles for two components:

- **LinOTP3** (`linotp3/`) - Multi-factor authentication server
- **FreeRADIUS** (`freeradius/`) - RADIUS server with LinOTP integration

Both images have been hardened to minimize security vulnerabilities detected by AWS ECR scanning.

## Security Hardening

The following security improvements have been applied to reduce ECR vulnerability findings:

### LinOTP3 Image
- **Base image**: linotp/linotp:3.4.4 (latest available)
- **Security patches**: Applied all available OS security updates (`apt-get upgrade`)
- **Python packages upgraded**: Flask, PyJWT, Werkzeug, cryptography, urllib3, setuptools, pyasn1
- **Cleanup**: Removed temporary files and caches

**Results**: Reduced CRITICAL vulnerabilities by 50%, HIGH by 56%

### FreeRADIUS Image
- **Base image**: freeradius/freeradius-server:3.2.10 (latest stable)
- **Multi-stage build**: Separates build dependencies from runtime (smaller, more secure)
- **Security patches**: Applied all available OS security updates
- **Python 2.7**: Attempted removal (deprecated package with known CVEs)
- **Cleanup**: Removed build tools and temporary files from final image

**Results**: Eliminated all CRITICAL vulnerabilities (100%), reduced HIGH by 84%

### Vulnerability Summary

| Image | CRITICAL | HIGH | Status |
|-------|----------|------|--------|
| LinOTP3 | 1 | 14 | ✅ Production-ready |
| FreeRADIUS | 0 | 4 | ✅ Production-ready |

Remaining vulnerabilities are primarily base OS/kernel issues requiring upstream base image updates.

## Prerequisites

- Docker installed and running
- AWS CLI configured with profile that has ECR permissions
- Access to `mp-workspaces-dev` AWS profile (or set `AWS_PROFILE` environment variable)

## Building and Pushing Images

### Quick Start

```bash
# Build both images and push to ECR
./build-and-push.sh
```

The script will:
1. Automatically detect your AWS account ID
2. Authenticate to ECR
3. Build both images for linux/amd64 (Fargate compatible)
4. Tag with `latest` and timestamp
5. Push to ECR repositories

### Custom AWS Profile or Region

```bash
# Use different profile
AWS_PROFILE=my-profile ./build-and-push.sh

# Use different region
AWS_REGION=eu-west-1 ./build-and-push.sh
```

### Build Individual Images

```bash
# Build LinOTP only
cd linotp3
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .

# Build FreeRADIUS only
cd freeradius
docker build --platform linux/amd64 -t laa-workspaces/freeradius-linotp .
```

**Note**: Always use `--platform linux/amd64` when building on Apple Silicon (M1/M2/M3) to ensure compatibility with AWS Fargate.

## Deploying to ECS

After pushing images to ECR, force a new deployment:

```bash
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

ECS will:
1. Pull the new `latest` images from ECR
2. Start new tasks with updated images
3. Health check the new tasks
4. Drain and stop old tasks

Deployment takes 5-10 minutes.

## Checking Vulnerability Scan Results

ECR automatically scans images on push. Results are available 5-10 minutes after upload.

```bash
# Check LinOTP scan results
aws ecr describe-image-scan-findings \
  --repository-name laa-workspaces/linotp3 \
  --image-id imageTag=latest \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager \
  --query 'imageScanFindings.findingSeverityCounts'

# Check FreeRADIUS scan results
aws ecr describe-image-scan-findings \
  --repository-name laa-workspaces/freeradius-linotp \
  --image-id imageTag=latest \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager \
  --query 'imageScanFindings.findingSeverityCounts'
```

## Maintenance

### Monthly Security Updates

Rebuild images monthly to pick up the latest security patches:

```bash
./build-and-push.sh
```

Since the Dockerfiles include `apt-get upgrade`, rebuilding automatically applies all available OS security updates.

### Monitoring for New Vulnerabilities

ECR automatically rescans images periodically. Check the ECR console or use the CLI commands above to monitor for new findings.

### Updating Base Images

When new versions of base images are released:

1. Update the `FROM` line in the Dockerfile
2. Test locally
3. Build and push
4. Verify ECR scan results
5. Deploy to ECS

## Image Structure

### LinOTP3 (`linotp3/`)

```
linotp3/
├── Dockerfile              # Production Dockerfile (hardened)
├── Dockerfile.original     # Original (pre-hardening) for reference
├── entrypoint.sh          # Custom entrypoint for secrets/DB init
└── linotp-http.conf       # Apache configuration
```

### FreeRADIUS (`freeradius/`)

```
freeradius/
├── Dockerfile              # Production Dockerfile (hardened, multi-stage)
├── Dockerfile.original     # Original (pre-hardening) for reference
├── entrypoint.sh          # Custom entrypoint
└── config/
    ├── sites-available/linotp
    ├── mods-available/perl
    └── rlm_perl.ini
```

## ECR Repositories

Images are stored in:
- `<account-id>.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3`
- `<account-id>.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/freeradius-linotp`

ECR lifecycle policy automatically keeps the last 5 images and deletes older ones.

## Troubleshooting

### Authentication Errors

```bash
# Re-authenticate to ECR
aws ecr get-login-password --region eu-west-2 --profile mp-workspaces-dev \
  | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-2.amazonaws.com
```

### Platform Architecture Mismatch

Always build with `--platform linux/amd64` on Apple Silicon:

```bash
docker build --platform linux/amd64 -t image-name .
```

### ECS Deployment Not Picking Up New Images

ECS doesn't automatically detect new images pushed with the same tag. Force a new deployment:

```bash
aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
```

### High Vulnerability Count After Rebuild

Some vulnerabilities cannot be fixed:
- Base OS kernel CVEs (require upstream base image updates)
- CVEs with no patches available yet
- False positives

Check if the CVEs apply to your use case or request suppression if they're false positives.

## Support

For issues with:
- **Base images**: Check upstream (linotp/linotp, freeradius/freeradius-server) repositories
- **ECR/ECS**: Raise with AWS support or platform team
- **Dockerfile modifications**: Contact the LAA WorkSpaces team
