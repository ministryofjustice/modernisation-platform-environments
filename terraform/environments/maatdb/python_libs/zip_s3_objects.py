#!/usr/bin/env python3.7
import logging
import os
import zipfile
import datetime
import boto3


LOGGER = logging.getLogger()
LOGGER.setLevel(os.environ.get("LOGLEVEL", "INFO"))

# PARAMETERS
BUCKET = os.environ.get('BUCKET')
LOCALPATH = os.environ.get('LOCALPATH')
FILETYPES = os.environ.get('FILETYPES')
ARCHIVE_NAME = os.environ.get('ARCHIVE_NAME')
REMOVEFILESAFTER = os.environ.get('REMOVEFILESAFTER')

ARCHIVE_SUFFIX = datetime.datetime.now().strftime('%y%m%d%H%M%S')

if FILETYPES:
    FILE_EXTENSIONS = ['.' + ext for ext in FILETYPES.split(',')]

# Check for valid env vars
if None in (BUCKET, ARCHIVE_NAME):
    LOGGER.error('Missing Environment Variables')
    LOGGER.error('Need BUCKET & ARCHIVE_NAME defined')
    raise Exception('Need BUCKET & ARCHIVE_NAME defined')

def retrieve_files(path):
    """
    Returns the list of the files in the provided path

    Args:
        path (str): Path that's gonna be checked

    Returns:
        Returns list of the files in provided path
    """
    file_paths = []
    for root, directories, files in os.walk(path):
        for filename in files:
            filepath = os.path.join(filename)
            file_paths.append(filepath)
    return file_paths

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    cloudwatch = boto3.client('cloudwatch')
    paginator = s3_client.get_paginator('list_objects')
    file_count = 0
    if LOCALPATH:
        # result = s3_client.list_objects_v2(Bucket=BUCKET, Prefix=LOCALPATH, Delimiter='/').get('Contents')[1:]
        operation_parameters = {'Bucket': BUCKET, 'Prefix': LOCALPATH}
    else:
        operation_parameters = {'Bucket': BUCKET}
        # result = s3_client.list_objects_v2(Bucket=BUCKET).get('Contents')
    page_iterator = paginator.paginate(**operation_parameters)
    for page in page_iterator:
        for res in page['Contents']:
            if res['Key'] == LOCALPATH:
                continue
            if FILETYPES:
                if res['Key'].endswith(tuple(FILE_EXTENSIONS)):
                    s3_filename = res['Key']
                else:
                    continue
            else:
                s3_filename = res['Key']
            if LOCALPATH:
                local_filename = os.path.basename(s3_filename)
                s3_client.download_file(BUCKET, s3_filename, "/tmp/" + local_filename)
                file_count += 1
            else:
                s3_client.download_file(BUCKET, s3_filename, "/tmp/" + s3_filename)
                file_count += 1
    # on lambda only /tmp is RW
    path = '/tmp'
    FULL_ARCHIVE_NAME = ARCHIVE_NAME + "-" + ARCHIVE_SUFFIX + ".zip"
    files = retrieve_files(path)
    if files:
        LOGGER.info('Retrieved files:')
        LOGGER.info(files)
        os.chdir(path)
        LOGGER.info('Creating ZIP: %s' % FULL_ARCHIVE_NAME)
        zip_file = zipfile.ZipFile(FULL_ARCHIVE_NAME, 'w')
        with zip_file:
            for file in files:
                LOGGER.info('Archiving: %s' % file)
                zip_file.write(file)
                LOGGER.info('Removing locally: %s' % file)
                os.remove(file)
        if LOCALPATH:
            s3_client.upload_file("/tmp/"+FULL_ARCHIVE_NAME, BUCKET, LOCALPATH+FULL_ARCHIVE_NAME)
        else:
            s3_client.upload_file("/tmp/"+FULL_ARCHIVE_NAME, BUCKET, FULL_ARCHIVE_NAME)
        if REMOVEFILESAFTER == "YES":
            paginator = s3_client.get_paginator('list_objects')
            if LOCALPATH:
            # result = s3_client.list_objects_v2(Bucket=BUCKET, Prefix=LOCALPATH, Delimiter='/').get('Contents')[1:]
                operation_parameters = {'Bucket': BUCKET, 'Prefix': LOCALPATH}
            else:
                operation_parameters = {'Bucket': BUCKET}
            # result = s3_client.list_objects_v2(Bucket=BUCKET).get('Contents')
            page_iterator = paginator.paginate(**operation_parameters)
            for page in page_iterator:
                for res in page['Contents']:
                    if FILETYPES:
                        if res['Key'].endswith(tuple(FILE_EXTENSIONS)):
                            s3_filename = res['Key']
                    else:
                        s3_filename = res['Key']
                    LOGGER.info('Removing %s from S3' % s3_filename)
                    s3_client.delete_object(Bucket=BUCKET, Key=s3_filename)
        cloudwatch.put_metric_data(
            Namespace='lambda_ftp',
            MetricData=[
                {
                'MetricName': 'Fetched S3 Objects',
                'Dimensions': [
                    {
                    'Name': 'Lambda name',
                    'Value': context.function_name
                    },
                ],
                'Timestamp': datetime.datetime.now(),
                'Value': file_count,
                'Unit': 'None'
                    },
                ]
            )
    else:
        LOGGER.info('No files to archive that match our criteria!... exiting!')
