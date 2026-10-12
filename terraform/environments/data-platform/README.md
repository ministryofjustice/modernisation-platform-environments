# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

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

Gary was here.

## OpenAI prompt logging

The internal OpenAI release enforces **fail-closed prompt logging** through
[the OpenAI policy](ai-gateway/src/openai_policy.py). Before a request can call
OpenAI or return a cached answer, it must receive a successful S3 `PutObject`
acknowledgement for its prompt record. A storage/credential failure, invalid
acknowledgement or ten-second deadline expiry rejects the request with HTTP 503.
Health-check prompts also require persistence; clients cannot opt out of this
logging by disabling caching or ordinary logging callbacks.

Prompt records are written beneath `requests/prompts/YYYY/MM/DD/` in the
OpenAI content-log bucket, with explicit SSE-KMS encryption. Each attempt uses a
new UUID and a conditional write to avoid overwriting an existing record.
Records contain the model, structured prompt, instructions, tool definitions,
conversation references, caller hash and LiteLLM call ID when available. Proxy
headers, credentials and internal auth objects are not copied into this record.
The existing private bucket, IAM permissions and 30-day expiry still apply.

The guarantee is that **every OpenAI request admitted through this backend's
inference pipeline has an acknowledged prompt record first**. The record captures
the prompt received by the backend after processing by the main gateway; URLs,
file IDs and previous-response references are recorded as references, not fetched
or expanded into provider-side context. Requests that never reach the backend
cannot be recorded. A rejected write may finish after the deadline, and retries
can produce multiple records; this is not an exactly-once transaction with OpenAI.

Response logging remains the asynchronous `s3_v2` callback, including streaming
responses. It is not a guarantee of complete response capture. Do not infer that
an OpenAI call completed merely because a prompt record exists.

An S3 or KMS outage now makes OpenAI inference unavailable even if an answer is
cached. Look for `OpenAI prompt persistence failed` in pod logs; the entry carries
a request ID and error type without printing prompt content. Check the pod's IRSA
credentials, S3/KMS access and connectivity before retrying. Do not disable the
logging hook as an outage workaround. The OpenAI federation IDs must still be
populated before deployment.

Offline tests in [the gateway tests directory](ai-gateway/tests) mock both S3 and
OpenAI; they do not require populated secrets. With `litellm[proxy]==1.101.5`,
PyYAML and Terraform installed, run:

```sh
PYTHONDONTWRITEBYTECODE=1 LITELLM_LOCAL_MODEL_COST_MAP=True python -m unittest discover \
  -s terraform/environments/data-platform/ai-gateway/tests -v
```

Set `LITELLM_CHART_PATH` to the locally downloaded `litellm-helm` chart version
1.101.0 to include the Helm rendering test. Before admitting live traffic, verify
that denying S3 writes prevents both cache hits and OpenAI calls, and that restoring
access allows calls only after their encrypted prompt records have been written.