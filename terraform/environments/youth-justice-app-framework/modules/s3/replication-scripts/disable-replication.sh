#!/bin/sh

aws s3api delete-bucket-replication --bucket yjaf-prod-bands
aws s3api delete-bucket-replication --bucket yjaf-prod-bedunlock
aws s3api delete-bucket-replication --bucket yjaf-prod-cmm
aws s3api delete-bucket-replication --bucket yjaf-prod-cms
aws s3api delete-bucket-replication --bucket yjaf-prod-mis
aws s3api delete-bucket-replication --bucket yjaf-prod-reporting
aws s3api delete-bucket-replication --bucket yjsm-prod-artefact
aws s3api delete-bucket-replication --bucket yjaf-prod-yjsm
