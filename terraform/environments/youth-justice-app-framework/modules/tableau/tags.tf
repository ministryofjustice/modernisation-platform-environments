#Adds a bunch of common tags for each resource in AWS
locals {
  head            = fileexists("${path.module}/.git/HEAD") ? split(" ", file("${path.module}/.git/HEAD")) : ["unknown"]
  git_hash_path   = contains(local.head, "unknown") ? "unknown" : (contains(local.head, "ref:") ? "${path.module}/.git/${trim(element(local.head, 1), "\n")}" : "${path.module}/.git/HEAD")
  module_version  = contains(local.head, "ref:") ? "${trim(file("${path.module}/VERSION.txt"), "\n")} (${trim(element(local.head, 1), "\n")})" : trim(file("${path.module}/VERSION.txt"), "\n")
  module_git_hash = contains(local.head, "unknown") ? "unknown" : trim(file(local.git_hash_path), "\n")

  tags = {
    "module"         = "tableau",
    "module_version" = local.module_version,
    #"module_git_hash"  = local.module_git_hash, #todo revisit this if we start using remote modules with tagging in github
    "project"     = var.project_name
    "Patch Group" = "Linux2"
  }


  all_tags = merge(var.tags, local.tags, local.tags)
}
