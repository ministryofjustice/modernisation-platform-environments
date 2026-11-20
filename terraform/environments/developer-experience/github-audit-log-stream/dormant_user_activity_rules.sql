-- Translated Athena rules baseline for dormant-user candidate identification.
-- This query is not live-validated. Verify the Glue schema, timestamp units,
-- event properties, partition values, query parameters, and all predicates
-- against authorised production records before use.
--
-- Athena execution parameters, in order:
--   1. Complete population snapshot run ID (VARCHAR)
--   2. Exclusive report cutoff, ISO-8601 with UTC offset (TIMESTAMP WITH TIME ZONE)
--   3. Inclusive lower datehour partition bound, UTC yyyy/MM/dd/HH (VARCHAR)
--   4. Exclusive upper datehour partition bound, UTC yyyy/MM/dd/HH (VARCHAR)
--   5. Whether to count SAML SSO events (BOOLEAN; prototype default TRUE)
--   6. Window length in days (INTEGER; prototype default 30)
--
-- The population table is a proposed prerequisite, not a resource in the
-- current Terraform component. Its columns are snapshot_run_id, user_id,
-- login, and org. It must contain only the approved, complete population.
-- The approved account allowlist is a second proposed table with user_id,
-- owner, and reason columns; matching and exclusion use stable user_id.
-- The repository-visibility snapshot is a third proposed table with
-- snapshot_run_id, repo, and visibility columns. It reflects snapshot-time
-- visibility, not necessarily visibility when a historical push occurred.
-- Audit events are evaluated across the enterprise business scope; org
-- membership is reported from the population snapshot, not used to filter
-- enterprise-wide activity.
-- Only actions in rule_actions can qualify. API requests, workflow runs,
-- issue activity, private-repository Git operations, and all other unmapped
-- actions do not independently establish qualifying activity.
WITH
parameters AS (
    SELECT
        CAST(? AS VARCHAR) AS snapshot_run_id,
        from_iso8601_timestamp(?) AS cutoff_utc,
        CAST(? AS VARCHAR) AS datehour_start,
        CAST(? AS VARCHAR) AS datehour_end,
        CAST(? AS BOOLEAN) AS include_sso,
        CAST(? AS INTEGER) AS window_days
),
rule_catalog (rule_id, rule_name, observable, limitation) AS (
    VALUES
        ('R01_saml_sso', 'Authenticating via SAML SSO', TRUE, 'org.sso_response; success is not recorded'),
        ('R02_repo_create', 'Creating a repository', TRUE, 'repo.create'),
        ('R03_push_internal_https', 'Pushing to an internal repository via HTTPS', TRUE, 'git.push; internal visibility and HTTP or HTTPS transport required'),
        ('R04_added_to_repo', 'Being added to a repository', TRUE, 'repo.add_member; credited to the added user'),
        ('R05_repo_visibility', 'Changing the visibility of a repository', TRUE, 'repo.access'),
        ('R06_pr_create', 'Creating a pull request', TRUE, 'pull_request.create'),
        ('R07_pr_comment', 'Commenting on a pull request', TRUE, 'pull_request_review.submit is a proxy; plain conversation comments are not logged'),
        ('R08_close_reopen', 'Closing or reopening an issue or pull request', TRUE, 'pull_request.close and pull_request.reopen only; issue close and reopen are not logged'),
        ('R09_labels', 'Applying or removing a label', FALSE, 'No audit-log event'),
        ('R10_assign', 'Assigning or unassigning an issue or pull request', FALSE, 'No audit-log event'),
        ('R11_review_request', 'Requesting or removing a review request', TRUE, 'pull_request.create_review_request and pull_request.remove_review_request'),
        ('R12_review_comment', 'Creating or editing a pull-request review comment', TRUE, 'pull_request_review_comment.create and pull_request_review_comment.update'),
        ('R13_dismiss_review', 'Dismissing a comment in a pull request', TRUE, 'pull_request_review.dismiss is a proxy'),
        ('R14_pr_synchronize', 'Synchronizing a pull request', FALSE, 'No audit-log event'),
        ('R15_commit_comment', 'Commenting on a commit', TRUE, 'commit_comment.update only; creation is not logged'),
        ('R16_release_publish', 'Publishing a release', FALSE, 'No audit-log event'),
        ('R17_wiki_push', 'Pushing to a wiki', FALSE, 'No audit-log event'),
        ('R18_star_repo', 'Starring a repository', FALSE, 'No audit-log event'),
        ('R19_repo_delete', 'Deleting a repository', TRUE, 'repo.destroy'),
        ('R20_join_org', 'Joining an organisation', TRUE, 'org.add_member; credited to the added user')
),
rule_actions (rule_id, action, subject_type) AS (
    VALUES
        ('R01_saml_sso', 'org.sso_response', 'actor'),
        ('R02_repo_create', 'repo.create', 'actor'),
        ('R03_push_internal_https', 'git.push', 'actor'),
        ('R04_added_to_repo', 'repo.add_member', 'user'),
        ('R05_repo_visibility', 'repo.access', 'actor'),
        ('R06_pr_create', 'pull_request.create', 'actor'),
        ('R07_pr_comment', 'pull_request_review.submit', 'actor'),
        ('R08_close_reopen', 'pull_request.close', 'actor'),
        ('R08_close_reopen', 'pull_request.reopen', 'actor'),
        ('R11_review_request', 'pull_request.create_review_request', 'actor'),
        ('R11_review_request', 'pull_request.remove_review_request', 'actor'),
        ('R12_review_comment', 'pull_request_review_comment.create', 'actor'),
        ('R12_review_comment', 'pull_request_review_comment.update', 'actor'),
        ('R13_dismiss_review', 'pull_request_review.dismiss', 'actor'),
        ('R15_commit_comment', 'commit_comment.update', 'actor'),
        ('R19_repo_delete', 'repo.destroy', 'actor'),
        ('R20_join_org', 'org.add_member', 'user')
),
population AS (
    SELECT
        CAST(s.user_id AS BIGINT) AS user_id,
        MAX(s.login) AS login,
        array_join(array_sort(array_agg(DISTINCT s.org)), ';') AS organisations
    FROM github_audit_logs.report_population_snapshot AS s
    CROSS JOIN parameters AS p
    WHERE s.snapshot_run_id = p.snapshot_run_id
    GROUP BY CAST(s.user_id AS BIGINT)
),
allowlisted_users AS (
    SELECT DISTINCT CAST(user_id AS BIGINT) AS user_id
    FROM github_audit_logs.report_user_allowlist
    WHERE user_id IS NOT NULL
),
repo_visibility AS (
    SELECT
        LOWER(v.repo) AS repo,
        MAX(LOWER(v.visibility)) AS visibility
    FROM github_audit_logs.report_repository_visibility AS v
    CROSS JOIN parameters AS p
    WHERE v.snapshot_run_id = p.snapshot_run_id
    GROUP BY LOWER(v.repo)
    HAVING COUNT(DISTINCT LOWER(v.visibility)) = 1
),
audit_events AS (
    SELECT
        e.*,
        LOWER(COALESCE(e.visibility, rv.visibility)) AS effective_visibility,
        from_unixtime(CAST(e.event_timestamp AS DOUBLE) / 1000.0, 'UTC') AS event_time_utc
    FROM github_audit_logs.enterprise_audit_logs AS e
    CROSS JOIN parameters AS p
    LEFT JOIN repo_visibility AS rv
        ON LOWER(e.repo) = rv.repo
    WHERE e.business IN ('ministry-of-justice-uk', 'Ministry of Justice (UK)')
      AND e.datehour >= p.datehour_start
      AND e.datehour < p.datehour_end
      AND e.event_timestamp >= CAST(
          to_unixtime(date_add('day', -p.window_days, p.cutoff_utc)) * 1000 AS BIGINT
      )
      AND e.event_timestamp < CAST(to_unixtime(p.cutoff_utc) * 1000 AS BIGINT)
),
qualifying_events AS (
    SELECT
        ra.rule_id,
        CAST(
            CASE ra.subject_type
                WHEN 'actor' THEN e.actor_id
                ELSE e.user_id
            END AS BIGINT
        ) AS subject_id,
        e.event_time_utc
    FROM audit_events AS e
    INNER JOIN rule_actions AS ra
        ON ra.action = e.action
    INNER JOIN rule_catalog AS r
        ON r.rule_id = ra.rule_id
       AND r.observable
    CROSS JOIN parameters AS p
    WHERE (r.rule_id <> 'R01_saml_sso' OR p.include_sso)
      AND (
          ra.subject_type <> 'actor'
          OR (
              NOT COALESCE(e.actor_is_bot, FALSE)
              AND NOT COALESCE(e.actor_is_agent, FALSE)
              AND LOWER(COALESCE(e.programmatic_access_type, '')) NOT LIKE '%personal access token%'
              AND LOWER(COALESCE(e.programmatic_access_type, '')) NOT LIKE 'public key%'
              AND LOWER(COALESCE(e.programmatic_access_type, '')) NOT LIKE 'github app%'
          )
      )
      AND (
          e.action <> 'git.push'
          OR (
              LOWER(e.transport_protocol_name) IN ('http', 'https')
              AND NOT COALESCE(e.repository_public, FALSE)
              AND e.effective_visibility = 'internal'
          )
      )
      AND CASE ra.subject_type
          WHEN 'actor' THEN e.actor_id
          ELSE e.user_id
      END IS NOT NULL
),
activity AS (
    SELECT
        subject_id,
        COUNT(DISTINCT rule_id) AS rules_satisfied,
        array_join(array_sort(array_agg(DISTINCT rule_id)), ';') AS rules_satisfied_list,
        COUNT(*) AS qualifying_events_in_window
    FROM qualifying_events
    GROUP BY subject_id
),
observable_rule_count AS (
    SELECT COUNT(*) AS rule_count
    FROM rule_catalog AS r
    CROSS JOIN parameters AS p
    WHERE r.observable
      AND (r.rule_id <> 'R01_saml_sso' OR p.include_sso)
),
excluded_counts AS (
    SELECT
        CAST(e.actor_id AS BIGINT) AS subject_id,
        SUM(
            CASE
                WHEN LOWER(COALESCE(e.programmatic_access_type, '')) LIKE '%personal access token%'
                  OR LOWER(COALESCE(e.programmatic_access_type, '')) LIKE 'public key%'
                  OR LOWER(COALESCE(e.programmatic_access_type, '')) LIKE 'github app%'
                THEN 1 ELSE 0
            END
        ) AS excluded_token_ssh_app_events,
        SUM(
            CASE
                WHEN (e.action LIKE 'git.%')
                 AND NOT (
                     e.action = 'git.push'
                     AND LOWER(e.transport_protocol_name) IN ('http', 'https')
                     AND NOT COALESCE(e.repository_public, FALSE)
                     AND e.effective_visibility = 'internal'
                 )
                THEN 1 ELSE 0
            END
        ) AS excluded_git_ops_events,
        SUM(
            CASE
                WHEN e.action LIKE 'issue.%'
                  OR e.action LIKE 'issues.%'
                  OR e.action LIKE 'issue_comment.%'
                THEN 1 ELSE 0
            END
        ) AS excluded_issue_events
    FROM audit_events AS e
    WHERE e.actor_id IS NOT NULL
    GROUP BY CAST(e.actor_id AS BIGINT)
)
SELECT
    p.user_id,
    p.login,
    p.organisations,
    COALESCE(a.rules_satisfied, 0) AS rules_satisfied,
    r.rule_count AS observable_rule_count,
    100.0 * COALESCE(a.rules_satisfied, 0) / r.rule_count AS rule_coverage_percent,
    COALESCE(a.rules_satisfied_list, '') AS rules_satisfied_list,
    COALESCE(a.qualifying_events_in_window, 0) AS qualifying_events_in_window,
    'dormant_candidate' AS activity_status,
    COALESCE(x.excluded_token_ssh_app_events, 0) AS excluded_token_ssh_app_events,
    COALESCE(x.excluded_git_ops_events, 0) AS excluded_git_ops_events,
    COALESCE(x.excluded_issue_events, 0) AS excluded_issue_events,
    pms.cutoff_utc AS cutoff_utc,
    pms.window_days AS window_days
FROM population AS p
CROSS JOIN observable_rule_count AS r
CROSS JOIN parameters AS pms
LEFT JOIN activity AS a
    ON a.subject_id = p.user_id
LEFT JOIN excluded_counts AS x
    ON x.subject_id = p.user_id
LEFT JOIN allowlisted_users AS al
    ON al.user_id = p.user_id
WHERE COALESCE(a.rules_satisfied, 0) = 0
  AND al.user_id IS NULL
ORDER BY p.login, p.user_id;
