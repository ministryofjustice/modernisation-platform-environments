# GitHub dormant-user activity report runbook

## Purpose and status

This document is an implementation handover for an engineer building a
Lambda-based report of GitHub users who may be dormant. It describes how a
proposed report could use the existing GitHub enterprise audit-log data,
Glue Data Catalog and Athena workgroup in this component. It does not implement
or deploy that workflow.

The report is a way to identify **candidates for human review**. It is not a
decision that a user is dormant, and it is never approval to suspend or remove
an account or reclaim a licence. Any account action must continue to follow the
separately approved human review and account-removal process.

The [developer-experience#331 issue](https://github.com/ministryofjustice/developer-experience/issues/331)
contains the report prototype handover and its known limitations. That
prototype used a 30-day window ending at 00:00 UTC on 8 October 2026 and
current GitHub API snapshots for `ministryofjustice` and
`moj-analytical-services`. Its outputs and counts are historical exploratory
results, not a validated production baseline.

The issue records an earlier Athena integration check in which a test query
returned 100 records. That is not live validation of this proposed report.
**Live Athena validation of the report and a controlled comparison against
GitHub's prototype/export remain outstanding.** Do not describe the proposed
workflow as deployed or operational until those activities and the remaining
approvals are complete.

## Existing resources and proposed workflow

The active AWS environment is the
[`github-audit-log-stream/` Terraform component](./). Its resources are
created only when the Terraform workspace is production, as controlled by
`local.is-production`.

| Resource or data | Confirmed in this checkout | Relevance and boundary |
| --- | --- | --- |
| Enterprise audit-log S3 bucket | [`s3-buckets.tf`](./s3-buckets.tf) defines a bucket named from the global S3 prefix, workspace environment and `github-audit-log-stream` component. It uses the component KMS key, blocks insecure transport, enables versioning and expires current and non-current versions after 730 days. | Raw audit logs are the activity source. The bucket name and actual objects must be confirmed from the production workspace/state; no account or bucket identifier is hard-coded here. |
| GitHub audit-log uploader role and OIDC provider | [`iam-roles.tf`](./iam-roles.tf) and [`iam-oidc-providers.tf`](./iam-oidc-providers.tf) define the GitHub audit-log OIDC trust and a role with `s3:PutObject` on the audit bucket and `kms:GenerateDataKey` on the component key. | This is the existing log-ingestion identity, not a report Lambda role. Do not widen or reuse it for report execution. |
| Glue database and table | [`athena.tf`](./athena.tf) defines database `github_audit_logs` and table `enterprise_audit_logs`, over compressed JSON in the audit-log bucket. The table projects the `datehour` partition from the path and maps `@timestamp` to `event_timestamp`. | The proposed query reads this catalog table. Check the deployed schema and actual partition/path layout before relying on them. |
| Athena workgroup | [`athena.tf`](./athena.tf) defines enabled workgroup `github-audit-logs`, enforces its configuration, publishes CloudWatch metrics and has a 10 GiB per-query scan cutoff. | The report should use the existing workgroup only after confirming the Lambda's approved access and the deployed workgroup configuration. |
| Athena query-results bucket | [`athena.tf`](./athena.tf) defines a separate, production-only bucket for workgroup results, encrypted with the component KMS key and configured to expire query results after 30 days. | Athena writes query results here; this is not automatically an approved location for final report files or membership snapshots. |
| KMS key | [`kms-keys.tf`](./kms-keys.tf) defines the component key used by the audit and Athena buckets. | Confirm key policy and caller permissions for any proposed Lambda or snapshot writer. |
| VPC and subnet lookup | [`platform_data.tf`](./platform_data.tf) reads shared VPC and subnet data. | This does not establish that the current Lambda design needs VPC attachment or has network access to GitHub. Decide based on the chosen execution/networking model. |
| Existing report Lambda and scheduled job | None is defined in this component's checked-in Terraform source. | Lambda code, execution role, schedule, snapshot storage, report output, alerting and ownership are proposed additions, not existing resources. |

The issue describes historical prototype outputs named
`dormant_report.csv`, `rules.csv`, `rule_counts.csv` and `org_summary.csv`.
They are useful as a starting report contract, not evidence that these files
are already generated or stored in AWS.

## Decisions and prerequisites before implementation

Record decisions in the implementation change or its review before enabling a
job. The repository and issue do not settle the following:

- **Population and enterprise scope:** confirm which organisations to include
  and whether the report should cover the full MoJ enterprise. The prototype
  snapshots covered two organisations, while its audit-log analysis described
  events from seven organisations. The Terraform uploader trust refers to the
  configured enterprise slug, but that alone does not establish complete log
  delivery or a matching user population. Decide whether agencies such as
  HMPPS are in scope, and whether their licences are managed from a shared
  pool.
- **Reporting interval and cut-off:** agree the dormancy window, UTC boundaries,
  run cadence and treatment of late or missing logs. The prototype used 30
  days, but that is not an approved production schedule or policy.
- **Snapshot and report storage:** approve a bucket and prefixes, data
  classification, readers, retention, versioning, encryption key and deletion
  process. Decide whether snapshots belong in a new dedicated location or an
  approved prefix in an existing bucket. Do not assume the Athena query-results
  bucket is appropriate for source snapshots or final reports.
- **GitHub API identity and permissions:** approve an organisation-level
  GitHub App or other supported identity with the minimum permissions needed
  to read membership, teams and repository visibility for the agreed scope.
  Confirm token custody, rotation, rate-limit handling and who administers the
  credential. No such report credential is confirmed by the resources listed
  above.
- **AWS deployment and access model:** agree the Lambda role, trust policy,
  network placement, encryption-key access, Terraform ownership and
  deployment/review approvals. Create a separate least-privilege report
  execution identity; do not extend the audit-log ingestion role by default.
- **Operational ownership:** name the service owner, report reviewer, alert
  recipient, support route and approver for any later account action. These
  are not established by this component's Terraform.
- **Prototype source of truth:** obtain and preserve the prototype SQL,
  preparation scripts, exact 20-rule catalogue and representative input/output
  fixtures. The issue handover describes their names and behaviour, but the
  scripts and SQL are not present in this component's checked-in source.

Do not run against production data or enable a schedule until the scope,
identity, destination, retention, access and ownership decisions have been
approved.

## Proposed implementation sequence

### 1. Establish the baseline

1. Review the current production Terraform state and AWS console/API
   configuration for the resources in the table above. Confirm the real
   bucket, key, workgroup, Glue database/table, partitions, retention and
   access policies from authorised sources. Do not copy sensitive identifiers
   or credentials into this runbook.
2. Obtain the prototype SQL and scripts referenced by issue #331. Preserve
   their rule definitions and known exclusions as a version-controlled
   baseline, with tests and representative fixtures, before porting them.
3. Agree the exact report population, audit-log enterprise scope, UTC window,
   snapshot as-of time, retention and output readers. Record unresolved
   decisions explicitly.
4. Inspect the human review/removal runbook linked by issue #331. Ensure the
   new report feeds its review process and cannot trigger automatic account
   removal.

### 2. Implement the report with Lambda, Athena and Glue

Use a scheduled or manually invoked Lambda as the report runner. It should
validate the approved configuration and latest complete GitHub population
snapshot, submit partition-pruned SQL to the existing Athena workgroup, read
the query results, render the agreed report files and publish them to a
separately approved destination. Athena should read the existing
`github_audit_logs.enterprise_audit_logs` Glue table over the streamed audit
logs. The Lambda, its execution role, trigger and report destination do not
currently exist in this component and must be designed, reviewed and added
through a separate implementation change; this runbook does not make those
changes.

The existing catalog and workgroup are the starting point, not a guarantee
that they need no changes. Inspect real records and validate the deployed
configuration before deciding:

| Resource | Required approach | Change only if validation shows it is needed |
| --- | --- | --- |
| Glue database and table in [`athena.tf`](./athena.tf) | Reuse `github_audit_logs.enterprise_audit_logs` and its `datehour` projection when its deployed location, partition layout and schema match the production data. | If required event properties are absent, update the table's `storage_descriptor.columns` with verified types and SerDe mappings in Terraform. For unstable or nested event shapes, prefer a separately managed derived table or view over changing the existing table in a way that could break its consumers. Change the S3 location or partition projection only if the actual log layout requires it. Test schema compatibility and malformed-record effects before rollout. |
| Population snapshot and Glue registration | No report population snapshot or corresponding Glue table is defined in this component. | Store a complete, approved snapshot in its approved S3 location and register a separate Glue table with at least `snapshot_run_id`, `user_id`, `login` and `org`. Define its schema, partitioning and retention to match the actual snapshot format. Do not mix membership snapshots into the audit-log table or infer the population from activity events. |
| Athena workgroup and results bucket in [`athena.tf`](./athena.tf) | Use `github-audit-logs` and its enforced configuration, encrypted result location, metrics and 10 GiB per-query scan cutoff. Design queries to prune `datehour` partitions and remain within that cutoff. | Change the workgroup cutoff, result location or encryption only through reviewed Terraform changes if the approved report design cannot operate with the current settings. Update the associated bucket/KMS permissions consistently. Do not bypass the cutoff or treat the query-results bucket as final report storage. |
| Lambda execution role and report destination | Create a separate least-privilege report identity and an approved destination for published files; keep the existing audit-log uploader role dedicated to ingestion. | Add only the required query, Glue metadata, audit-data, snapshot, result, report-write and KMS permissions to the relevant identities and resource policies. These resources and permissions are not currently defined for a report in this component. |

No Glue or Athena Terraform change should be made pre-emptively. Any required
change must be based on verified deployed schemas and representative data,
reviewed for effects on existing consumers, and validated in the authorised
environment. Live report-query validation remains outstanding.

### 3. Prepare dated GitHub API snapshots

Provide the Lambda with a complete, dated population snapshot. The preferred
boundary is a separately operated preparation job or operator-run script
which writes to an approved location; combining snapshot collection with the
report Lambda is an implementation choice that needs to account for network
access, runtime limits, permissions and failure isolation. The report Lambda
must reject a missing or incomplete snapshot. The preparation process must
fetch data from GitHub APIs for every approved organisation:

1. **Membership:** paginate through organisation members and outside
   collaborators, retaining stable GitHub user IDs, logins, organisation,
   membership type and snapshot timestamp. Do not use login as the join key.
2. **Teams:** fetch team membership with pagination and retries, associate
   memberships to user IDs, and preserve the organisation/team identifiers
   needed by the report. Record teams or organisations that could not be read.
3. **Repository visibility:** enumerate repositories in scope with pagination
   and capture stable repository identity, organisation, visibility and
   snapshot timestamp. The report needs to distinguish internal from private
   and public repositories; never infer visibility from a missing row.
4. Use bounded retries with backoff for transient errors and rate limits.
   Treat permission errors, incomplete pagination, unexpected empty results,
   API failures and partial organisation coverage as a failed snapshot, not a
   successful empty population.
5. Validate the returned scope against the approved organisation/repository
   allowlist. Check required fields, unique IDs, counts, pagination completion,
   referential integrity and plausible changes from the previous snapshot.
   Produce a manifest recording the run ID, UTC as-of time, approved scope,
   per-organisation counts, completion/coverage status, script version and
   checksums. Do not put access tokens or unnecessary personal data in the
   manifest or logs.
6. Write to a unique, dated staging prefix in the approved destination. Use
   encryption and transport settings required by that destination. Verify
   uploaded object sizes/checksums and write a completion marker or final
   manifest only after every dataset passes validation. A consumer must ignore
   a run without that marker. Never overwrite the last known-good snapshot
   with partial results.
7. Keep API credentials in an approved secrets store, restrict access to the
   job identity, avoid printing them, and document rotation and revocation.
   Minimise captured data: for example, the prototype reports whether a
   verified-domain email is available; it does not need to expose email
   addresses unless a separately approved use requires them.

Agree the output format (for example JSON Lines or CSV), partition/prefix
layout and exact manifest contract with the Lambda implementation before
building it. A date-oriented layout such as
`snapshots/as_of=<UTC-date>/run_id=<unique-id>/` is illustrative only, not an
approved bucket or path.

### 4. Port the prototype rules into Athena SQL

The existing Glue table currently declares these top-level fields in
[`athena.tf`](./athena.tf):

| Glue field | Type in Terraform | Report use |
| --- | --- | --- |
| `event_timestamp` | `bigint` | UTC event-time filtering for the agreed window and last qualifying activity. Confirm units and conversion against actual records. |
| `action` | `string` | Event type/action matching for the rule catalogue. |
| `actor` | `string` | Actor login for events credited to the acting user. |
| `actor_id` | `bigint` | Stable actor identity and joins to the population snapshot. |
| `user` | `string` | Subject/recipient login when an action targets another user. |
| `user_id` | `bigint` | Stable subject/recipient identity; membership additions are credited to the added user, not the administrator. |
| `org` | `string` | Organisation scope and coverage checks. |
| `repo` | `string` | Repository association for visibility-sensitive activity. |
| `programmatic_access_type` | `string` | Excluding PAT, SSH-key and GitHub App activity where the prototype rules require it. |
| `datehour` partition | `string` | Projected audit-log path partition used to limit scanned data. |

Preserve the prototype's event-property extraction and filters in the Lambda's
Athena SQL as well as these top-level fields. The handover requires
distinguishing HTTP(S) pushes from SSH, internal from private/public
repository visibility, and PR activity from issue activity. Check real audit
event payloads before deciding whether the Glue table needs additional typed
columns or mappings. Do not assume event-specific properties are top-level
columns. The JSON SerDe is configured to ignore malformed JSON, so include
checks for parse/coverage effects rather than treating a successful query as
proof that no records were skipped. Any table or workgroup changes must follow
the conditional Terraform guidance above.

Port the 20 documented GitHub qualifying activities as a versioned rule
catalogue. The prototype says 14 have audit-event mappings; several are
partial or proxies. The issue handover identifies these categories:

- Mapped categories: SAML SSO; repository creation, deletion and visibility
  changes; HTTPS pushes to internal repositories; being added to a repository;
  joining an organisation; pull-request creation; review requests and
  removals; and creating or editing review comments.
- Partial/proxy categories: pull-request comments represented by review
  submission; pull-request close/reopen but not issue close/reopen; comment
  dismissal represented by review dismissal; and commit-comment edits without
  creation.
- Not observable in this audit stream according to the prototype: applying or
  removing labels; assigning or unassigning issues/PRs; pull-request
  synchronisation; publishing releases; wiki pushes; and repository stars.

The exact 20 rule names, event actions, payload predicates and exclusions must
come from the prototype catalogue and be checked against current GitHub
documentation and real records. Keep rule identity, description, observability
status and limitations in a queryable/reportable catalogue; do not silently
upgrade a proxy or unobservable rule to fully covered.

Implement the following report logic from the prototype:

- An **active** user has at least one qualifying event in the agreed UTC
  window; one qualifying event is enough.
- A **dormant candidate** has no qualifying event observed in that window. It
  does not mean confirmed dormant, and the report must show relevant coverage
  limitations.
- Count qualifying activity across the agreed enterprise scope, while
  reporting the user's organisation memberships separately. Deduplicate
  users by GitHub user ID.
- Credit repository/organisation membership-add events to the user added,
  rather than the administrator acting.
- Exclude PAT (classic and fine-grained), SSH-key and GitHub App access,
  private-repository Git operations, issue creation/commenting, public
  repository pushes, API requests alone and workflow runs alone where the
  prototype rules specify those exclusions. Confirm filters against GitHub's
  documented behaviour before acceptance.
- Retain the prototype's distinct-rule coverage score:
  `distinct rules satisfied / 14 mapped rules * 100`. Label it as breadth of
  observed activity, **not dormancy confidence**. Keep the denominator and
  mapping status visible if the catalogue changes.
- Preserve excluded-event counters and any bot/service-account allowlist as
  auditable data. The issue recommends recording each excluded account's
  GitHub user ID, login, owner and reason, reviewing that list periodically,
  and retaining excluded accounts in a separate output.

Produce the four prototype-shaped outputs unless stakeholders approve a
documented change:

| Output | Minimum content |
| --- | --- |
| `dormant_report.csv` | One row per unique user; organisations and member/outside-collaborator status; qualifying rule IDs/count; coverage score; last qualifying activity; days inactive when knowable; verified-domain email availability if approved; outside-collaborator flag; team count; and excluded-event counters. Include run/window/snapshot identifiers or a linked manifest. |
| `rules.csv` | All 20 rules, observability and mapping status, plus limitations. |
| `rule_counts.csv` | Population-user counts satisfying each rule in the selected window. Define whether counts are distinct users and how missing population coverage is treated. |
| `org_summary.csv` | Population, active and dormant-candidate counts for each organisation, with scope/cut-off metadata. State that organisation counts overlap when users belong to multiple organisations. |

Also emit an audit-coverage summary for the run: requested and covered
organisations, snapshot age and completeness, included audit-log date/partition
range, records by day (and relevant org where feasible), null/missing actor
identifiers, malformed/unclassified records where measurable, and any
collection gaps or partial mappings. A report with incomplete coverage must
be marked incomplete and must not present unobserved activity as proof of
dormancy.

#### Illustrative Athena candidate query

The audit-log table contains events, not the complete set of users. It cannot
return users with no qualifying events unless the query also starts from a
complete population snapshot. The example below assumes a separately
registered Glue table named `github_audit_logs.report_population_snapshot`
with `snapshot_run_id`, `user_id`, `login` and `org` columns. That table does
not currently exist in this component; its approved S3 location and Glue
definition are prerequisites described above.

This is a **SQL template, not a validated production query**. Replace both
marked rule placeholders with the complete, reviewed event predicates from
the versioned rule catalogue, including event-property filters, exclusions
and recipient attribution for membership-add events. Check every column and
predicate against live Glue metadata and real records. Do not execute it or
publish its results until the placeholders have been replaced and the query
has passed the validation and prototype-comparison steps below.

```sql
-- Illustrative only: replace the marked rule placeholders before execution.
WITH snapshot_rows AS (
    SELECT user_id, login, org
    FROM github_audit_logs.report_population_snapshot
    WHERE snapshot_run_id = ?
),
population AS (
    SELECT
        user_id,
        max(login) AS login,
        array_sort(array_agg(DISTINCT org)) AS organisations
    FROM snapshot_rows
    GROUP BY user_id
),
approved_scope AS (
    SELECT DISTINCT org
    FROM snapshot_rows
),
qualifying_events AS (
    SELECT
        CASE
            WHEN (<verified membership-add event predicate>) THEN e.user_id
            ELSE e.actor_id
        END AS report_user_id,
        e.event_timestamp
    FROM github_audit_logs.enterprise_audit_logs AS e
    INNER JOIN approved_scope AS s
        ON e.org = s.org
    WHERE e.datehour >= ?
      AND e.datehour < ?
      AND e.event_timestamp >= ?
      AND e.event_timestamp < ?
      AND (
          <complete verified qualifying-event predicates and exclusions>
      )
),
activity AS (
    SELECT
        report_user_id,
        max(event_timestamp) AS last_qualifying_event_timestamp,
        count(*) AS qualifying_event_count
    FROM qualifying_events
    WHERE report_user_id IS NOT NULL
    GROUP BY report_user_id
)
SELECT
    p.user_id,
    p.login,
    p.organisations
FROM population AS p
LEFT JOIN activity AS a
    ON a.report_user_id = p.user_id
WHERE a.report_user_id IS NULL
ORDER BY p.login, p.user_id;
```

After verifying that the chosen Athena engine and Lambda API path support
execution parameters, bind values in this order: snapshot run ID; inclusive
lower `datehour`; exclusive upper `datehour`; inclusive lower event timestamp;
exclusive upper event timestamp. Derive the snapshot run ID and organisation
scope from validated, approved configuration—not request input.
Format partition bounds as UTC `yyyy/MM/dd/HH` strings matching the deployed
projection, rounding the lower bound down and the exclusive upper bound up to
cover every intersecting hour. Keep the exact UTC window in the timestamp
bounds. Confirm whether `event_timestamp` is in seconds or milliseconds from
live records before converting the agreed UTC boundaries to its integer units.
The `?` markers are value parameters, not text substitution. If the selected
Athena API/engine path does not support execution parameters, construct SQL
only from validated configuration and an explicit organisation allowlist,
with correct SQL literal escaping; never concatenate unchecked input.

This example returns candidates only from the selected snapshot and approved
scope. Deduplicate and attribute activity by stable GitHub user ID, not login.
An incomplete snapshot, missing actor/recipient IDs, malformed records,
unavailable event mappings or uncovered audit partitions must mark the run
incomplete rather than cause the Lambda to publish users as candidates.

### 5. Implement the Lambda/Athena/rendering flow

Implement the report runner as a Lambda invoked by the agreed schedule or an
approved manual trigger. The Lambda coordinates snapshot validation, Athena
queries against the existing Glue table, report rendering and publication.
The proposed flow is:

1. Load and validate configuration, reporting-window boundaries, scope and
   the latest complete membership/team/repository-visibility snapshot from
   the approved location.
   Refuse to publish if the snapshot is missing, stale, incomplete or outside
   the approved scope.
2. Start a parameterised or safely constructed Athena query in the existing
   `github-audit-logs` workgroup and `github_audit_logs` database, with
   restrictive `datehour` and timestamp filters. Never interpolate unchecked
   user input into SQL. Record the Athena query execution ID and snapshot/run
   IDs.
3. Query activity, per-rule counts, organisation summary and audit-coverage
   diagnostics from the same declared window and scope. Check query state,
   scanned bytes, row counts and expected output shape. Respect the configured
   workgroup cutoff; do not silently bypass it.
4. Render the approved CSV/report files with stable ordering, explicit UTC
   dates and a run manifest. Escape CSV values correctly and avoid logging
   report rows or personal data.
5. Write final artifacts to the approved, access-controlled report destination
   under a unique run prefix. Verify uploads and write the completion marker
   last. Do not overwrite or delete prior runs as part of normal report
   generation.
6. Publish only a report whose query, population snapshot and audit-coverage
   checks all pass. Otherwise mark the run failed/incomplete, retain enough
   non-sensitive metadata for diagnosis, notify the agreed operational owner
   and leave the last successful report intact.

Athena query execution is asynchronous. Implement bounded polling within the
Lambda's configured timeout or use a separately approved continuation or
orchestration mechanism. Do not make a Lambda wait indefinitely or assume its
timeout, memory, networking or concurrency settings. If result volume may
exceed Lambda limits, agree a streaming or Athena-side output design before
implementation.

### 6. Add configuration, security and operations

Keep the following as explicit, reviewed configuration rather than implicit
constants: approved organisation/repository scope; reporting window and UTC
cut-off; accepted snapshot age; S3 destinations and prefixes; Glue
database/table and Athena workgroup; output format; retention; GitHub secret
reference; bot/service-account exclusions; and notification destination.
Validate configuration at startup and fail clearly on invalid or missing
values. Do not put secrets in Terraform variables, source control, Lambda
environment values in plaintext, or logs.

The proposed Lambda role should be separate from the GitHub log uploader role
and scoped to only the required operations and exact resources. It needs
permission to start and inspect Athena queries in the selected workgroup, read
the required Glue catalog metadata, and access the S3/KMS locations used for
source data, snapshots, query results and published reports as appropriate.
Review, at minimum:

- read access to the approved snapshot prefix and the audit bucket objects
  needed by Athena, plus only the required Glue catalog metadata access;
- Athena query start, status and result retrieval for the selected workgroup;
- write access only to the approved report prefix and Athena's configured
  result location, as required by the implementation;
- KMS use limited to the approved keys and operations for those data paths;
- CloudWatch Logs write access and only the specific secret retrieval needed
  for GitHub API calls, if those calls run in Lambda;
- trust limited to the selected scheduler/invoker and no broad wildcard
  resource grants.

Confirm bucket policies, KMS key policies and cross-account boundaries as
well as identity policies. Use encryption in transit and at rest, least
privilege, restricted report readers and an approved retention/deletion
policy. Treat membership, team and report data as sensitive personal or
organisational information; do not expose it through public objects or
unrestricted logs. Ensure report access is auditable.

No schedule is confirmed. Select and approve an EventBridge schedule only
after agreeing operational need and upstream snapshot freshness. Make runs
idempotent by run ID and avoid concurrent publication for the same reporting
window. Define timeout/retry limits, API and Athena throttling behaviour,
partial failure handling, duplicate invocation handling and retention for
failed staging data.

Add CloudWatch metrics/alarms and structured logs for invocation outcome,
duration, snapshot freshness/completeness, API coverage, Athena query ID/state,
bytes scanned, record counts, output status and errors. Avoid usernames,
tokens and report contents in logs. Provide an actionable notification to the
named support route on failed or incomplete runs and document how to identify
the last known-good report. Operational ownership and alert routing remain
prerequisites, not existing guarantees.

## Validation and acceptance

Do not mark the implementation complete until all of the following pass:

1. **Scope and snapshots:** test pagination, stable user-ID joins, member and
   outside-collaborator coverage, team and repository-visibility coverage,
   duplicate handling, rate limits, retries, incomplete access and unexpected
   empty results. Confirm partial or out-of-scope snapshots fail closed and
   cannot replace a last known-good run.
2. **Rule behaviour:** use fixtures for every rule, exclusion, proxy,
   unobservable activity and membership-add recipient attribution. Verify
   UTC inclusive/exclusive boundaries, duplicate events, multiple
   organisations, multiple qualifying rules, users with no actor events and
   missing actor/user IDs. Check the score denominator and rule counts.
3. **Live Athena validation:** in an authorised environment, validate the
   deployed Glue schema, partition projection, event timestamp conversion,
   representative action/property values, scan limits and the exact report
   queries against live audit data. This remains outstanding; the historical
   100-record integration check is not sufficient.
4. **Coverage:** compare API scope with the approved population, audit
   partitions with the required reporting window, and query totals with
   independent checks. Investigate missing actor IDs, malformed JSON,
   missing days and organisation mismatches. Do not claim complete delivery
   based only on the absence of an observed gap.
5. **Prototype comparison:** run the proposed Lambda/Athena report and the
   existing prototype for the same
   organisations, membership snapshot/as-of time, UTC window, exclusions and
   cutoff. Compare population, active/candidate classifications, per-user
   differences, rule counts and organisation summaries. Investigate every
   discrepancy and document expected differences from GitHub's platform-side
   report, unavailable event types, proxy mappings and current-versus-
   historical membership/visibility data. The exploratory comparison in
   issue #331 is not a substitute: its export time was unknown and its
   population and cutoff were not aligned.
6. **Failure and security:** test secret access and rotation, denied
   unauthorised access, KMS/bucket policy behaviour, Athena failure/throttle,
   Lambda timeout, duplicate trigger and partial upload. Verify failed runs
   cannot publish a success marker or overwrite the prior report, and that
   alerts contain no sensitive report data.
7. **Human review:** have the service owner confirm the report clearly labels
   candidates and limitations and cannot automatically suspend, remove or
   approve removal of users.

Only claim acceptance after the named owners sign off the scope, security,
comparison findings, operational process and remaining limitations.

## Known prototype limitations to carry forward

The issue handover reports that:

- The prototype's user snapshot covered two organisations, while its audit
  data covered events associated with seven organisations. The two
  organisation counts overlapped; the proposed enterprise-wide workflow must
  align population and audit scope and deduplicate by user ID.
- Membership, teams and repository visibility were current snapshots, not
  historical state at the report cut-off. GitHub's export generation time was
  unknown.
- SAML SSO events counted without confirmation that authentication succeeded.
- An empty verified-domain email result did not prove that the user had no
  verified email.
- No qualifying event in available history did not establish the true last
  activity date or exact inactivity duration.
- Some GitHub qualifying activities are not observable in this audit stream,
  and some mappings are partial or proxies.
- For the exploratory 8 October comparison, 744 of 775 users in GitHub's
  export were also candidates, one was classified active, 30 were absent from
  the two-organisation population, and the prototype produced 113 additional
  candidates. Investigated discrepancy groups overlapped and did not establish
  a single cause.

Treat these as reported observations to reproduce and investigate, not proven
causes or guarantees. Any refresh should align time cut-offs and population
snapshots before interpreting differences.

## Troubleshooting and disablement

| Symptom | Checks and response |
| --- | --- |
| Snapshot is empty, partial or unexpectedly small | Check approved organisation scope, GitHub App installation/permissions, API pagination, rate limits, error logs and completion manifest. Mark the run incomplete; do not publish or replace the last known-good snapshot. |
| Users or teams are missing | Check membership type coverage, team pagination and organisation access. Compare unique GitHub user IDs and per-organisation counts with an independently approved source. Do not infer that missing users are dormant. |
| Repository push rules disagree | Confirm the repository visibility snapshot and its as-of time; inspect actual event properties and programmatic access type. Preserve the discrepancy for rule review rather than silently changing the filter. |
| Athena query returns no or too few events | Check production workspace resources, catalog database/table, projected `datehour` values, S3 path layout, UTC boundaries, timestamp units and event schema. Confirm the selected period is within available retained history. |
| Athena query fails, scans too much or exceeds cutoff | Inspect query execution state and error, partition predicates, workgroup configuration and scan metrics. Narrow the date/column scope or improve the query; do not bypass the workgroup cutoff without approval. |
| Report shows unexplained candidates | Check snapshot/report scope alignment, missing actor IDs, audit coverage, late or unavailable events, rule exclusions and the limitations above. Escalate unresolved differences for human review. A candidate result is not proof of dormancy. |
| Output is missing or incomplete | Check Lambda invocation, Athena completion, output permissions, KMS key access, upload verification and completion marker. Keep the last known-good report; investigate before retrying the same run ID. |

To disable the proposed workflow, use the approved operational control to
disable its schedule/invoker first, then prevent further report publication
without deleting the existing audit-log pipeline, source logs, Glue table or
Athena workgroup. Preserve prior reports and run metadata according to the
approved retention policy. Revoke or rotate the report-specific GitHub
credential and remove report-role access only through reviewed change
management. Do not delete source audit data or shared resources as a rollback
step. Record the disablement reason, owner and re-enable approval path.

## Source references

- [Active GitHub audit-log stream Terraform component](./)
- [Athena, Glue database/table and query-results bucket](./athena.tf)
- [Audit-log S3 bucket, policy and retention](./s3-buckets.tf)
- [Audit-log uploader role](./iam-roles.tf)
- [OIDC provider](./iam-oidc-providers.tf)
- [Component KMS key](./kms-keys.tf)
- [Network and subnet data lookups](./platform_data.tf)
- [Issue #331 and prototype handover](https://github.com/ministryofjustice/developer-experience/issues/331)
