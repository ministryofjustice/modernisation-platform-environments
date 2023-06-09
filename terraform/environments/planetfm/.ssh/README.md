Each environment has its own public/private ssh key pair for the default ec2-user.
The private key is uploaded as a SSM parameter in each environment under `ec2-user_pem`.

# Creating Keys

1. Generate keys (don't set password)

```
app=planetfm
for env in development test preproduction production; do
  mkdir -p $app-$env
  cd $app-$env
  ssh-keygen -m pem -t rsa -b 4096 -f ec2-user
  cd ..
done
```

2. Ensure terrafrom creates placeholder `ec2-user_pem` SSM parameter

3. Upload keys to SSM

Assumes you have correct aws config profiles setup

```
app=planetfm
for env in development test preproduction production; do
  pem=$(cat $app-$env/ec2-user)
  aws ssm put-parameter --name "ec2-user_pem" --type "SecureString" --data-type "text" --value "$pem" --overwrite --profile "$app-$env"
done
```

4. Delete any local private keys

```
rm */ec2-user
```

# Using keys

Run [get-keys.sh](get-keys.sh) from this directory to download all of the keys (set a password you can remember).

Example ssh config found [here](https://github.com/ministryofjustice/dso-useful-stuff/blob/main/.ssh/config)
This assumes keys are stored under your .ssh directory, e.g. `~/.ssh/planetfm-development/ec2-user`

Setup soft links in your own .ssh directory like this
```
  dir=$(pwd)
  (
    cd ~/.ssh
    app=planetfm
    for env in development test preproduction production; do
      ln -sf $dir/$app-$env $app-$env
    done
  )
```
