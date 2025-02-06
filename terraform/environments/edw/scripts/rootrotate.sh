export SECRET2=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id EDW/app/db-EC2-root-password --query SecretString --output text`
echo "$SECRET2" | passwd root --stdin