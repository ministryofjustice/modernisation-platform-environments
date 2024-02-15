"""Lambda function to add Checksum metadata to files.

This function adds two tags to files that contain the SHA256 checksum as well
as the BAse64 encoded SHA256 checksum (this is what AWS displays by default).

To calculate a files SHA256 checksum locally in the command line (i.e. to
compare) use:
```
shasum -a 256 path/to/file
```

and:

```
shasum -a 256 path/to/file | cut -f1 -d\ | xxd -r -p | base64
```

to encode it to Base64.
"""
import base64
import boto3
import hashlib


s3_client = boto3.client('s3')


def handler(event, context):
    print(event)

    event_type = event['Records'][0]['eventName']
    bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    print(f'{object_key = } added to {bucket = } via {event_type = }')

    # Generate the SHA256 checksum of the object.
    hash_value = generate_sha256_checksum(bucket, object_key)
    
    # Print the SHA256 checksum to CloudWatch logs.
    print(f'SHA256 checksum of {object_key}: {hash_value}')
    
    hash_64 = convert_hash_to_base64(hash_value=hash_value)

    # Print the Base 64 encoded SHA256 checksum to CloudWatch logs.
    print(f'Base 64 SHA256 checksum of {object_key}: {hash_64}')

    # Retrieve existing tags for the object
    response = s3_client.get_object_tagging(
        Bucket=bucket,
        Key=object_key
    )

    additional_tags = {
        'SHA-256 checksum': hash_value,
        'Base64 SHA-256 checksum': hash_64,
    }
    
    # Merge existing tags with additional tags
    existing_tags = response.get('TagSet', [])
    existing_tags.extend([
        {'Key': key, 'Value': value}
        for key, value in additional_tags.items()
    ])
    
    # Update tags for the object
    s3_client.put_object_tagging(
        Bucket=bucket,
        Key=object_key,
        Tagging={
            'TagSet': existing_tags
        }
    )

    print(f'Added tags = {list(additional_tags.keys())} to {object_key = }')

    return None


def generate_sha256_checksum(bucket_name, object_key):
    # Retrieve the object data from S3
    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    object_data = response['Body'].read()
    
    # Calculate the SHA256 checksum
    sha256_hash = hashlib.sha256(object_data).hexdigest()

    return sha256_hash


def convert_hash_to_base64(hash_value):
    # Convert hexdigest to bytes
    binary_data = bytes.fromhex(hash_value)

    # Encode bytes to base64
    return base64.b64encode(binary_data).decode()
