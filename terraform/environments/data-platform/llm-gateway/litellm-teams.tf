# resource "litellm_team" "test_team" {
#   count = terraform.workspace == "data-platform-development" ? 1 : 0

#   team_alias = "test"
#   models     = ["azure-gpt-5"]
# }
