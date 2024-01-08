resource "aws_directory_service_directory" "mmad" {
  name     = "sprinkler.modernisation-platform.internal"
  password = aws_secretsmanager_secret_version.mmad.secret_string
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id]
  }

  tags = merge(
    local.tags,
    { Name = "sprinkler.modernisation-platform.internal" }
  )
}

resource "aws_secretsmanager_secret" "mmad" {
  name = "active-directory_sprinkler.modernisation-platform.internal"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mmad" {
  secret_id     = aws_secretsmanager_secret.mmad.id
  secret_string = random_password.mmad.result
}

resource "random_password" "mmad" {
  length      = 16
  min_numeric = 1
  min_special = 1
}