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

## GitHub repository backup storage

The `github-backup/` Terraform component provisions the storage for the opt-in
[GitHub backup proof of concept](https://github.com/ministryofjustice/developer-experience/issues/453).
Resources are created only in the `developer-experience-production` workspace,
in its DevEx AWS account, in `eu-west-2`. Run Terraform from `github-backup/`
against this component's own state, not the parent directory's Terraform root.
Account IDs are resolved through the existing environment-management
configuration; no account ID is hard-coded.

| Contract | Value |
| --- | --- |
| SSM Parameter Store name | `/github-management/github-backup/s3-uri` |
| Parameter type | `String` (the URI is not a secret) |
| Parameter value | `s3://mojdevx-production-github-backup` |
| Bucket | `mojdevx-production-github-backup` |
| KMS alias | `alias/github-backup` |
| Consumer IAM role | Existing `github-management` role, managed by `github-management/` |
| Region | `eu-west-2` |

Deploy `github-backup/` before `github-management/`: the management component
looks up the bucket and KMS alias when it applies the consumer role's upload
permissions. The SSM parameter path is retained so consumers do not need to
change their configuration.

The `github_backup_destination` Terraform output exposes the parameter name,
URI, key ARN, role ARN, account ID and region after deployment. It is null
outside production.

To inspect this contract from the deployed component's state, run
`terraform output -json github_backup_destination` from `github-backup/`
with the existing backend initialised and the production workspace selected.

The storage uses these pinned upstream modules:
`terraform-aws-modules/terraform-aws-s3-bucket` v5.15.4
(`dd0c434de5e74d8864e249ee020d917b076b6e32`) and
`terraform-aws-modules/terraform-aws-kms` v4.2.1
(`af1d45558a6073c017a732d2273efcc733b34d0f`).

The private bucket blocks all public access, disables ACLs with
`BucketOwnerEnforced` ownership, requires secure transport and TLS 1.2 or later,
and enables versioning and default KMS encryption with a dedicated rotating key.
`force_destroy = false` prevents Terraform from emptying a populated bucket
during deletion. This is not Object Lock or an immutable retention guarantee.
There is no automatic expiry of archives or object versions: a retention policy
must be agreed separately. The KMS key has a 30-day deletion window and must be
retained for as long as its encrypted backups need to be restored.

The existing role managed by `github-management/` and trusted by
`ministryofjustice/developer-experience-github-management`
can retrieve this exact parameter with `ssm:GetParameter`, upload archives with
`s3:PutObject`, clean up failed multipart uploads with `s3:AbortMultipartUpload`,
and use `kms:GenerateDataKey` and `kms:Decrypt` on the dedicated key (decryption is
required for multipart uploads). No backup object read, list or delete access is
added, and neither the role's trust policy nor the `octo-access` role is changed.
A restore consumer will need separately scoped object-read and KMS permissions.

The role's existing GitHub OIDC subject pattern is
`ministryofjustice@2203574/developer-experience-github-management@1333267581:*`.
This is repository-identity scoped, but its subject suffix is not restricted to
a particular branch or GitHub environment. The consumer must use a token
matching that existing subject configuration; this change does not add trust for
the repository being backed up. The backup bucket's policy adds only denies for
insecure transport and TLS below 1.2, not a public or cross-account allow.
Same-account upload access comes from the existing role's scoped IAM permissions.

After deploying, assume the existing role in the DevEx production account and
retrieve the destination before passing it to the backup script:

```sh
aws ssm get-parameter \
  --region eu-west-2 \
  --name /github-management/github-backup/s3-uri \
  --query Parameter.Value \
  --output text
```

The consumer appends `owner/repository/timestamp-unique-archive` keys to this
base URI. Upload without an ACL; S3 applies the bucket's default KMS encryption.
This infrastructure does not deploy a backup job or schedule. Deployment,
GitHub Actions authentication and scheduled consumer wiring remain separate;
no backup interval has been agreed.
