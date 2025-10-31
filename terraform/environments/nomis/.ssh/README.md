# SSH keys

Each environment has its own public/private ssh key pair for the default ec2-user.
The private key is uploaded as a SecretsManager secret in each environment under `/ec2/.ssh/ec2-user`.

## Creating the keys

For new accounts, before you create any EC2 instance:
- Run [create-keys.sh](create-keys.sh) to create the initial key pairs
- Commit the public keys into source code in the directory they are created `terraform/environments/nomis/.ssh/*/ec2-user.pub`
- Apply terraform.  Baseline module with `enable_ec2_user_keypair = true` in `baseline_presets_options`. This will create an aws_key_pair resource and a placeholder `/ec2/.ssh/ec2-user` secret
- Run [put-keys.sh](put-keys.sh) to put the private key in the `/ec2/.ssh/ec2-user` secret
- Run the put-keys.sh script to validate keys are updated and delete your unencrypted local private key

## Using the keys

The ec2-user key pair can be used to access a server if SSM is not working. Setup the key-pair on your local machine as follows:
- Run [get-keys.sh](get-keys.sh) from this directory to download and encrypt the ssh private keys.
- Run [create-links.sh](create-links.sh) from this directory to create soft links in your ~/.ssh directory

If SSM is working, you can SSH with config like this replace myinstanceid and nomis-development as appropriate.

```
Host i-myinstanceid
   ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile nomis-development"
   User ec2-user
   HostKeyAlgorithms +ssh-dss,ssh-rsa
   StrictHostKeyChecking no
   UserKnownHostsFile /dev/null
   IdentityFile ~/.ssh/nomis-development/ec2-user
```

If SSM is not working, you will need to ssh proxy via another host such as an SSH bastion.

```
Host bastion
   # put your ssh bastion config here
   # bastion must have ssh connectivity to your instance

Host i-myinstanceid
   ProxyJump bastion
   User ec2-user
   HostKeyAlgorithms +ssh-dss,ssh-rsa
   StrictHostKeyChecking no
   UserKnownHostsFile /dev/null
   IdentityFile ~/.ssh/nomis-development/ec2-user
```
