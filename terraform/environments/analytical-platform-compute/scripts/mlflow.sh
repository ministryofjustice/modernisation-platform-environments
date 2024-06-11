#!/usr/bin/env bash

echo "(i) Helm template"

helm template mlflow \
  --values ./src/helm/values/mlflow/values.yml \
  ./src/helm/charts/mlflow

helm upgrade --install mlflow \
  --namespace mlflow \
  --values ./src/helm/values/mlflow/values.yml \
  ./src/helm/charts/mlflow