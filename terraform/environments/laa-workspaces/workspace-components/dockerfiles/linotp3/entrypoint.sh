#!/bin/bash
set -e

echo "Waiting for Database..."
# Wait for database to be ready
until mysql -h"$LINOTP_DB_HOST" -u"$LINOTP_DB_USER" -p"$LINOTP_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done
echo "Database started"

# Write encryption key from injected secret
echo "$LINOTP_ENC_KEY_VALUE" > /etc/linotp/encKey
chmod 600 /etc/linotp/encKey

# Set environment variables
export LINOTP_CFG="/etc/linotp/linotp.cfg"
export LINOTP_DATABASE_URI="mysql+pymysql://${LINOTP_DB_USER}:${LINOTP_DB_PASSWORD}@${LINOTP_DB_HOST}/linotp3?charset=utf8"
export FLASK_APP=linotp.app

echo "Using configuration file: $LINOTP_CFG"
echo "--- Bootstrapping LinOTP ---"

# Initialize database (idempotent - safe to run multiple times)
linotp init database 2>&1 || echo "Database already initialized"

# Generate audit keys (idempotent)
linotp init audit-keys 2>&1 || echo "Audit keys already exist"

echo "--- Starting LinOTP ---"

# Run LinOTP configuration in background using CLI
if [ "${ENABLE_AUTO_CONFIG:-true}" = "true" ]; then
    (
        sleep 30  # Give LinOTP time to start
        echo "Starting LinOTP automated configuration (CLI-based)..."
        /usr/local/bin/configure_linotp_cli.sh
        if [ $? -eq 0 ]; then
            echo "✅ LinOTP configuration completed successfully"
        else
            echo "WARNING: LinOTP configuration failed, check logs"
        fi
    ) &
fi

echo "Starting gunicorn on 0.0.0.0:5000 ..."
# Start gunicorn with LinOTP app
exec gunicorn --bind 0.0.0.0:5000 --workers 1 --threads 4 --timeout 120 'linotp.app:create_app()'

