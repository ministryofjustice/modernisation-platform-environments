module "coat-cur-data-pipeline" {
  source  = "ministryofjustice/repository/github"
  version = "1.2.1"

  poc = false

  name        = "coat-cur-data-pipeline"
  description = "A GitHub repository for the Cloud Optimisation and Accountability Team Cost and Usage Report Data Pipeline "
  topics      = ["cloud-optimisation-and-accountability"]

  homepage_url = "https://cloud-optimisation-and-accountability.justice.gov.uk/"

  team_access = {
    admin = [var.cloud_optimisation_and_accountability_team_id]
  }

  template = {
    "owner" : "ministryofjustice",
    "repository" : "analytical-platform-airflow-python-template"
  }
}
