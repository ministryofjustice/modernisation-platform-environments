# Recovering failed Step Functions executions

This runbook covers failed executions of the Integration Hub file-transfer workflows:

- `filereceived-workflow`, which moves an exact version from `incoming` to `processing` and uses the `STAGE` operation.
- `filescanresultrecorded-workflow`, which moves an exact version from `processing` to its routing destination and uses the `ROUTE` operation.

These workflows deliberately do not maintain custom recovery or resume state. Recovery uses either native Step Functions redrive or a controlled reset and replay.

## Choose the recovery method

### Native redrive

Use native redrive when the deployed workflow definition did not need to change. Suitable examples include:

- temporary AWS service errors;
- throttling; or
- a transient EventBridge publication failure.

A redriven execution retains its original execution ARN, input and state-machine definition. It resumes from the unsuccessful state and does not adopt a definition deployed after the original execution started.

Do not use native redrive to recover from a defect in ASL, JSONata, state transitions or service-integration arguments. It will execute the same faulty definition again.

### Reset and replay

Use reset and replay when a code or definition correction must be picked up by a new execution.

Reset and replay is safe only when all of the following are true:

- the failed execution is no longer running;
- the exact source object version still exists;
- the DynamoDB operation record is still owned by the failed execution and has status `IN_PROGRESS`; and
- the failed attempt did not create a completed destination object version, or that version has been identified and handled deliberately.

Do not reset and replay after `Delete Exact Source Version` has succeeded. The original input then refers to an object version that no longer exists.

A failure before `Complete Multipart Upload` is normally safe to replay. An incomplete multipart upload may remain, but the S3 lifecycle rule will abort it. A failure after `Complete Multipart Upload` may have created a destination version; replaying without checking can create an additional version.

## Prerequisites

The commands below require:

- AWS CLI v2;
- `jq`;
- permission to inspect Step Functions and S3;
- permission to read and conditionally delete the workflow idempotency record; and
- permission to start a new Step Functions execution.

Run the commands from a trusted operator workstation. Replace every value in angle brackets before continuing.

```zsh
region="eu-west-2"
account_id="<aws-account-id>"
environment="<development|test|preproduction|production>"
execution_arn="<failed-execution-arn>"

state_machine_arn="arn:aws:states:${region}:${account_id}:stateMachine:${environment}-filereceived-workflow"
table_name="integration-hub-file-transfer-${environment}-file-transfer-idempotency"
operation="STAGE"
```

For the routing workflow, use:

```zsh
state_machine_arn="arn:aws:states:${region}:${account_id}:stateMachine:${environment}-filescanresultrecorded-workflow"
operation="ROUTE"
```

## 1. Confirm the correction is deployed

Inspect the deployed definition and confirm that it contains the intended correction:

```zsh
  aws stepfunctions describe-state-machine \
    --region "$region" \
    --state-machine-arn "$state_machine_arn" \
    --query definition \
    --output text
```

Do not clear the idempotency record until the deployed definition has been checked.

## 2. Inspect the failed execution

```zsh
execution=$(
    aws stepfunctions describe-execution \
      --region "$region" \
      --execution-arn "$execution_arn" \
      --output json
)

jq . <<< "$execution"
jq -e '.status == "FAILED" or .status == "TIMED_OUT" or .status == "ABORTED"' <<< "$execution"
```

Review the execution in the Step Functions console or retrieve its recent history:

```zsh
aws stepfunctions get-execution-history \
  --region "$region" \
  --execution-arn "$execution_arn" \
  --reverse-order \
  --max-results 100 \
  --output json
```

Establish the last successful state and whether `Complete Multipart Upload` or `Delete Exact Source Version` succeeded.

Stop and investigate rather than replay if:

- source deletion succeeded;
- destination completion succeeded but the created destination version has not been accounted for; or
- the execution history does not establish the side effects clearly.

## 3. Recover the original event and identifiers

The new execution must receive the complete original EventBridge event:

```zsh
input=$(jq -r '.input' <<< "$execution")

correlation_id=$(jq -r '.detail.metadata.correlationId' <<< "$input")
source_bucket=$(jq -r '.detail.data.object.bucket' <<< "$input")
source_key=$(jq -r '.detail.data.object.key' <<< "$input")
source_version_id=$(jq -r '.detail.data.object.versionId' <<< "$input")

jq -e \
  '.detail.metadata.correlationId
   and .detail.data.object.bucket
   and .detail.data.object.key
   and .detail.data.object.versionId' \
  <<< "$input"
```

Do not reconstruct a smaller event manually. The existing event ID, correlation ID and exact S3 version are part of the workflow contract.

## 4. Confirm the exact source version still exists

```zsh
aws s3api head-object \
  --region "$region" \
  --bucket "$source_bucket" \
  --key "$source_key" \
  --version-id "$source_version_id" \
  --expected-bucket-owner "$account_id"
```

Stop if this fails. Resetting the claim cannot make a deleted source version replayable.

## 5. Inspect the idempotency record

Build the composite DynamoDB key:

```zsh
key=$(
  jq -nc \
    --arg correlation_id "$correlation_id" \
    --arg operation "$operation" \
    '{
      concurrencyId: {S: $correlation_id},
      operation: {S: $operation}
    }'
)
```

Read the record consistently:

```zsh
record=$(
  aws dynamodb get-item \
    --region "$region" \
    --table-name "$table_name" \
    --key "$key" \
    --consistent-read \
    --output json
)

jq . <<< "$record"
```

Confirm that the claim is still `IN_PROGRESS` and belongs to the failed execution:

```zsh
jq -e \
  --arg execution_arn "$execution_arn" \
  '.Item.status.S == "IN_PROGRESS"
   and .Item.execution_arn.S == $execution_arn' \
  <<< "$record"
```

Stop if the assertion fails. Another execution may own the operation, or the operation may already have completed.

## 6. Conditionally remove the stale claim

The condition prevents removal if ownership or status changed after the preceding read:

```zsh
expression_values=$(
  jq -nc \
    --arg execution_arn "$execution_arn" \
    '{
      ":execution_arn": {S: $execution_arn},
      ":in_progress": {S: "IN_PROGRESS"}
    }'
)

removed_record=$(
  aws dynamodb delete-item \
    --region "$region" \
    --table-name "$table_name" \
    --key "$key" \
    --condition-expression \
      'execution_arn = :execution_arn AND #status = :in_progress' \
    --expression-attribute-names \
      '{"#status":"status"}' \
    --expression-attribute-values "$expression_values" \
    --return-values ALL_OLD \
    --output json
)

jq -e '.Attributes.status.S == "IN_PROGRESS"' <<< "$removed_record"
```

If DynamoDB reports `ConditionalCheckFailedException`, do not retry the deletion without inspecting the record again.

## 7. Start a new execution

Use a new execution name and the original event input. The new execution will use the latest deployed state-machine definition:

```zsh
execution_name="manual-replay-$(date -u +%Y%m%dT%H%M%SZ)-$RANDOM"

replacement=$(
  aws stepfunctions start-execution \
    --region "$region" \
    --state-machine-arn "$state_machine_arn" \
    --name "$execution_name" \
    --input "$input" \
    --output json
)

jq . <<< "$replacement"
```

Record the new execution ARN.

## 8. Monitor the replacement execution

```zsh
replacement_execution_arn=$(jq -r '.executionArn' <<< "$replacement")

aws stepfunctions describe-execution \
  --region "$region" \
  --execution-arn "$replacement_execution_arn" \
  --output json
```

Confirm that the workflow reaches `SUCCEEDED`, that the expected canonical event is published, and that the DynamoDB operation record reaches `COMPLETED`.

## Incomplete multipart uploads

A failure after `Create Multipart Upload` can leave an incomplete upload. This does not create a visible S3 object version and does not block a replacement execution. The configured S3 lifecycle rules abort incomplete multipart uploads after one day.

Do not manually abort an upload unless its upload ID has been positively associated with the failed execution. A replacement execution may be using a different active upload for the same object key.

## Recovery boundaries

Use reset and replay only as a controlled response to a known failure. It is not a general substitute for idempotency or for native redrive.

| Failure point | Preferred recovery |
| --- | --- |
| Temporary service error, throttling or corrected IAM permission | Native redrive |
| Definition or JSONata defect before multipart completion | Reset and replay after deploying the correction |
| Failure after multipart completion but before source deletion | Inspect and account for the destination version before replay |
| Failure after exact source deletion | Do not replay from the original event; investigate destination state and recover operationally |
| Operation record is `COMPLETED` | Do not remove the record or replay |

When there is doubt about whether an irreversible state succeeded, preserve the DynamoDB claim and investigate rather than creating another execution.
