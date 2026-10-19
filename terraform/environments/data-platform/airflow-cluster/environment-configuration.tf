locals {
  environment_configurations = {
    test = {
      eks_public_access_cidrs = [
        "0.0.0.0/0", # Any IP: needed for Github-Hosted runners currently used in analytical-platform-airflow DAG deployments
      ]
    }
  }
}
