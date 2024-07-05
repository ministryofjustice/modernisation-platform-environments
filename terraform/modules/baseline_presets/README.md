# Introduction

Preset configuration that can be plugged into the baseline module.

For example:
- standard wildcard cert
- resources required for using image builder
- an example security group setup

## ec2-user key pairs

If using baseline to create EC2 instances, follow these steps to create an
`ec2-user` admin user.

Step 1: Run terraform with `enable_ec2_user_keypair` set to true

This will create a SecretsManager secret for storing the private key.

Step 2: Generate key pairs

Use `ssh-keygen` to generate key pairs.  See example scripts in nomis
terraform under the `.ssh` directory.

Step 3: Update SecretsManager secret

Upload the private key to the SecretsManager secret.
Commit the public key to this repo under the relevant application
directory, e.g. for nomis, under `.ssh/nomis-test/ec2-user.pub`

Step 4: Re-run terrafrom

This will create the keypair resource.
