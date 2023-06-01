##################################################
# Airflow
##################################################

variable "airflow_version" {
  type        = string
  description = "Version of Airflow to deploy"
}

variable "airflow_environment_class" {
  type        = string
  description = "Environment class of Airflow to deploy"
}

variable "airflow_dag_s3_path" {
  type        = string
  description = "Path to DAGs in S3 bucket"
  default     = "dags/"
}
