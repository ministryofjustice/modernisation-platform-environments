import boto3
import io
import json
import zipfile


def build_ascii_directory_structure(directory_structure, indent=0, structure_string=""):
    """
    Recursively constructs the directory structure string.

    Parameters
    ----------
    directory_structure
        The directory structure to print.
    indent
        The current indentation level.
    structure_string
        The string to append the directory structure.

    Returns
    -------
    str
        The constructed directory structure string.
    """
    for key, value in directory_structure.items():
        structure_string += '  ' * indent + f'- {key}\n'
        if isinstance(value, dict):
            structure_string = build_ascii_directory_structure(value, indent + 1, structure_string)
        elif isinstance(value, list):
            for item in value:
                structure_string = build_ascii_directory_structure(item, indent + 1, structure_string)
        else:
            structure_string += '  ' * (indent + 1) + f'- {value}\n'
    return structure_string


def handler(event, context):
    """
    Read contents of a zip file and print directory structure and item count.
    """
    print(event)

    event_type = event['Records'][0]['eventName']
    bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    print(f'{object_key = } added to {bucket = } via {event_type = }')
    
    # Create S3 client
    s3_client = boto3.client('s3')
    
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
            
            # Traverse the directory structure and create dictionary entries
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
            ey=new_object_key,
            Body=json_content.encode('utf-8')
        )

        print(f'Info saved to {new_object_key}')

        return None
