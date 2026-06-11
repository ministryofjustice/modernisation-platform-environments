#!/bin/bash
set -e

# Write encryption key to file from injected secret
echo "$LINOTP_ENC_KEY_VALUE" > /etc/linotp/encKey
chmod 600 /etc/linotp/encKey
chown linotp:linotp /etc/linotp/encKey 2>/dev/null || true

# Build DATABASE_URI from individual components
export LINOTP_DATABASE_URI="mysql+pymysql://${LINOTP_DB_USER}:${LINOTP_DB_PASSWORD}@${LINOTP_DB_HOST}/linotp3?charset=utf8"

# Write LinOTP config
cat > /etc/linotp/linotp.cfg <<EOF
DATABASE_URI = "${LINOTP_DATABASE_URI}"
SECRET_FILE = "/etc/linotp/encKey"
ROOT_CA_FILE = None
SESSION_COOKIE_SECURE = False
APACHE_WSGI = True
EOF

# Initialize DB schema (idempotent — safe to run on every start)
linotp init database || echo "DB init returned non-zero (may already be initialized)"

# Create admin user (idempotent — fails silently if already exists)
linotp local-admins add admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
    || linotp local-admins change-password admin --password "${LINOTP_ADMIN_PASSWORD}" 2>/dev/null \
    || echo "Admin user already configured"

# Start Apache in foreground
exec apache2ctl -D FOREGROUND
