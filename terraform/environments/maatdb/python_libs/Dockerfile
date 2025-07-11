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

# Install & package dependencies for AWS Lambda layer (Python 3.12)
CMD /opt/bin/pip3.12 install -r /app/requirements.txt -t /tmp/python/lib/python3.12/site-packages/ && \
    find /tmp/python -name "_rust.abi3.so" && \
    cd /tmp && \
    zip -r9q /app/python-requirements-layer.zip python -x '*.dist-info*' -x '*.egg-info*' && \
    du -sh /app/python-requirements-layer.zip