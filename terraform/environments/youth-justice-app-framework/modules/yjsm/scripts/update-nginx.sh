#!/bin/bash
# build-nginx-modsec.sh
# Usage: ./build-nginx-modsec.sh
# Override versions: NGINX_VERSION=1.29.1 MODSEC_VERSION=3.0.14 ./build-nginx-modsec.sh

set -euo pipefail

NGINX_VERSION=${NGINX_VERSION:-1.29.8}
MODSEC_VERSION=${MODSEC_VERSION:-3.0.14}
CONNECTOR_VERSION=${CONNECTOR_VERSION:-v1.0.4}
BUILD_DIR=/var/tmp/nginx-build

echo "================================================"
echo "Building:"
echo "  nginx:          $NGINX_VERSION"
echo "  ModSecurity:    $MODSEC_VERSION"
echo "  Connector:      $CONNECTOR_VERSION"
echo "================================================"

# -------------------------------------------------------
# Install build dependencies (AL2023)
# Note: geoip-devel removed from AL2023, dropped from flags
# -------------------------------------------------------
echo "[1/6] Installing build dependencies..."
dnf install -y gcc gcc-c++ make cmake git \
  pcre2-devel pcre-devel zlib-devel openssl-devel \
  libxml2-devel libcurl-devel \
  libxslt-devel gd-devel perl-devel \
  gperftools-devel yajl-devel \
  libtool autoconf automake

mkdir -p $BUILD_DIR && cd $BUILD_DIR

# -------------------------------------------------------
# Build ModSecurity v3
# Note: repo moved from SpiderLabs to owasp-modsecurity
# -------------------------------------------------------
echo "[2/6] Cloning and building ModSecurity $MODSEC_VERSION..."
git clone --depth 1 --branch v$MODSEC_VERSION \
  https://github.com/owasp-modsecurity/ModSecurity
cd ModSecurity
git submodule init && git submodule update
find . -name "*.sh" -exec chmod +x {} +
chmod +x build.sh
./build.sh
chmod +x configure
./configure
make -j$(nproc)
make install
cd $BUILD_DIR

# -------------------------------------------------------
# Get ModSecurity nginx connector
# Note: repo moved from SpiderLabs to owasp-modsecurity
# -------------------------------------------------------
echo "[3/6] Cloning ModSecurity-nginx connector $CONNECTOR_VERSION..."
git clone --depth 1 --branch $CONNECTOR_VERSION \
  https://github.com/owasp-modsecurity/ModSecurity-nginx

# -------------------------------------------------------
# Download and build nginx
# -------------------------------------------------------
echo "[4/6] Downloading nginx $NGINX_VERSION..."
curl -O https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar xzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}

echo "[5/6] Configuring and building nginx..."
./configure \
  --prefix=/usr/share/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib64/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
  --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
  --pid-path=/run/nginx.pid \
  --lock-path=/run/lock/subsys/nginx \
  --user=nginx --group=nginx \
  --with-compat \
  --with-file-aio \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_gzip_static_module \
  --with-http_gunzip_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_mp4_module \
  --with-stream=dynamic \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-pcre --with-pcre-jit \
  --with-threads \
  --add-dynamic-module=$BUILD_DIR/ModSecurity-nginx

make -j$(nproc)
make install

# -------------------------------------------------------
# Create nginx user and required dirs if fresh install
# -------------------------------------------------------
getent group nginx &>/dev/null || groupadd nginx
id nginx &>/dev/null || useradd -r -s /sbin/nologin -d /var/lib/nginx -g nginx nginx
mkdir -p /var/lib/nginx/tmp/{client_body,proxy,fastcgi,uwsgi,scgi}
chown -R nginx:nginx /var/lib/nginx

# -------------------------------------------------------
# Clone or update OWASP CRS
# -------------------------------------------------------
echo "[6/6] Setting up OWASP CRS..."
if [ ! -d /etc/nginx/owasp-crs ]; then
  git clone https://github.com/coreruleset/coreruleset /etc/nginx/owasp-crs
else
  cd /etc/nginx/owasp-crs && git pull
fi

# -------------------------------------------------------
# Cleanup
# -------------------------------------------------------
rm -rf $BUILD_DIR

echo ""
echo "================================================"
echo "Done!"
nginx -V
echo "================================================"