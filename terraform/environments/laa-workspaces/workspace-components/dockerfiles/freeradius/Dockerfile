# SECURITY FIX: Multi-stage build to reduce attack surface
# Use latest stable version (3.2.10) to get updated openssl, curl, gnutls28, python3
FROM freeradius/freeradius-server:3.2.10 AS builder

USER root

# Install build dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libperl-dev \
    libconfig-file-perl \
    cpanminus \
    git \
    ca-certificates \
    libssl-dev \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install Perl modules (fixes libdbi-perl CVEs)
RUN cpanm --notest Config::File LWP::UserAgent LWP::Protocol::https Try::Tiny

# Clone LinOTP auth module
RUN git clone --depth 1 https://github.com/LinOTP/linotp-auth-freeradius-perl.git \
    /usr/share/linotp/linotp-auth-freeradius-perl

# Runtime stage - SECURITY FIX: Use latest version (3.2.10) to fix curl/openssl/gnutls28 CVEs
FROM freeradius/freeradius-server:3.2.10

USER root

# SECURITY FIX: Upgrade all packages and aggressively remove Python 2.7
# Python 2.7 has 4 unfixable HIGH CVEs and is not needed by FreeRADIUS
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get purge -y python2.7* libpython2.7* || true && \
    apt-get install -y --no-install-recommends \
    libperl5.* \
    libconfig-file-perl \
    libwww-perl \
    liblwp-protocol-https-perl \
    ca-certificates && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/lib/python2.7 /usr/share/python2.7 && \
    ! dpkg -l | grep -q python2.7 || echo "Warning: python2.7 still present"

# Copy only necessary artifacts from builder
COPY --from=builder /usr/local/share/perl /usr/local/share/perl
COPY --from=builder /usr/local/lib/x86_64-linux-gnu/perl /usr/local/lib/x86_64-linux-gnu/perl
COPY --from=builder /usr/share/linotp/linotp-auth-freeradius-perl /usr/share/linotp/linotp-auth-freeradius-perl

# Copy configuration files
COPY config/sites-available/linotp /etc/freeradius/3.0/sites-available/linotp
COPY config/mods-available/perl /etc/freeradius/3.0/mods-available/perl
COPY config/rlm_perl.ini /etc/linotp/rlm_perl.ini
COPY entrypoint.sh /entrypoint.sh

# Set up FreeRADIUS configuration
RUN chmod +x /entrypoint.sh && \
    mkdir -p /etc/linotp && \
    mkdir -p /etc/freeradius/3.0/sites-enabled && \
    mkdir -p /etc/freeradius/3.0/mods-enabled && \
    rm -f /etc/freeradius/3.0/sites-enabled/default \
          /etc/freeradius/3.0/sites-enabled/inner-tunnel \
          /etc/freeradius/3.0/mods-enabled/eap && \
    ln -sf /etc/freeradius/3.0/sites-available/linotp \
          /etc/freeradius/3.0/sites-enabled/linotp && \
    ln -sf /etc/freeradius/3.0/mods-available/perl \
          /etc/freeradius/3.0/mods-enabled/perl

EXPOSE 1812/udp 1813/udp

ENTRYPOINT ["/entrypoint.sh"]
