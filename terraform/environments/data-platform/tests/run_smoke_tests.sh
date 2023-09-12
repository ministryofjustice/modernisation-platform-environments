
database="example_prison_data_product"
table="testing"

file="test_data.csv"
file_md5=$(cat $file | openssl dgst -md5 -binary | base64)
request_presigned_url="https://hsolkci589.execute-api.eu-west-2.amazonaws.com/development/upload_data"
query_string="database=$database&table=$table&contentMD5=$file_md5"
response=$(curl "$request_presigned_url?$query_string" -H "authorizationToken: placeholder")

echo "Attempting to delete $database.$table from glue"
echo $(aws glue delete-table --database-name $database --name $table)

url=$(echo $response | jq '.URL.url' | tr -d '"')
encryption=$(echo $response | jq '.URL.fields."x-amz-server-side-encryption"' | tr -d '"')
acl=$(echo $response | jq '.URL.fields."x-amz-acl"' | tr -d '"')
date=$(echo $response | jq '.URL.fields."x-amz-date"' | tr -d '"')
Content_MD5=$(echo $response | jq '.URL.fields."Content-MD5"' | tr -d '"')
content_type=$(echo $response | jq '.URL.fields."Content-Type"' | tr -d '"')
key=$(echo $response | jq '.URL.fields.key' | tr -d '"')
algorithm=$(echo $response | jq '.URL.fields."x-amz-algorithm"' | tr -d '"')
credential=$(echo $response | jq '.URL.fields."x-amz-credential"' | tr -d '"')
token=$(echo $response | jq '.URL.fields."x-amz-security-token"' | tr -d '"')
policy=$(echo $response | jq '.URL.fields.policy' | tr -d '"')
signature=$(echo $response | jq '.URL.fields."x-amz-signature"' | tr -d '"')

echo "Posting $file to presigned url as $database.$table"
curl -X POST \
     -F x-amz-server-side-encryption=$encryption -F x-amz-date=$date \
     -F Content-MD5=$Content_MD5 -F Content-Type=$content_type  \
     -F key=$key -F x-amz-acl=$acl \
     -F Policy=$policy -F X-Amz-Credential=$credential -F x-amz-signature=$signature \
     -F X-Amz-Algorithm=$algorithm -F X-Amz-Security-Token=$token -F file=@./$file \
      $url

echo "Waiting for $database.$table to show up in athena"
sleep 10
echo "Getting recreated table"
echo $(aws glue get-table --database-name $database --name $table)
