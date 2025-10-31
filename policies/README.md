# Open Policy Agent

We use [Conftest](https://www.conftest.dev/) and [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) to test json files and policies.

## Setup
[Install Conftest](https://www.conftest.dev/install/)

## Run the tests

This runs the OPA tests against each terraform file in the [terraform](../terraform) folder against the relevant policy folder.

[scripts/tests/validate/run-opa-tests.sh](../scripts/tests/validate/run-opa-tests.sh)

## Run the test unit tests

These verify that the tests are running as expected.

`conftest verify -p policies/terraform`

`conftest verify -p policies/terraform`
