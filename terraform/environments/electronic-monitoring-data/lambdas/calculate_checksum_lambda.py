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
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    size = event['Records'][0]['s3']['object']['size']

    print(f'{object_key = } of {size = }B added to {bucket_name = } via {event_type = }')

    chunk_size = 131072  # 128KB

    # TEMPORARILY ALSO ADDING THE ZIP SUMMARY CODE HERE.
    # Check if the object key ends with '.zip'
    if object_key.endswith('.zip'):
        print(f"Summarising '{object_key = }' as has '.zip' extension")
        zip_data = summarise_zip_file(
            bucket_name=bucket_name,
            object_key=object_key,
            chunk_size=chunk_size,
        )

        save_info_json(
            bucket_name=bucket_name,
            object_key=object_key,
            json_data=zip_data,
        )


    # Generate the SHA256 checksum of the object.
    hash_value = generate_sha256_checksum(
        bucket_name=bucket_name,
        object_key=object_key,
        chunk_size=chunk_size,
    )
    
    hash_64 = convert_hash_to_base64(hash_value=hash_value)

    additional_tags = {
        'SHA-256 checksum': hash_value,
        'Base64 SHA-256 checksum': hash_64,
    }

    add_sha256_tags(
        bucket_name=bucket_name,
        object_key=object_key,
        additional_tags=additional_tags,
    )

    return None


def generate_sha256_checksum(
    bucket_name,
    object_key,
    chunk_size = 65536,  # 64 KB chunk.
):
    print(f'Using {chunk_size=}B to read object')

    # Initialize the SHA256 hash object
    sha256_hash = hashlib.sha256()

    # Retrieve the object data from S3 in chunks
    try:
        processed_chunks = 0

        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        object_stream = response['Body']
        
        while True:
            chunk = object_stream.read(chunk_size)
            if not chunk:
                break
            sha256_hash.update(chunk)

            processed_chunks += 1

            if processed_chunks % 25000 == 0:
                print(f'Processed {processed_chunks} chunks')

    except Exception as e:
        print("Error:", e)
        return None

    # Calculate the SHA256 checksum
    hash_value = sha256_hash.hexdigest()

    print(f'SHA256 checksum: {hash_value}')

    return hash_value


def convert_hash_to_base64(hash_value):
    # Convert hexdigest to bytes
    binary_data = bytes.fromhex(hash_value)

    # Encode bytes to base64
    hash_64 = base64.b64encode(binary_data).decode()

    # Print the Base 64 encoded SHA256 checksum to CloudWatch logs.
    print(f'Base 64 SHA256 checksum: {hash_64}')

    return hash_64


def add_sha256_tags(
    bucket_name,
    object_key,
    additional_tags,
):
    # Retrieve existing tags for the object
    response = s3_client.get_object_tagging(
        Bucket=bucket_name,
        Key=object_key
    )
    
    # Merge existing tags with additional tags
    existing_tags = response.get('TagSet', [])
    existing_tags.extend([
        {'Key': key, 'Value': value}
        for key, value in additional_tags.items()
    ])
    
    print(existing_tags)
    
    # Update tags for the object
    s3_client.put_object_tagging(
        Bucket=bucket_name,
        Key=object_key,
        Tagging={
            'TagSet': existing_tags
        }
    )

    print(f'Added tags = {list(additional_tags.keys())} to {object_key = }')

    return None


def summarise_zip_file(
    bucket_name,
    object_key,
    chunk_size=4096,
):
    try:
        # Initialize counters
        total_folders = 0
        total_files = 0
        total_size = 0
        total_packed_size = 0

        # Initialize physical size of the zip file
        physical_size = 0

        # Create an in-memory buffer to read chunks of data
        buffer = io.BytesIO()
        
        # Read the contents of the zip file from S3 in chunks
        response = s3_client.get_object(
            Bucket=bucket_name,
            Key=object_key,
        )
        zip_stream = response['Body']
        
        # Read and process the zip file in chunks
        while True:
            chunk = zip_stream.read(chunk_size)
            if not chunk:
                break
            
            # Write the chunk to the buffer
            buffer.write(chunk)
            
            # Check if a complete file exists in the buffer
            while True:
                # Seek to the beginning of the buffer
                buffer.seek(0)
                
                # Attempt to open the zip file with the current buffer contents
                try:
                    with zipfile.ZipFile(buffer, 'r') as zip_ref:
                        # Get file list
                        file_list = zip_ref.namelist()
                        
                        # Iterate through files in the zip
                        for file_name in file_list:
                            # Extract file information
                            file_info = zip_ref.getinfo(file_name)
                            
                            # Update counters
                            if file_info.is_dir():
                                total_folders += 1
                            else:
                                total_files += 1
                                total_size += file_info.file_size
                                total_packed_size += file_info.compress_size
                    
                    # Get the physical size of the zip file
                    physical_size = buffer.tell()
                    
                    # Reset the buffer
                    buffer.seek(0)
                    buffer.truncate(0)
                    
                    # Exit the inner loop
                    break
                
                # If the buffer does not contain a complete zip file, continue reading chunks
                except zipfile.BadZipFile:
                    break
            
    except Exception as e:
        print("Error:", e)
        return None
    
    # Return analysis results
    return {
        'size': total_size,
        'packed_size': total_packed_size,
        'folders': total_folders,
        'files': total_files,
        'physical_size': physical_size,
    }


def save_info_json(
    bucket_name,
    object_key,
    json_data,
):
        json_content = json.dumps(json_data)

        # Saving JSON content to a new file with .json extension
        new_object_key = object_key + '.info.json'

        s3_client.put_object(
            Bucket=bucket_name, 
            Key=new_object_key,
            Body=json_content.encode('utf-8')
        )

        print(f'Json information saved to {new_object_key}')