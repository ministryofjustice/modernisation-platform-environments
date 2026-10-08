locals {
  development = {
    # Notification-only API trial in #integration-hub-team. Configure the channel's
    # incoming webhook in the generated secret; no download access is granted yet.
    products-poc-slack-test = {
      prefix = "products-poc/uploads/"
      groups = []
    }
  }
}
