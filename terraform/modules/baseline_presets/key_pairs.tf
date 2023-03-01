locals {

  key_pairs = {

    # default admin user for EC2s
    ec2-user = {
      # commit the public key into environments repo, keep the private key somewhere safe
      public_key_filename = ".ssh/${var.environment.account_name}/ec2-user.pub"
    }
  }

}
