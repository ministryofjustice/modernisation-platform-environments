# Dormant GitHub user report runbook

## Status

Handover for building a Lambda report that lists GitHub users with no
qualifying activity in a set window, using the audit logs this component
already streams to S3 and exposes through Athena. Nothing in this document is
deployed yet.

The report produces candidates for human review. It doesn't suspend or remove
anyone; account removal follows the existing approved process.

Background is in [developer-experience#331](https://github.com/ministryofjustice/developer-experience/issues/331).
The prototype there used a 30-day window to 00:00 UTC on 8 October 2026 and
API snapshots of `ministryofjustice` and `moj-analytical-services`. Treat its
numbers as exploratory, not a baseline.

Still to do before go-live:

- run the report queries against live data in Athena (the 100-record check in
  #331 only proved connectivity)
- compare like for like with the prototype and GitHub's export
- agree the items under [Decisions needed](#decisions-needed)

## What already exists

All of this is in this Terraform component and only created in production
(`local.is-production`).

| Resource | Defined in | Notes |
| --- | --- | --- |
| Audit-log bucket | [`s3-buckets.tf`](./s3-buckets.tf) | KMS-encrypted, versioned, TLS only, objects expire after 730 days. Source data for the report. |
| Uploader role and OIDC provider | [`iam-roles.tf`](./iam-roles.tf), [`iam-oidc-providers.tf`](./iam-oidc-providers.tf) | GitHub writes logs with this role. Keep it for ingestion; don't reuse it for the report. |
| Glue table `github_audit_logs.enterprise_audit_logs` | [`athena.tf`](./athena.tf) | JSON over the audit bucket, `datehour` partition projection, `@timestamp` mapped to `event_timestamp`. |
| Athena workgroup `github-audit-logs` | [`athena.tf`](./athena.tf) | Enforced config, CloudWatch metrics, 10 GiB per-query scan limit. |
| Athena results bucket | [`athena.tf`](./athena.tf) | Query results, expired after 30 days. Not for snapshots or reports. |
| KMS key | [`kms-keys.tf`](./kms-keys.tf) | Encrypts both buckets. |
| VPC and subnet lookups | [`platform_data.tf`](./platform_data.tf) | Shared data sources. The report may not need a VPC at all. |

Not built yet: the report Lambda and its role, the schedule, the snapshot job
and its storage, the report bucket and alerting.

The prototype's four outputs (`dormant_report.csv`, `rules.csv`,
`rule_counts.csv`, `org_summary.csv`) are the starting point for the report
format.

## Decisions needed

Agree these in the implementation PR before anything runs against production
data.

- **Scope:** which organisations count. The prototype population covered 2
  orgs while its audit data covered 7. Decide whether the whole enterprise is
  in scope, including agencies such as HMPPS, and whether licences come from a
  shared pool.
- **Window and schedule:** the dormancy window, UTC cut-off, how often it runs
  and how late or missing logs are handled. 30 days was a prototype choice,
  not policy.
- **Storage:** bucket and prefixes for snapshots and reports, data
  classification, who can read them, retention and KMS key.
- **GitHub access:** a GitHub App with the minimum read permissions for
  members, teams and repository visibility, and who owns and rotates it.
- **AWS access:** a dedicated least-privilege Lambda role, its trigger,
  networking and Terraform ownership.
- **Ownership:** service owner, report reviewer, alert recipient and support
  route.
- **User notification:** how and when users are told about removal, and what
  the rejoining instructions say. See [Notifying users](#notifying-users).

## Notifying users

[User feedback](https://mojdt.slack.com/archives/C0AJBK3P5A8/p1792573404095199)
asked for users to be told when they're removed from an organisation and how
to get back in. Build this into the removal process:

- **Before removal:** warn each confirmed candidate that their account is due
  to be removed for inactivity, give the date, and explain how to keep access.
- **At removal:** tell them they've been removed, which organisation it
  applies to, and how to rejoin, linking to the current joining guidance
  rather than copying the steps into the message.
- **Channel:** agree how messages are sent. Users without a verified-domain
  email in the report need another route.
- **Content:** keep messages free of other users' details and of report data
  beyond the user's own status.

The report Lambda doesn't send these alerts. They belong to the human review
and removal process, after a reviewer has confirmed the candidate.

## Build steps

### 1. Check the baseline

1. Confirm the deployed bucket, key, workgroup, Glue table, partitions and
   policies in production match the Terraform. Don't copy identifiers or
   credentials into this document.
2. Run the offline tests in [Rules baseline](#rules-baseline) and check the
   rule mappings against the agreed catalogue.
3. Read the review and removal runbook linked from #331. The report feeds
   that process; it must not trigger account changes itself.

Reuse the existing Glue table and workgroup unless live data shows they don't
work for the report. If changes are needed, make them in Terraform, check the
effect on existing consumers, and don't raise the scan limit or use the
results bucket for report output.

### 2. Snapshot job

The audit log can't show who has *no* activity, so the report needs a dated
snapshot of everyone in scope. Run this as its own job or operator script
rather than inside the report Lambda, so API limits and failures stay
separate.

For each organisation in scope, collect:

- **members and outside collaborators:** user ID, login, org and membership
  type. Join on user ID, never login.
- **team membership:** keyed by user ID. Record any team or org that couldn't
  be read.
- **repository visibility:** repo, org and visibility, so internal pushes can
  be told apart from private and public ones.

The job should:

- page through every response and retry rate limits and transient errors with
  backoff
- fail the whole snapshot on permission errors, incomplete pagination,
  unexpected empty results or a missing org
- check required fields, duplicate IDs and big swings from the previous run
- write to a unique run prefix such as
  `snapshots/as_of=<date>/run_id=<id>/` (layout to be agreed), with a
  manifest (run ID, as-of time, scope, per-org counts, checksums, script
  version) written last as the completion marker
- never overwrite the last good snapshot
- keep the GitHub credential in Secrets Manager and out of logs, and skip
  email addresses unless that use is approved

The report reads three Glue tables over the snapshot data. None exist yet:

| Table | Columns |
| --- | --- |
| `github_audit_logs.report_population_snapshot` | `snapshot_run_id`, `user_id`, `login`, `org` |
| `github_audit_logs.report_user_allowlist` | `user_id`, `owner`, `reason` |
| `github_audit_logs.report_repository_visibility` | `snapshot_run_id`, `repo`, `visibility` |

Keep them separate from the audit-log table. Visibility is as at snapshot
time, not when a past push happened.

### 3. Rules

GitHub defines 20 qualifying activities. The prototype maps 14 of them to
audit events, some only partially.

- **Mapped:** SAML SSO; repository create, delete and visibility change; HTTPS
  push to an internal repository; added to a repository; joined an
  organisation; PR opened; review requested or removed; review comment created
  or edited.
- **Partial or proxy:** PR comment (via review submitted); PR close and reopen
  (issues not covered); comment dismissal (via review dismissed); commit
  comment edited (creation not covered).
- **Not in the audit stream:** labels, assignees, PR synchronise, releases,
  wiki pushes and stars.

Report logic:

- one qualifying event in the window makes a user **active**; none makes them
  a **candidate**
- count activity across the whole enterprise, deduplicated by user ID, and
  report org memberships separately
- credit membership-add events to the user who was added, not the admin
- exclude PAT, SSH-key and GitHub App access, private-repository Git
  operations, issue activity, public-repository pushes, and API requests or
  workflow runs on their own
- coverage score = distinct rules met / 14 × 100. It shows breadth of
  activity, not how sure we are that someone is dormant
- keep excluded-event counts, and keep the bot and service-account allowlist
  (user ID, login, owner, reason) under regular review, with excluded accounts
  reported separately

Keep the rule catalogue (ID, description, mapping status, limitations) as
data so it can be reported on. Don't mark a proxy or unobservable rule as
fully covered.

#### Glue fields used

| Field | Type | Use |
| --- | --- | --- |
| `event_timestamp` | `bigint` | Window filter and last activity. Assumed to be epoch milliseconds; confirm against real records. |
| `action` | `string` | Rule matching. |
| `actor`, `actor_id` | `string`, `bigint` | Who did it. `actor_id` joins to the snapshot. |
| `user`, `user_id` | `string`, `bigint` | Who it was done to, for example the user added to an org. |
| `org` | `string` | Scope and coverage checks. |
| `repo` | `string` | Join to repository visibility. |
| `programmatic_access_type` | `string` | PAT, SSH-key and GitHub App exclusions. |
| `datehour` | `string` partition | Partition pruning. |

The SQL also uses `business`, `actor_is_bot`, `actor_is_agent`,
`transport_protocol_name`, `repository_public` and `visibility`, which the
Glue table doesn't declare yet. Check them against real events. If they need
adding, a separate view or derived table is safer than changing
`enterprise_audit_logs` under its existing consumers. The SerDe skips
malformed JSON, so a successful query doesn't prove every record was read.

#### Rules baseline

[`dormant_user_activity_rules.sql`](./dormant_user_activity_rules.sql) holds
the rule catalogue, event mappings, attribution, filters, classification and
exclusion counters. It's a straight translation of the prototype and hasn't
been run against live data.

Run the offline tests from the repository root. They use the standard library
and synthetic fixtures, so no AWS access is needed:

```sh
python3 -m unittest discover \
  -s terraform/environments/developer-experience/github-audit-log-stream/tests \
  -v
```

They cover the 20-rule catalogue, the 14 mapped rules, action and subject
mapping, UTC boundaries, filters and expected candidates. They don't run the
SQL in Athena or check the deployed schema.

The query takes six positional Athena execution parameters:

| # | Parameter | Example |
| --- | --- | --- |
| 1 | Population snapshot run ID | `'synthetic-run'` |
| 2 | Exclusive cut-off, ISO-8601 UTC | `'2026-10-13T00:00:00Z'` |
| 3 | Inclusive lower `datehour` (`yyyy/MM/dd/HH`) | `'2026/09/13/00'` |
| 4 | Exclusive upper `datehour` | `'2026/10/13/00'` |
| 5 | Count SAML SSO events | `TRUE` |
| 6 | Window length in days | `30` |

Quote strings in the parameter list, pass the Boolean and integer as
literals, and leave the `?` markers in the SQL unquoted. Round the lower
partition bound down and the upper bound up so every overlapping hour is
scanned; the timestamp filter does the exact cut.

### 4. Report Lambda

Each run:

1. loads config and the latest complete snapshot, and stops if it's missing,
   stale or out of scope
2. runs the query in the `github-audit-logs` workgroup with tight `datehour`
   and timestamp filters, logging the query execution ID and run IDs
3. polls Athena with a bounded wait inside the Lambda timeout, or hands off
   to Step Functions if runs get long
4. checks query state, bytes scanned and row counts
5. writes the four CSVs and a run manifest to a unique run prefix, completion
   marker last
6. on any failure, marks the run incomplete, alerts the owner and leaves the
   previous report alone

| File | Contents |
| --- | --- |
| `dormant_report.csv` | One row per user: orgs and membership type, rules met, coverage score, last qualifying activity, days inactive where known, outside-collaborator flag, team count, excluded-event counts and, if approved, verified-domain email availability. |
| `rules.csv` | All 20 rules with mapping status and limitations. |
| `rule_counts.csv` | Distinct users meeting each rule in the window. |
| `org_summary.csv` | Population, active and candidate counts per org. Counts overlap where users are in more than one org. |

Each run also writes a coverage summary: orgs requested and covered, snapshot
age, partitions included, records per day, missing actor IDs and known gaps.
If coverage is incomplete, the report is labelled incomplete.

### 5. Configuration, security and operations

Make these explicit config, checked at start-up: org scope, window and
cut-off, maximum snapshot age, S3 locations, Glue database and table,
workgroup, retention, GitHub secret ARN, allowlist and alert target. Secrets
stay in Secrets Manager, not in Terraform variables, environment variables or
logs.

The Lambda role should only have:

- read on the snapshot prefix and the audit bucket, plus the Glue metadata
  Athena needs
- Athena start, get and results on the `github-audit-logs` workgroup
- write on the report prefix and the Athena results location
- KMS use on the keys for those paths
- CloudWatch Logs, and read on the GitHub secret if API calls run in the
  Lambda

Check the bucket and key policies too, not just the role. Membership and
report data is personal data: restrict who can read it, keep access auditable
and apply the agreed retention.

Don't add an EventBridge schedule until the owner and snapshot cadence are
agreed. Make runs idempotent by run ID and stop two runs publishing for the
same window.

Alarm on failed or incomplete runs. Log outcome, duration, snapshot
freshness, Athena query ID and state, bytes scanned, row counts and errors,
but no usernames, tokens or report rows.

## Acceptance

1. **Snapshots:** pagination, ID joins, member, collaborator, team and
   visibility coverage, rate limits, retries and empty results are tested. A
   partial snapshot fails and can't replace the last good one.
2. **Rules:** fixtures cover every rule, exclusion, proxy and membership-add
   case, plus UTC boundaries, duplicates, multi-org users, missing IDs and the
   score denominator.
3. **Live Athena:** schema, partition projection, timestamp units, real
   action and property values, scan size and the actual report queries are
   checked against production data.
4. **Coverage:** snapshot matches the agreed population, partitions cover the
   window and totals match an independent count. Missing IDs, malformed JSON
   and missing days are explained.
5. **Prototype comparison:** run both with the same orgs, snapshot, window,
   exclusions and cut-off, and explain every difference in population,
   classification, rule counts and org summaries. The comparison in #331
   doesn't count, because its export time was unknown and its population and
   cut-off didn't line up.
6. **Failure and security:** secret rotation, denied access, KMS and bucket
   policies, Athena failures and throttling, Lambda timeout, duplicate
   triggers and partial uploads are tested. A failed run can't mark itself
   complete or overwrite the last report, and alerts carry no report data.
7. **Review:** the service owner confirms the report clearly labels
   candidates and limitations, and can't trigger account changes. Removal
   warnings and rejoining instructions are agreed and tested.

The named owners sign off scope, security, comparison results and remaining
limitations before go-live.

## Known prototype limitations

From the #331 handover:

- The population covered 2 orgs and the audit data 7, with overlapping users.
  The enterprise report has to line the two up and deduplicate by user ID.
- Membership, teams and visibility were current state, not state at the
  cut-off. GitHub's export time was unknown.
- SAML SSO events were counted without confirming the sign-in succeeded.
- An empty verified-domain email result doesn't mean the user has none.
- No qualifying event in the available history doesn't give a real
  last-active date.
- Some activities aren't in the audit stream and some mappings are proxies.
- In the 8 October comparison, 744 of the 775 users in GitHub's export were
  also prototype candidates, 1 was classed active, 30 weren't in the two-org
  population, and the prototype found 113 extra candidates. The differences
  overlapped and no single cause was found.

Re-run with matching cut-offs and populations before drawing conclusions.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Snapshot empty or too small | Org scope, App installation and permissions, pagination, rate limits, manifest. Don't publish. |
| Users or teams missing | Membership types, team pagination, org access, per-org counts. Missing doesn't mean dormant. |
| Push rules look wrong | Visibility snapshot and its as-of time, event properties, `programmatic_access_type`. Raise it for rule review rather than changing the filter. |
| Too few events | Workspace, Glue table, `datehour` values, S3 layout, UTC bounds, timestamp units, retention. |
| Query fails or hits the scan limit | Execution error, partition predicates, scan metrics. Narrow the query; don't raise the limit without approval. |
| Unexpected candidates | Scope, missing actor IDs, coverage gaps, late events, exclusions and the known limitations. Escalate for human review. |
| Report missing or incomplete | Invocation, Athena state, S3 and KMS permissions, upload checks, completion marker. Keep the last good report and don't reuse the run ID. |

## Turning it off

Disable the schedule first, then stop publication. Leave the audit-log
pipeline, source logs, Glue table and workgroup alone, and keep past reports
for the agreed retention period. Revoke the report's GitHub credential and
remove its role through a normal reviewed change. Record why it was turned
off and who can approve turning it back on.

## References

- [Terraform component](./)
- [Athena, Glue and results bucket](./athena.tf)
- [Audit-log bucket](./s3-buckets.tf)
- [Uploader role](./iam-roles.tf) and [OIDC provider](./iam-oidc-providers.tf)
- [KMS key](./kms-keys.tf)
- [Network lookups](./platform_data.tf)
- [Rules baseline SQL](./dormant_user_activity_rules.sql) and [tests](./tests/)
- [developer-experience#331](https://github.com/ministryofjustice/developer-experience/issues/331)
