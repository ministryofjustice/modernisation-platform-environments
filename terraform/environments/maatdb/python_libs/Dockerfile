#checkov:skip=CKV_DOCKER_3: "Root user accepted for this container build step"
#checkov:skip=CKV_DOCKER_2: "Healthcheck not required for this simple container"
FROM public.ecr.aws/amazonlinux/amazonlinux:2023
LABEL maintainer="k@e-dot.uk"

# Environment setup
ENV PATH=/opt/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/lib

ARG SOURCE_PYTHON_VER=3.12.3
ENV SOURCE_PYTHON_VER=$SOURCE_PYTHON_VER

# Install build tools and required libraries
RUN yum update -y && \
    yum install -y --allowerasing \
    gcc gcc-c++ make zip tar xz findutils wget curl git rust cargo \
    bzip2 bzip2-devel xz-devel zlib-devel openssl-devel libffi-devel freetype-devel \
    readline-devel sqlite-devel gdbm-devel tk-devel libuuid-devel ncurses-devel libdb-devel \
    expat-devel libtirpc-devel && \
    yum groupinstall -y "Development Tools" && \
    yum clean all

# Build and install Python 3.12 into /opt (disable PGO)
RUN curl -sSL https://www.python.org/ftp/python/${SOURCE_PYTHON_VER}/Python-${SOURCE_PYTHON_VER}.tar.xz | tar -xJ && \
    cd Python-${SOURCE_PYTHON_VER} && \
    ./configure --prefix=/opt --enable-shared --with-ensurepip=install && \
    make -j$(nproc) altinstall && \
    cd .. && rm -rf Python-${SOURCE_PYTHON_VER}

# Upgrade pip, setuptools, wheel for Python 3.12
RUN /opt/bin/pip3.12 install --upgrade pip setuptools wheel

# Create non-root user and group
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --create-home appuser

# Ensure directories are owned by appuser
RUN mkdir -p /app /tmp/python && \
    chown -R appuser:appuser /app /tmp

# Copy requirements file and entrypoint script
COPY requirements.txt /app/
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Switch to non-root user
USER appuser

# Use JSON form for CMD
CMD ["bash", "/app/entrypoint.sh"]
