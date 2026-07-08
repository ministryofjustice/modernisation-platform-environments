#!/bin/bash
set -e

# This script runs as root (via Dockerfile USER root during this step)
# or handles permission issues gracefully

# Write encryption key to file from injected secret
echo "$LINOTP_ENC_KEY_VALUE" > /etc/linotp/encKey
chmod 600 /etc/linotp/encKey || true
chown linotp:linotp /etc/linotp/encKey 2>/dev/null || true

# Build DATABASE_URI from individual components
export LINOTP_DATABASE_URI="mysql+pymysql://${LINOTP_DB_USER}:${LINOTP_DB_PASSWORD}@${LINOTP_DB_HOST}/linotp3?charset=utf8"

# Write LinOTP config
cat > /etc/linotp/linotp.cfg <<EOF
DATABASE_URI = ${LINOTP_DATABASE_URI}
SECRET_FILE = /etc/linotp/encKey
ROOT_CA_FILE = None
SESSION_COOKIE_SECURE = False
APACHE_WSGI = True
EOF

chmod 644 /etc/linotp/linotp.cfg || true
chown linotp:linotp /etc/linotp/linotp.cfg 2>/dev/null || true

# Run as linotp user for remaining commands
if [ "$(id -u)" = "0" ]; then
    # We're root, switch to linotp user for DB operations
    su -s /bin/bash linotp << 'EOSU'
        # Initialize DB schema (idempotent)
        linotp init database || echo "DB init returned non-zero (may already be initialized)"

        # Create admin user (idempotent)
        linotp local-admins add admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
            || linotp local-admins change-password admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
            || echo "Admin user already configured"
EOSU
else
    # Already running as non-root, just execute directly
    linotp init database || echo "DB init returned non-zero (may already be initialized)"
    linotp local-admins add admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
        || linotp local-admins change-password admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
        || echo "Admin user already configured"
fi

# Start Apache as root (required for port 80)
exec apache2ctl -D FOREGROUND
