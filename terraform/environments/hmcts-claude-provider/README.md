# HMCTS Claude Provider

This environment provides AWS Bedrock access for Claude AI models in the eu-west-1 (Ireland) region.

## AWS Bedrock Setup

This environment is configured to use AWS Bedrock with Claude models. The following manual setup steps are required:

### 1. Request Model Access

First, request access to Claude models in the AWS Bedrock console:

1. Go to the [Bedrock Model Access page](https://eu-west-1.console.aws.amazon.com/bedrock/home?region=eu-west-1#/modelaccess)
2. Request access to:
   - Claude Sonnet 4.5
   - Claude Sonnet 4 (optional - requires marketplace subscription)

### 2. Create Bedrock API Key

Run the provided script to create a Bedrock API key with 90-day expiry:

```bash
./create-bedrock-api-key.sh
```

This script will:
- Assume the BedrockAPIKeyCreator role (which bypasses the common_policy deny)
- Create the IAM user if needed
- Generate a service-specific credential (bearer token)
- Output the configuration for Claude Code

**Important:** Save the bearer token shown in the output - it cannot be retrieved again!

### 3. Configure Claude Code

Add the environment variables from the script output to your `~/.bashrc` or `~/.zshrc`:

```bash
# Claude Code Bedrock Configuration
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
export MAX_THINKING_TOKENS=1024
export ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_BEARER_TOKEN_BEDROCK='<your-bearer-token>'
```

Then reload your shell:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

## Available Models

Use the system-defined EU inference profiles for cross-region load balancing:

- **Claude Opus 4.5**: `global.anthropic.claude-opus-4-5-20251101-v1:0` (global only - no EU profile available)
- **Claude Sonnet 4.5**: `eu.anthropic.claude-sonnet-4-5-20250929-v1:0` (recommended)
- **Claude Sonnet 4**: `eu.anthropic.claude-sonnet-4-20250514-v1:0`
- **Claude Haiku 4.5**: `eu.anthropic.claude-haiku-4-5-20251001-v1:0`

These inference profiles route requests across multiple EU regions (eu-west-1, eu-central-1, eu-north-1, eu-west-3, etc.) for optimal availability.

## Troubleshooting

### Bearer Token Authentication

Note: The bearer token (BSK...) format may not work with all Bedrock API endpoints. If you encounter authentication issues with Claude Code, you may need to use AWS credential-based authentication instead.


## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
