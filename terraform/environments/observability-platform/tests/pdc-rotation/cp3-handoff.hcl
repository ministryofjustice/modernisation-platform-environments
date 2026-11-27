variables {
  use_environment_configuration = true
}

run "previous_four_account_development_tenant" {
  state_key = "cp3"
  command   = apply

  module {
    source = "./before_cp3_handoff"
  }
}

run "retire_three_development_accounts" {
  state_key = "cp3"
  command   = plan
}
