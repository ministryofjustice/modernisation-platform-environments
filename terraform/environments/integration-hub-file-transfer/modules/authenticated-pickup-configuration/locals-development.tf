locals {
  development = {
    # API trial: the existing integration-hub group may read the pickup directory.
    products-poc-slack-test = {
      prefix           = "products-poc/uploads/"
      groups           = ["integration-hub"]
      slack_channel_id = "C0ARA0C101L" # integration-hub-team
      slack_team_id    = "T02DYEB3A"   # Justice Digital
    }
  }
}
