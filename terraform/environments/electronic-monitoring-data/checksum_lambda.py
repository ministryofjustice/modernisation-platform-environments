"""
Lambda function to add Checksum metadata to files.

Implementation taken from 
https://aws.amazon.com/blogs/storage/enabling-and-validating-additional-checksums-on-existing-objects-in-amazon-s3/
"""
import boto3
import os

s3_client = boto3.client('s3')
s3_resource = s3 = boto3.resource('s3')

def handler(event, context):

    print(event)

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    print(f"Object {key} was just uploaded in Bucket {bucket}.")
    copy_source = {
        'Bucket': bucket,
        'Key': key
    }

    attributes = get_attributes(bucket, key)
    
    # Only proceed if Checksums don't already exist
    if attributes['Checksum'] is None:
        print(f"Copying {key} to the same place but adding Checksum ...")
        try:
            # If using SSE-KMS
            if 'EncryptionKey' in attributes:
                s3_resource.meta.client.copy(
                    copy_source,
                    Bucket=bucket,
                    Key=key,
                    ExtraArgs={
                        'ChecksumAlgorithm':os.environ['Checksum'],
                        'StorageClass': attributes['StorageClass'],
                        'ServerSideEncryption': attributes['Encryption'],
                        'SSEKMSKeyId': attributes['EncryptionKey']
                    }
                )
            # If using SSE-S3
            elif attributes['Encryption'] is not None:
                s3_resource.meta.client.copy(
                    copy_source,
                    Bucket=bucket,
                    Key=key,
                    ExtraArgs={
                        'ChecksumAlgorithm':os.environ['Checksum'],
                        'StorageClass': attributes['StorageClass'],
                        'ServerSideEncryption': attributes['Encryption']
                    }
                )
            # If not using any encryption - NOT RECOMMENDED
            else:
                print(os.environ['Checksum'])
                s3_resource.meta.client.copy(
                    copy_source,
                    Bucket=bucket,
                    Key=key,
                    ExtraArgs={
                        'ChecksumAlgorithm':os.environ['Checksum'],
                        'StorageClass': attributes['StorageClass']
                    }
                )
            print(f"SUCCESS: {key} now has a {os.environ['Checksum']} Checksum ")
        except Exception as e:
            print(e)
            raise
    else:
        print(f"{key} already has a Checksum; No further action needed!")
    
    return

def get_attributes(bucket, key):
    try:
        attributes = {}
        response = s3_client.get_object_attributes(
        Bucket=bucket,
        Key=key,
        ObjectAttributes=['Checksum']
        )
        
        # Check if the Object already has Checksums
        print(f"Checking whether {key} already has Checksum ...")
        if 'ChecksumCRC32' in response:
            attributes['Checksum'] = 'ChecksumCRC32'
            print(f"{key} already has a CRC32 Checksum!")
            return attributes
        elif 'ChecksumCRC32C' in response:
            attributes['Checksum'] = 'ChecksumCRC32C'
            print(f"{key} already has a CRC32C Checksum!")
            return attributes
        elif 'ChecksumSHA1' in response:
            attributes['Checksum'] = 'ChecksumSHA1'
            print(f"{key} already has a SHA1 Checksum!")
            return attributes
        elif 'ChecksumSHA256' in response:
            attributes['Checksum'] = 'ChecksumSHA256'
            print(f"{key} already has a SHA256 Checksum!")
            return attributes
        else:
            print(f"{key} does not have a Checksum!")
            attributes['Checksum'] = None
            
            print(f"Obtaining other attributes for {key} ...")
            #Check Object's storage class
            print(f"Checking Storage Class for {key} ...")
            if 'StorageClass' not in response:
                print(f"{key} is stored in S3-STANDARD.")
                attributes['StorageClass'] = 'STANDARD'
            else:
                storage_class = response['StorageClass']
                print(f"{key} is stored in {storage_class}.")
                attributes['StorageClass'] = response['StorageClass']
            
            # Check Object's encryption
            print(f"Checking Encryption for {key} ...")
            if 'ServerSideEncryption' not in response:
                print(f"{key} is not encrypted.")
                attributes['Encryption'] = None
            else:
                print(f"{key} is encrypted.")
                attributes['Encryption'] = response['ServerSideEncryption']
                if response['ServerSideEncryption'] == 'aws:kms':
                    attributes['EncryptionKey'] = response['SSEKMSKeyId']
            
            return attributes

    except Exception as e:
        print(e)
        raise