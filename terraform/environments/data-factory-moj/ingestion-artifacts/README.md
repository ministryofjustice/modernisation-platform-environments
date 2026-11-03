# Ingestion artifacts

This component stores the packages we deploy as part of the ingestion
pipeline, starting with the DMS runtime controller Lambda.

It is only enabled in development for now.

The bucket is shared, so we can add packages for other ingestion components
without creating a new bucket each time.

## What we store here

- Lambda ZIP files that have passed the CI checks
- Build details, including the source commit and package checksum
- Other deployment files if we need them later

Contracts, service configuration and extracted data stay separate.
Ingestion progress is kept in the Ingestion Registry.

## How packages are organised

Each package is stored under its component name, source commit and checksum:

    lambda/<adapter>/<source-commit>/<zip-sha256>/package.zip
    lambda/<adapter>/<source-commit>/<zip-sha256>/artifact-metadata.json

This lets us see where a package came from and check that we are deploying
the file that CI built.

Deployments use the exact S3 object version and checksum rather than a
latest.zip file that could change underneath us.

## Keeping the files safe

Public access is blocked and connections must use HTTPS. Packages are
encrypted using a dedicated KMS key, with key rotation enabled.

Bucket versioning keeps previous versions when a file is overwritten.
It does not stop someone with the right permissions from deleting them.

Access logs go into a separate bucket. We have not added automatic deletion
rules yet, so packages and logs stay there until we agree how long to keep
them.

Terraform also has protection against accidentally deleting the buckets
and encryption key while their resource definitions remain in place.

## Uploading and deploying

Terraform creates the storage. It does not build or upload the packages.

The publishing process will upload the tested package and its build details.
The deployment process will then use that exact uploaded version.

The Lambda itself does not need access to the ZIP it was deployed from.

## Publishing permissions

A dedicated GitHub Actions role allows the modules repository's
integration/data-hub-modularisation branch to publish runtime packages.

It can upload and read files under lambda/dms-runtime-controller/ in the
artifact bucket and use the encryption key through S3.

It cannot delete packages, change infrastructure or start ingestion.
Other adapters will need their publishing permissions added explicitly.

The publishing workflow will be connected separately.