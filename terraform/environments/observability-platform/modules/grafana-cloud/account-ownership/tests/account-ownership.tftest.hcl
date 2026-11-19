mock_provider "http" {}

run "canonical_application_matching" {
  command = plan

  variables {
    enabled = true
    accounts = [
      "modernisation-platform-development",
      "cloud-platform-development",
      "container-platform-hmpps-nonlive",
      "other-development",
      "missing-development",
      "undeclared-development",
      "collision-development",
    ]
    modernisation_platform_account_names = [
      "modernisation-platform-development",
      "cloud-platform-development",
      "container-platform-hmpps-nonlive",
      "other-development",
      "missing-development",
      "undeclared-development",
    ]
    nonmp_account_names = ["collision-development"]
  }

  override_data {
    target = data.http.account_definition["modernisation-platform"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"modernisation-platform\"},\"environments\":[{\"name\":\"development\"}]}"
    }
  }
  override_data {
    target = data.http.account_definition["cloud-platform"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"cloud-platform\"},\"environments\":[{\"name\":\"development\"}]}"
    }
  }
  override_data {
    target = data.http.account_definition["container-platform-hmpps"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"container-platform-octo\"},\"environments\":[{\"name\":\"nonlive\"}]}"
    }
  }
  override_data {
    target = data.http.account_definition["other"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"cloud-platform-extra\"},\"environments\":[{\"name\":\"development\"}]}"
    }
  }
  override_data {
    target = data.http.account_definition["missing"]
    values = { status_code = 404, response_body = "Not Found" }
  }
  override_data {
    target = data.http.account_definition["undeclared"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"modernisation-platform\"},\"environments\":[{\"name\":\"production\"}]}"
    }
  }
  override_data {
    target = data.http.account_definition["collision"]
    values = {
      status_code   = 200
      response_body = "{\"tags\":{\"application\":\"modernisation-platform\"},\"environments\":[{\"name\":\"development\"}]}"
    }
  }

  assert {
    condition = (
      output.team_by_account["modernisation-platform-development"] == "modernisation-platform" &&
      output.team_by_account["cloud-platform-development"] == "cloud-platform" &&
      output.team_by_account["container-platform-hmpps-nonlive"] == "cloud-platform" &&
      output.team_by_account["other-development"] == null &&
      !contains(keys(output.team_by_account), "missing-development") &&
      !contains(keys(output.team_by_account), "undeclared-development") &&
      !contains(keys(output.team_by_account), "collision-development")
    )
    error_message = "Match exact MP and cloud-platform tags plus the CP prefix, and reject unknown, undeclared, or non-MP accounts."
  }
}

run "disabled_environment" {
  command = plan

  variables {
    enabled                              = false
    accounts                             = ["modernisation-platform-development"]
    modernisation_platform_account_names = ["modernisation-platform-development"]
    nonmp_account_names                  = []
  }

  assert {
    condition     = length(data.http.account_definition) == 0 && length(output.team_by_account) == 0
    error_message = "Do not query ownership definitions or grant access when the feature is disabled."
  }
}

run "enabled_without_accounts" {
  command = plan

  variables {
    enabled                              = true
    accounts                             = []
    modernisation_platform_account_names = ["cloud-platform-production"]
    nonmp_account_names                  = []
  }

  assert {
    condition     = length(data.http.account_definition) == 0 && length(output.team_by_account) == 0
    error_message = "An enabled stack with no onboarded accounts must not grant access or fetch account definitions."
  }
}
