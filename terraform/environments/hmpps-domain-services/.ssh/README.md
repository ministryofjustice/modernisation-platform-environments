# SSH keys

Each environment has its own public/private ssh key pair for the default ec2-user.
The private key is uploaded as a SSM parameter in each environment under `ec2-user_pem`.

## Creating the keys
Run [create-keys.sh](create-keys.sh) to create the initial keys
Then create the SSM placeholder parameters in AWS
Then update the SSM parameters with [put-keys.sh](put-keys.sh)

## Using the keys
Run [get-keys.sh](get-keys.sh) from this directory to download all of the keys.

Example ssh config found [here](https://github.com/ministryofjustice/dso-useful-stuff/blob/main/.ssh/config)
This assumes keys are stored under your .ssh directory, e.g. `~/.ssh/nomis-development/ec2-user`
