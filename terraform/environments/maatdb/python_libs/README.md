# Python 3.12 Lambda Layer Builder

This folder provides a Docker-based setup for building an AWS Lambda layer zip file containing Python 3.12 dependencies.

---

## 📄 Files

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

## 🚀 Usage

### 1️⃣ Make sure these files exist in your directory

Dockerfile
entrypoint.sh
build-layer.sh
requirements.txt (optional — will be created if missing)

---

### 2️⃣ Make scripts executable

```bash
chmod +x build-layer.sh entrypoint.sh
