module "ministryofjustice" {
  source = "./ministryofjustice"

  cloud_optimisation_and_accountability_team_id = data.github_team.cloud_optimisation_and_accountability.id
}

