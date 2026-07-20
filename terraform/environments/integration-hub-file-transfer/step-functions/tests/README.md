# Keeping the Step Functions test fixtures up to date

This directory holds the fixtures used by the `test-step-functions` job in
[integration-hub-file-transfer.yml](../../../../.github/workflows/integration-hub-file-transfer.yml)
to exercise individual states from
[file-transfer-workflow.asl.json](../file-transfer-workflow.asl.json)
using the AWS Step Functions
[`TestState`](https://docs.aws.amazon.com/step-functions/latest/apireference/API_TestState.html)
API.

The purpose of this guide is to explain what each fixture is for, how they relate to
one another, and what to check whenever the workflow definition changes.

## Why fixtures live here, not in the workflow

`TestState` can only test one state at a time, and it needs that state's
definition, input and variables supplied as plain JSON — it cannot resolve the
`${...}` placeholders that Terraform's `templatefile()` fills in when the real
state machine is deployed (account ID, bucket names, KMS key ARNs, and so on).

Rather than have the GitHub Actions workflow render those placeholders with
made-up test values, every value a test needs is committed here as JSON. The
workflow only wires these files into `aws stepfunctions test-state`; it does
not construct or substitute any test data itself. Keeping test data out of the
workflow file means:

- fixtures can be reviewed and diffed like any other test data
- adding a new test does not require editing the workflow YAML
- there's a single, obvious place to update when a state's contract changes

## File-naming convention

Each tested state has three files:

| File | Purpose |
|---|---|
| `<state-name>.definition.json` | The standalone ASL definition of **one** state, copied verbatim from `file-transfer-workflow.asl.json` |
| `<state-name>.input.json` | The `$states.input` the state should be tested with (typically an EventBridge event) |
| `<state-name>.variables.json` | The JSONata workflow variables (`$variableName`) the state under test dereferences |

For example, the `Copy Incoming Object` state has:

- [copy-incoming-object.definition.json](copy-incoming-object.definition.json)
- [copy-incoming-object.input.json](copy-incoming-object.input.json)
- [copy-incoming-object.variables.json](copy-incoming-object.variables.json)

## `<state-name>.definition.json`

This must be an exact copy of the state's object from the `States` map in
`file-transfer-workflow.asl.json`, with one addition: a top-level
`"QueryLanguage": "JSONata"` property. The full workflow declares
`QueryLanguage` once at the machine level and every state inherits it, but
`TestState` needs it set explicitly on a standalone state definition.

Whenever the source state changes, copy the updated state body across again.
Do not hand-edit the copy — if the two drift apart, the test stops being
meaningful because it is no longer testing what will actually be deployed.

Only states without unresolved `${...}` Terraform placeholders can be tested
this way. `Copy Incoming Object` qualifies because its `Bucket`, `Key` and
similar values all come from JSONata variables (`$processingBucket`, and so
on) rather than Terraform interpolation.

## `<state-name>.input.json`

This is the JSON that would be present in `$states.input` when the state
under test runs. For states early in the workflow (like `Initialise`), this
is the raw EventBridge event. For states further down the chain, `$states.input`
may be irrelevant if the state only reads assigned variables — in that case
this file can be an empty object `{}`, but it must still exist and be valid
JSON.

When the shape of the upstream event changes (for example, a new field is
added to `FileReceived.v1`), update this file to match the corresponding
schema in [../../schemas](../../schemas).

## `<state-name>.variables.json`

This supplies every JSONata variable (`$variableName`) that the state's
`Arguments`/`Condition`/`Assign` expressions dereference. If the state
references a variable that isn't a key in this file, `TestState` will fail
or return `null` for that value.

When you change what a state reads:

1. Re-read the state's JSONata expressions and list every `$variableName` it
   uses.
2. Confirm each one is present in the fixture, with a realistic value of the
   correct type (string, number, object, array).
3. Remove variables the state no longer reads — an unused fixture value isn't
   harmful, but it does mislead the next person into thinking it's exercised.

## Checklist when the ASL definition changes

Whenever `file-transfer-workflow.asl.json` changes, check whether it affects
any state that already has fixtures here:

- [ ] Did the state's `Type`, `Resource`, `Arguments`, `Assign` or `Catch`
      change? If so, copy the updated state body into
      `<state-name>.definition.json`.
- [ ] Did the set of `$variableName` references in the state change? If so,
      add, update or remove entries in `<state-name>.variables.json`.
- [ ] Does the state read `$states.input`? If the upstream event shape
      changed, update `<state-name>.input.json` to match.
- [ ] If a **new** state needs coverage, create its three fixture files
      following the naming convention above, then add a step to the
      `test-step-functions` job in the workflow that calls `test-state`
      with `--definition`, `--input` and `--variables` pointing at the new
      files (and a `--mock` if the state calls an AWS SDK action).

## Running a test locally

Each state test can be run without needing GitHub Actions, provided you have
sufficient AWS credentials available to you:

```bash
aws stepfunctions test-state \
  --definition file://terraform/environments/integration-hub-file-transfer/step-functions/tests/copy-incoming-object.definition.json \
  --input file://terraform/environments/integration-hub-file-transfer/step-functions/tests/copy-incoming-object.input.json \
  --variables file://terraform/environments/integration-hub-file-transfer/step-functions/tests/copy-incoming-object.variables.json \
  --mock '{"result": "{\"VersionId\": \"test-processing-version-id\"}", "fieldValidationMode": "NONE"}' \
  --inspection-level DEBUG \
  --no-cli-pager
```

A successful test returns `"status": "SUCCEEDED"`. Anything else — including
a validation error about a missing variable — means a fixture is out of date
with the state it's meant to test.
