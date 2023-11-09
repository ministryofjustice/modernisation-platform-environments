
import boto3

# Specify the AWS profile you want to use
aws_profile = 'laa-development-lz' 
snapshot_id = 'snap-0331f5921109f4666'
image_name = 'eric-db-srv-RHEL-7.7-280923'



# Initialize the Boto3 EC2 client with the specified profile
session = boto3.Session(profile_name=aws_profile)
ec2_client = session.client('ec2')

# Create an image from the snapshot
response = ec2_client.register_image(
    BlockDeviceMappings=[
        {
            'DeviceName': '/dev/sda1',  # Modify as needed
            'Ebs': {
                'SnapshotId': snapshot_id,
                'VolumeSize': 80,  # Modify as needed
                'VolumeType': 'gp2',  # Modify as needed
            },
        },
    ],
    RootDeviceName='/dev/sda1',
    VirtualizationType='hvm',
    Name=image_name,
    Description='Image created from snapshot in shutdown state',
    Architecture= 'x86_64'
    
)

# Print the newly created image ID
print(f"Image ID: {response['ImageId']}")
