
# Python 3.12 Lambda Layer Builder

This folder provides a Docker-based setup for building an AWS Lambda layer zip file containing Python 3.12 dependencies.

---

## Files

### `Dockerfile`
- Builds an Amazon Linux 2023 base image.
- Installs Python 3.12 from source.
- Installs required build tools and Python packaging tools (`pip`, `setuptools`, `wheel`).
- Creates a non-root user (`appuser`) for security.
- Copies `requirements.txt` and `entrypoint.sh` into the image.
- Runs `entrypoint.sh` at container start to build the layer zip.

---

### `entrypoint.sh`
- Installs packages from `/app/requirements.txt` into `/tmp/python/lib/python3.12/site-packages/`.
- Creates a Lambda-compatible zip file named `ftpclient-python-requirements312.zip`.
- If `requirements.txt` is missing, automatically creates an empty one to avoid failures.

---

### `requirements.txt`
- List your Python dependencies here (example: `requests`, `boto3`).
- If left empty, an empty Lambda layer will be created.

---

### `build-layer.sh`
A convenience shell script to automate building and running the Docker image.  
It handles creating a default `requirements.txt`, building the image, and running the container.

---

## Usage

### Step 1: Make sure these files exist in your directory

- Dockerfile
- entrypoint.sh
- build-layer.sh
- requirements.txt (optional — will be created if missing)

---

### Step 2: Make scripts executable

```bash
chmod +x build-layer.sh entrypoint.sh

---

### Step 3: Upload the created ZIP file to layer S3 bucket

The zip file name, bucket and folder location are defined in the following parameters in application_variables.json:

- ftp_layer_source_zip
- ftp_layer_bucket
- ftp_layer_folder_location

Note - if amending for an existing deployment the, request for the layer resource to be “tainted” (ask the Modernisation Platform Team via the ask channel to do this) and then re-run the GitHub workflow for the environment in question. The layer will then be recreated using the updated python libs.

## Python Lambda Source

The directory also contains the following files:

- ftpclient.py. FTP script to upload or download files to/from a remote sftp host.
- zip_s3_objects.py. A script that will zip up files in a defined location.

Both of those files should zipped and uploaded to the bucket & folder location as mentioned above. 

The following parameters are relevant:

ftp_layer_source_zip - ftp lambda file name
zip_lambda_source_file - zip lambda file name

ftp_lambda_source_file_version & zip_lambda_source_file_version - the version IDs from the s3 bucket objects.

