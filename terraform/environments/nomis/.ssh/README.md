Each environment has its own public/private ssh key pair for the default ec2-user.
The private key is uploaded as a SSM parameter in each environment under `ec2-user_pem`.

For example:

```
PROFILE=nomis-development # for example
pem=$(cat $PROFILE/ec2-user)
aws ssm put-parameter --name "ec2-user_pem" --type "SecureString" --data-type "text" --value "$pem" --profile "$PROFILE"
```
