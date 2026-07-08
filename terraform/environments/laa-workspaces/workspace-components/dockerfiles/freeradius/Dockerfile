FROM freeradius/freeradius-server:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libperl-dev \
    libconfig-file-perl \
    cpanminus \
    git \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest Config::File LWP::UserAgent LWP::Protocol::https Try::Tiny

RUN git clone --depth 1 https://github.com/LinOTP/linotp-auth-freeradius-perl.git \
    /usr/share/linotp/linotp-auth-freeradius-perl

COPY config/sites-available/linotp /etc/freeradius/3.0/sites-available/linotp
COPY config/mods-available/perl /etc/freeradius/3.0/mods-available/perl
COPY config/rlm_perl.ini /etc/linotp/rlm_perl.ini
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /etc/linotp \
    && mkdir -p /etc/freeradius/3.0/sites-enabled \
    && mkdir -p /etc/freeradius/3.0/mods-enabled \
    && rm -f /etc/freeradius/3.0/sites-enabled/default \
              /etc/freeradius/3.0/sites-enabled/inner-tunnel \
    && rm -f /etc/freeradius/3.0/mods-enabled/eap \
    && ln -sf /etc/freeradius/3.0/sites-available/linotp \
              /etc/freeradius/3.0/sites-enabled/linotp \
    && ln -sf /etc/freeradius/3.0/mods-available/perl \
              /etc/freeradius/3.0/mods-enabled/perl

EXPOSE 1812/udp 1813/udp

ENTRYPOINT ["/entrypoint.sh"]
