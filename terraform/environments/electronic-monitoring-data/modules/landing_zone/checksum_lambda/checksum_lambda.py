import base64
import boto3
import hashlib


s3_client = boto3.client('s3')


def handler(event, context):
    # Retrieve the S3 bucket name and object key from the event.
    bucket_name = event['tasks'][0]['s3Bucket']
    object_key = event['tasks'][0]['s3Key']

    # Generate the SHA256 checksum of the object.
    hash_value = generate_sha256_checksum(bucket_name, object_key)
    
    # Print the SHA256 checksum to CloudWatch logs.
    print(f"SHA256 checksum of {object_key}: {hash_value}")
    
    hash_64 = convert_hash_to_base64(hash=hash_value)

    # Print the Base 64 encoded SHA256 checksum to CloudWatch logs.
    print(f"Base 64 SHA256 checksum of {object_key}: {hash_64}")

    # Apply tags to the object.
    s3_client.put_object_tagging(
        Bucket=bucket_name,
        Key=object_key,
        Tagging={
            'TagSet': [
                {'Key': 'SHA-256 checksum', 'Value': hash_value},
                {'Key': 'Base64 SHA-256 checksum', 'Value': hash_64},
            ]
        }
    )
    
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
