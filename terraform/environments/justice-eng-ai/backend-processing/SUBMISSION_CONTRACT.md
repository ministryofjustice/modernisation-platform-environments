# Explicit submission handoff

Deploy the companion application-builder consumers/resolver before applying this workflow change. Enable #44's immutable producer only after both old and new fixtures have been tested in development.

The S3 trigger already passes the complete key. The new resolver child workflow runs on the existing Fargate script runner before any DynamoDB lookup. It reads the configured staging bucket and event key, validates package identifiers against the exact submitted `(AppID, SysKey)` event, and emits `submission` into its output. No application ID is inferred from the filename.

All processing stages receive AppID, numeric BuildID, Forge UUID, SUBMISSION_ID, complete S3 key, hash, version and assurance via the shared `submission_environment` local. IDs are strings when passed as ECS environment values. The approval status comes from the scoped control-plane script output, not the latest unrelated application event.

New waiting events and resume queries bind approval to SubmissionID and SourceSha256. Administrators/review tools must copy these fields from the waiting event into approval/rejection events. Missing fields do not fall back to an unbound approval. Do not apply this wiring until the review mechanism can provide them.

Legacy flat packages with matching identifiers but no recorded hash are explicitly held for human review by the companion code. Missing/partial evidence stops. Repeated or newer submissions cannot be substituted by a latest-event lookup. The existing folder/file readers remain in the consumer code for older workflow invocations during rollout.

Local validation uses mocked Terraform module plans and mocked S3/DynamoDB consumer tests. No backend state, infrastructure or live workflow is changed by running the module tests. A coordinated development apply and end-to-end acceptance test remain required. Image digest provenance and the unfinished infrastructure deployment implementation are not delivered by this compatibility change.
