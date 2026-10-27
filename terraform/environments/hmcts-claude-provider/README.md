# HMCTS Claude Provider

This environment provides AWS Bedrock access for Claude AI models in the eu-west-2 (London) region.

## AWS Bedrock Setup

### 1. Issue a Bedrock API Key

Keys are issued per person, so invocation logs attribute usage to an individual:

```bash
./issue-bedrock-key.sh linus.norton
```

This assumes the BedrockAPIKeyCreator role, creates the IAM user `BedrockAPIKey-<name>` if needed,
attaches `HMCTSClaudeBedrockPolicy`, and issues a credential that expires after 90 days.

- `--rotate` replaces an existing credential, for expiry or a suspected leak
- `--revoke` removes a person's credentials, keeping the IAM user so past usage stays attributable

The token is shown once and cannot be retrieved again.

### 2. Configure Claude Code

Add the environment variables from the script output to your `~/.bashrc` or `~/.zshrc`, then reload
your shell.

Model access does not need requesting per region - the account's marketplace subscriptions already
cover eu-west-2.

## Available Models

### In-region, UK only (eu-west-2)

An unprefixed model ID called against the eu-west-2 endpoint is served from London with no inference
profile in front of it. Four Claude models support this in eu-west-2:

- **Claude Opus 5.5**: `anthropic.claude-opus-5-5` (Claude Code Opus slot)
- **Claude Sonnet 5**: `anthropic.claude-sonnet-5` (Claude Code Sonnet slot)
- **Claude Sonnet 4.6**: `anthropic.claude-sonnet-4-6`
- **Claude Opus 4.6**: `anthropic.claude-opus-4-6-v1`

eu-west-2 is the only region offering in-region inference for Opus 5.5 at all.

Opus 5.5, Sonnet 4.6 and Opus 4.6 are in-region in eu-west-2 and nowhere else, so an unprefixed ID
sent to the wrong region fails rather than running abroad. Sonnet 5 is also in-region in
ap-northeast-2 and ap-southeast-1, so `HMCTSClaudeBedrockPolicy` admits its foundation model ARN
only under `eu-*`, and neither globally nor in any non-EU region.

To check whether another model has gained in-region support:

```bash
aws bedrock list-foundation-models --region eu-west-2 --by-provider anthropic \
  | jq -r '.modelSummaries[] | select(.inferenceTypesSupported|index("ON_DEMAND")) | .modelId'
```

A model listing only `INFERENCE_PROFILE` cannot be pinned to London. Sonnet 5.5, Haiku 5.5, Opus 5,
Opus 4.8, Opus 4.7, Fable 5 and Fable 5.1 are all in that group.

### EU inference profiles (cross-region within the EU)

- **Claude Haiku 4.5**: `eu.anthropic.claude-haiku-4-5-20251001-v1:0`

No Haiku has in-region support in any region, so the Claude Code Haiku slot is the one part of this
environment that is not UK only. Called from eu-west-2 this profile routes across eu-central-1,
eu-north-1, eu-south-1, eu-south-2, eu-west-1, eu-west-2 and eu-west-3.

## Model Invocation Logging

Bedrock model invocation logging is enabled in both eu-west-1 and eu-west-2. eu-west-2 is the region
this README tells people to use and the account default, but the Bedrock policy admits inference
profiles in any region, so traffic can still arrive at eu-west-1. Until October 2026 only eu-west-1 was
logged, and about 39% of that month's spend could not be attributed to anyone.

Logging is configured per region and Bedrock only accepts a destination in its own region, so each
region has its own bucket, KMS key and log group:

| Region | S3 bucket | CloudWatch log group |
| --- | --- | --- |
| eu-west-1 | `hmcts-claude-provider-bedrock-logs-<account-id>` | `/aws/bedrock/modelinvocations` |
| eu-west-2 | `hmcts-claude-provider-bedrock-logs-<account-id>-eu-west-2` | `/aws/bedrock/modelinvocations` |

Records land under `invocation-logs/` and expire after 90 days. Any region not in that table is
still uncaptured; add it to `bedrock_log_buckets` in `bedrock_logging.tf` to start logging it.

Request and response bodies are not logged: `text_data_delivery_enabled` is false, so a record
carries only the envelope - timestamp, principal, model, region and the four token counts. That is
everything the dashboard and per-person attribution need, and it keeps prompts and source code out
of the buckets entirely. One side effect: with bodies off, a streaming invocation writes a second
record under the same `requestId` with zero token counts, so a call count has to be
`count_distinct(requestId)` rather than `count(*)`. Token sums are unaffected.

### Usage dashboard

The `hmcts-claude-bedrock-usage` dashboard in eu-west-1 reports calls, tokens and estimated cost by
user and by model. A Logs Insights query cannot span regions, so the dashboard carries one column of
widgets per region and the columns have to be added together for an account total.

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
