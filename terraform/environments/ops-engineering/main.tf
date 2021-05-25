resource "aws_ecrpublic_repository" "spike" {
  provider        = aws.us-east-1
  repository_name = "opsengspike"

  catalog_data {
    about_text        = "This is an MOJ production of AWS ECR brought to you by ops eng"
    architectures     = ["x86", "x86-64"]
    description       = "This will like just have naff images that I create"
    operating_systems = ["Linux"]
    usage_text        = "Usage Carefully, Here be dragons."
  }
}

output "repository_uri" {
  value = aws_ecrpublic_repository.spike.repository_uri
}