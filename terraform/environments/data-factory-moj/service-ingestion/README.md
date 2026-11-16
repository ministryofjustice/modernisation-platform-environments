# Service ingestion

This component deploys ingestion resources from service YAML files.

It uses the shared `configured-ingestion` module, so adding a service
doesn't require copying Terraform blocks.

For now, deployments are limited to development in `eu-west-2`.

## What it creates

- Source and target endpoints
- DMS tasks for the configured table groups
- Runtime Lambdas that check and control those tasks
- The permissions and logs those resources need

Deploying these resources does not start ingestion or approve contracts.

## What it reuses

Other components provide the shared resources:

- `dms-core`: the sandbox databases and shared replication capacity
- `ingestion-registry`: the Registry table and configuration storage
- `ingestion-artifacts`: the tested Lambda packages

Those resources stay managed by their existing components. This component
does not take over the existing sandbox tasks or endpoints.

## How configuration is used

The service YAML describes what to ingest. Platform settings supply the
network, storage, capacity and secret references for the environment.

The preparation step checks the configuration and turns it into deployment
inputs. It also carries forward previous extraction generations and their
capacity assignments.

Passwords and other credential values must not be included in the YAML
or generated inputs. Generated inputs must not be committed.

If the development inputs are missing, deployment must fail rather than
assume there are no services to deploy.

## After deployment

The deployed resource references are checked against the configuration
before versioned configuration and deployment documents are published.

An ingestion run should only use a revision once that publication has
completed successfully.