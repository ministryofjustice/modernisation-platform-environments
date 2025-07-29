module "cloud-optimisation-and-accountability" {
  source  = "ministryofjustice/repository/github"
  version = "1.2.1"

  poc = false

  name        = "cloud-optimisation-and-accountability"
  description = "A GitHub repository for the Cloud Optimisation and Accountability Team"
  topics      = ["cloud-optimisation-and-accountability"]

  homepage_url = "https://cloud-optimisation-and-accountability.justice.gov.uk/"

  team_access = {
    admin = [var.cloud_optimisation_and_accountability_team_id]
  }
}
