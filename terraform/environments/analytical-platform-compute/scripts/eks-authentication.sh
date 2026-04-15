#!/usr/bin/env bash

# This scripts exists because the Terraform Kubernetes provider does not pass assumed credentials from the default AWS provider

EKS_CLUSTER_NAME=${1}

aws eks get-token --cluster-name "${EKS_CLUSTER_NAME}"
