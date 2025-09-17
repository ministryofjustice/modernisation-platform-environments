import boto3
import os
import subprocess
import logging
import paramiko
import io

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOGLEVEL", "INFO"))

# FTP / FTPS
host = os.environ.get('HOST')
port = os.environ.get('PORT')
protocol = os.environ.get('PROTOCOL')
transferType = os.environ.get('TRANSFERTYPE')
fileTypes = os.environ.get('FILETYPES')
remotePath = os.environ.get('REMOTEPATH')
localPath = os.environ.get('LOCALPATH')
requireSSL = os.environ.get('REQUIRE_SSL')
insecure = os.environ.get('INSECURE')
caCert = os.environ.get('CA_CERT')
cert = os.environ.get('CERT')
key = os.environ.get('KEY')
keyType = os.environ.get('KEY_TYPE')
user = os.environ.get('USER')
password = os.environ.get('PASSWORD')
certPath = os.environ['LAMBDA_TASK_ROOT'] + "/certs/"
# SFTP related
ssh_key = os.environ.get('SSH_KEY')
private_key = None

if ssh_key:
    cert = ssh_key[32:-30].replace(" ", "\n")
    start = '-----BEGIN RSA PRIVATE KEY-----\n'
    end = '\n-----END RSA PRIVATE KEY-----'
    ssh_key = start + cert + end
    private_key_file = io.StringIO()
    private_key_file.write(ssh_key)
    private_key_file.seek(0)
    private_key = paramiko.RSAKey.from_private_key(private_key_file)

if fileTypes:
    extensions = ['.'+ext for ext in fileTypes.split(',')]

# Check for valid env vars
if None in (host, transferType, remotePath, protocol):
    logger.error('Missing Environment Variables')
    logger.error('Need HOST, TRANSFERTYPE, REMOTEPATH and PROTOCOL')
    raise Exception('Need HOST, TRANSFERTYPE, REMOTEPATH and PROTOCOL defined')


def lambda_handler(event, context):
    command = "curl --max-time 600 "

    # SSL/Certs
    if insecure == "YES":
        command += "-k "
    if protocol == "FTPS":
        command += "--ssl-reqd --ftp-ssl "
    elif requireSSL == "YES":
        command += "--ssl-reqd --ftp-ssl "
    if caCert:
        command += "--cacert " + certPath + caCert + " "
    if cert:
        command += "--cert " + certPath + cert + " "
    if key:
        command += "--key " + key + " "
    if keyType:
        command += "--key-type " + keyType + " "
    # User/Auth
    if user:
        if password:
            command += "-u " + user + ":" + password + " "
        else:
           logger.info("Have user but no password")
           command += "-u " + user + " "
    # Host
    if port:
        command += protocol + "://" + host + ":" + port + remotePath
    else:
        command += protocol + "://" + host + remotePath

    if os.environ.get('TRANSFERTYPE') == "FTP_UPLOAD":
        FTPuploadFiles(command)
    elif os.environ.get('TRANSFERTYPE') == "FTP_DOWNLOAD":
        FTPdownloadFiles(command)
    elif os.environ.get('TRANSFERTYPE') == "SFTP_DOWNLOAD":
        SFTPdownloadFiles()
    elif os.environ.get('TRANSFERTYPE') == "SFTP_UPLOAD":
        SFTPuploadFiles()
    else:
        logger.error('TRANSFERTYPE should be (S)FTP_UPLOAD or (S)FTP_DOWNLOAD')
        raise Exception('TRANSFERTYPE should be (S)FTP_UPLOAD or (S)FTP_DOWNLOAD')


# Takes a curl command and runs it, has some error handling
def runCommand(command):
    logger.info('Curl command: {}'.format(command))
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    except Exception as e:
        logger.error('Could not connect to remote host')
        logger.error(e)
        raise Exception('Could not connect to remote host.\n{}'.format(e))
    if result.returncode != 0:
        logger.error('Error in FTP process.')
        logger.error('Return code {}'.format(result.returncode))
        logger.error('Details: {}'.format(result.stdout))
        raise Exception('Error in FTP process.\nReturn code {}.\n Details: {}\n{}'.format(result.returncode, result.stdout, result.stderr))
    logger.info('Details: {}'.format(result.stdout))
    return result


def FTPuploadFiles(command):
    s3_client = boto3.client('s3')
    bucket = os.environ.get('S3BUCKET')
    if not bucket:
        logger.error('No S3 Bucket defined for Upload')
        raise Exception('No S3 Bucket defined for Upload')
    if localPath:
        result = s3_client.list_objects_v2(Bucket=bucket, Prefix=localPath, Delimiter='/').get('Contents')
    else:
        result = s3_client.list_objects_v2(Bucket=bucket).get('Contents')
    if not result:
        logger.info('Nothing to upload')
        return
    else:
        logger.info('Files in the S3:')
        logger.info(result)
    for res in result:
        if fileTypes:
            if res['Key'].endswith(tuple(extensions)):
                f = res['Key']
            else:
                continue
        else:
            f = res['Key']
            if f.endswith('/'):
                continue
        if localPath:
            filename = os.path.basename(f)
            s3_client.download_file(bucket, f, "/tmp/" + filename)
            put = command + " --upload-file /tmp/" + filename
        else:
            s3_client.download_file(bucket, f, "/tmp/" + f)
            put = command + " --upload-file /tmp/" + f
        runCommand(put)
        if os.environ.get('FILEREMOVE') == "YES":
            s3_client.delete_object(Bucket=bucket, Key=f)


def FTPdownloadFiles(command):
    s3_client = boto3.client('s3')
    bucket = os.environ.get('S3BUCKET')
    # Check for valid env vars
    if not bucket:
        logger.error('No S3 Bucket defined for Download')
        raise Exception('No S3 Bucket defined for Download')

    # Result is a byte string list of files
    # We need to decode it to a String, remove the extra newline, and convert to a list of files
    result = runCommand(command + " --list-only")
    try:
        files = result.stdout.decode("utf-8").rstrip('\n').split('\n')
    except Exception as e:
        logger.error('Could not decode remote response to File List')
        logger.error(e)
        raise Exception('Could not decode remote response to File List.\n{}'.format(e))
    if files == ['']:
        logger.info('Nothing to download')
        return
    else:
        logger.info('Files on the source server:')
        logger.info(files)
    for f in files:
        if fileTypes:
            if not f.endswith(tuple(extensions)):
                continue
        get = command + f + " -o /tmp/" + f
        runCommand(get)
        if localPath:
            s3_client.upload_file("/tmp/" + f, bucket, localPath+f)
        else:
            s3_client.upload_file("/tmp/" + f, bucket, f)
        if os.environ.get('FILEREMOVE') == "YES":
            remove = command + ' -X "DELE ' + f + '"'
            result = subprocess.run(remove, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            # 19 should be a fail, but Curl DELETE is weird
            if result.returncode not in (0, 19):
                logger.error('Error in FTP process.')
                logger.error('Return code {}'.format(result.returncode))
                logger.error('Details: {}'.format(result.stdout))
                raise Exception('Error in FTP process.\nReturn code {}.\n Details: {}\n{}'.format(result.returncode, result.stdout, result.stderr))


def connect_to_SFTP(hostname, port, username, password=None, pkey=None):
    transport = paramiko.Transport((hostname, int(port)))
    if private_key:
        transport.connect(
            username=username,
            pkey=private_key
        )
    else:
        transport.connect(
            username=username,
            password=password
        )
    sftp = paramiko.SFTPClient.from_transport(transport)
    return sftp, transport


def SFTPdownloadFiles():
    if private_key:
        sftp, transport = connect_to_SFTP(
        hostname=host,
        port=port,
        username=user,
        pkey=private_key
        )
    else:
        sftp, transport = connect_to_SFTP(
            hostname=host,
            port=port,
            username=user,
            password=password
        )
    s3_client = boto3.client('s3')
    bucket = os.environ.get('S3BUCKET')
    # Check for valid env vars
    if not bucket:
        logger.error('No S3 Bucket defined for Download')
        raise Exception('No S3 Bucket defined for Download')
    sftp.chdir(remotePath)
    result = sftp.listdir()
    if fileTypes:
        files = []
        for file in result:
            if file.endswith(tuple(extensions)):
                files.append(file)
        result = files
    if not result:
        logger.info('Nothing to download')
        return
    else:
        logger.info('Files in the directory:')
        logger.info(result)
        for f in result:
            sftp.get(f,"/tmp/"+f)
            if localPath:
                s3_client.upload_file("/tmp/" + f, bucket, localPath+f)
            else:
                s3_client.upload_file("/tmp/" + f, bucket, f)
            if os.environ.get('FILEREMOVE') == "YES":
                sftp.remove(f)


def SFTPuploadFiles():
    if private_key:
        sftp, transport = connect_to_SFTP(
        hostname=host,
        port=port,
        username=user,
        pkey=private_key
        )
    else:
        sftp, transport = connect_to_SFTP(
            hostname=host,
            port=port,
            username=user,
            password=password
        )
    s3_client = boto3.client('s3')
    bucket = os.environ.get('S3BUCKET')
    if not bucket:
        logger.error('No S3 Bucket defined for Upload')
        raise Exception('No S3 Bucket defined for Upload')
    if localPath:
        result = s3_client.list_objects_v2(Bucket=bucket, Prefix=localPath, Delimiter='/').get('Contents')
    else:
        result = s3_client.list_objects_v2(Bucket=bucket).get('Contents')
    if not result:
        logger.info('Nothing to upload')
        return
    logger.info('Files in the S3:')
    logger.info(result)
    for res in result:
        f = res['Key']
        # don't handle directories
        if f.endswith('/'):
            continue
        if fileTypes:
            if res['Key'].endswith(tuple(extensions)):
                f = res['Key']
            else:
                continue
        if localPath:
            filename = os.path.basename(f)
            s3_client.download_file(bucket, f, "/tmp/" + filename)
            sftp.put('/tmp/' + filename, remotePath + filename)
        else:
            s3_client.download_file(bucket, f, "/tmp/" + f)
            sftp.put('/tmp/' + f, remotePath + f)
        if os.environ.get('FILEREMOVE') == "YES":
            s3_client.delete_object(Bucket=bucket, Key=f)
