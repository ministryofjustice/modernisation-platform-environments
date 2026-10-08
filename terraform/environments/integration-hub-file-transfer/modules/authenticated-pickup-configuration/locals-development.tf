locals {
  development = {
    # Notification-only API trial; download access remains disabled.
    products-poc-slack-test = {
      prefix           = "products-poc/uploads/"
      groups           = []
      slack_channel_id = "C0ARA0C101L" # integration-hub-team
      slack_team_id    = "T02DYEB3A"   # Justice Digital
    }
  }
}
