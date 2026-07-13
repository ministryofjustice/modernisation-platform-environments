#!/bin/bash
set -e

# Create LinOTP config directory
mkdir -p /etc/linotp

# Write encryption key to file from injected secret
echo "$LINOTP_ENC_KEY_VALUE" > /etc/linotp/encKey
chmod 600 /etc/linotp/encKey
chown -R linotp:linotp /etc/linotp

# Build DATABASE_URI from individual components
export LINOTP_DATABASE_URI="mysql+pymysql://${LINOTP_DB_USER}:${LINOTP_DB_PASSWORD}@${LINOTP_DB_HOST}/linotp3?charset=utf8"
export SECRET_FILE="/etc/linotp/encKey"

# Run LinOTP configuration in background (waits for LinOTP to be ready, then configures)
if [ "${ENABLE_AUTO_CONFIG:-true}" = "true" ]; then
    (
        sleep 30  # Give LinOTP time to start
        echo "Starting LinOTP automated configuration..."
        /usr/local/bin/configure_linotp.py
        if [ $? -eq 0 ]; then
            echo "LinOTP configuration completed successfully"
        else
            echo "WARNING: LinOTP configuration failed, check logs"
        fi
    ) &
fi

# Call original LinOTP entrypoint with bootstrap (creates audit keys + runs migrations)
exec /app/entrypoint.sh --with-bootstrap

