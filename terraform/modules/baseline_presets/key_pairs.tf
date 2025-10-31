# See README.md for how to use

locals {

  ec2_user_public_key_filename = ".ssh/${var.environment.account_name}/ec2-user.pub"

  key_pairs_filter = flatten([
    var.options.enable_ec2_user_keypair && fileexists(local.ec2_user_public_key_filename) ? ["ec2-user"] : [],
  ])

  key_pairs = {
    ec2-user = {
      public_key_filename = local.ec2_user_public_key_filename
    }
  }

}
