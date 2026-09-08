# Use latest available version (3.4.4 is newest on Docker Hub)
# Security fixes come from apt-get upgrade below
FROM linotp/linotp:3.4.4

USER root

# SECURITY FIX: Apply all available security patches
# Remove python2.7 (deprecated, has unfixable CVEs) - LinOTP uses Python 3
# This fixes CVEs in: openssl, curl, gnutls28, linux kernel packages
# NOTE: Cannot upgrade Flask/Werkzeug/PyJWT - LinOTP 3.4.4 requires specific versions
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get remove -y python2.7 python2.7-minimal libpython2.7-stdlib libpython2.7-minimal || true && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# SECURITY FIX: Upgrade system packages with known HIGH vulnerabilities
# Upgrades libssh2, expat, acl, attr, gzip to latest available versions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssh2-1 \
    libexpat1 \
    acl \
    attr \
    gzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# SECURITY FIX: Upgrade Perl modules to fix CVEs
# - Socket module to 2.041+ (fixes CRITICAL CVE-2026-12087)
# - Other Perl core modules to latest versions
RUN apt-get update && \
    apt-get install -y --no-install-recommends cpanminus build-essential && \
    cpanm --notest Socket IO::Socket::SSL Net::SSLeay && \
    apt-get remove -y cpanminus build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cpanm

# SECURITY FIX: Upgrade setuptools to fix CVE-2024-6345 (HIGH)
# Install pymysql via pip (required for MySQL connection in virtualenv)
RUN pip install --no-cache-dir --upgrade setuptools pymysql && \
    rm -rf /root/.cache

COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
COPY configure_linotp.py /usr/local/bin/configure_linotp.py
COPY configure_linotp_cli.sh /usr/local/bin/configure_linotp_cli.sh
COPY configure_linotp_api.sh /usr/local/bin/configure_linotp_api.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh && \
    chmod +x /usr/local/bin/configure_linotp.py && \
    chmod +x /usr/local/bin/configure_linotp_cli.sh && \
    chmod +x /usr/local/bin/configure_linotp_api.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
