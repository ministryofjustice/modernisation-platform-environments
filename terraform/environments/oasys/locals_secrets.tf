locals {

  share_secret_principal_ids_db = [
    "arn:aws:iam::${module.environment.account_id}:role/ec2-database-*"
  ]

  secret_policy_write_db = {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
    ]
    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${module.environment.account_id}:role/ec2-database-*"
      ]
    }
    resources = ["*"]
  }
  secret_policy_read_db = {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${module.environment.account_id}:role/ec2-database-*"
      ]
    }
    resources = ["*"]
  }

  secretsmanager_secrets_bip = {
    secrets = {
      passwords = {}
    }
  }

  secretsmanager_secrets_db = {
    # policy = [
    #   local.secret_policy_read_db,
    #   local.secret_policy_write_db,
    # ]
    secrets = {
      passwords = {}
    }
  }

  secretsmanager_secrets_oasys_db = {
    secrets = {
      passwords      = {}
      apex-passwords = {}
    }
  }

  secretsmanager_secrets_bip_db = {
    secrets = {
      passwords     = {}
      bip-passwords = {}
    }
  }
}
