"""Lambda function to add Checksum metadata to files.

This function adds two tags to files that contain the SHA256 checksum as well
as the Base64 encoded SHA256 checksum (this is what AWS displays by default).

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

import io
import json
import zipfile


s3_client = boto3.client('s3')


def handler(event, context):
    print(event)

    event_type = event['Records'][0]['eventName']
    bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    size = event['Records'][0]['s3']['object']['size']

    print(f'{object_key = } of {size = }B added to {bucket = } via {event_type = }')

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

    # TEMPORARILY ALSO ADDING THE ZIP SUMMARY CODE HERE.

    # Check if the object key ends with '.zip'
    if object_key.endswith('.zip'):
        print(f"Summarising '{object_key = }' as has '.zip' extension")

        # Read the contents of the zip file from S3
        response = s3_client.get_object(
            Bucket=bucket,
            Key=object_key
        )
        
        # Read the zip file content into memory
        zip_content = response['Body'].read()
        
        # Extract files from the zip
        with zipfile.ZipFile(io.BytesIO(zip_content)) as zip_ref:
            # List all files in the zip
            file_list = zip_ref.namelist()
            
            # Total number of files
            total_files = len(file_list)
            
            # Directory structure dictionary
            directory_structure = {}
            
            # Read each file's content and build directory structure
            for file_name in file_list:
                parts = file_name.split('/')
                current_dict = directory_structure
                
                # Traverse directory structure and create dictionary entries
                for part in parts[:-1]:
                    if part not in current_dict:
                        current_dict[part] = {}
                    current_dict = current_dict[part]
            
            print(f'\n\nJSON directory structure:\n{directory_structure}')

            print(f'\n\n Total files in {object_key}: {total_files}')

            # Writing the JSON file with the information
            json_data = {
                'total_objects': total_files,
                'directory_structure': directory_structure
            }
            json_content = json.dumps(json_data)

            # Saving JSON content to a new file with .json extension
            new_object_key = object_key + '.info.json'

            s3_client.put_object(
                Bucket=bucket, 
                Key=new_object_key,
                Body=json_content.encode('utf-8')
            )

            print(f'Zip info saved to {new_object_key}')

    return None


def generate_sha256_checksum(
    bucket_name,
    object_key,
    chunk_size=65536,  # 64 KB chunk.
):
    print(f'Using {chunk_size=}B to read object')

    # Initialize the SHA256 hash object
    sha256_hash = hashlib.sha256()

    # Retrieve the object data from S3 in chunks
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        object_stream = response['Body']
        
        while True:
            chunk = object_stream.read(chunk_size)
            if not chunk:
                break
            sha256_hash.update(chunk)

    except Exception as e:
        print("Error:", e)
        return None

    # Calculate the SHA256 checksum
    return sha256_hash.hexdigest()


def convert_hash_to_base64(hash_value):
    # Convert hexdigest to bytes
    binary_data = bytes.fromhex(hash_value)

    # Encode bytes to base64
    return base64.b64encode(binary_data).decode()
