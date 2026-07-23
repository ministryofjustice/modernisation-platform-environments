#!/bin/bash
# rollback-nginx.sh
# Restores nginx binary, modules, and /etc/nginx from a backup created by
# build-nginx-modsec.sh.
#
# Usage:
#   ./rollback-nginx.sh                          # uses most recent backup
#   ./rollback-nginx.sh /var/backups/nginx/20260707-153000   # specific backup

set -euo pipefail

BACKUP_ROOT=/var/backups/nginx

if [ $# -ge 1 ]; then
  BACKUP_DIR="$1"
elif [ -f "$BACKUP_ROOT/latest" ]; then
  BACKUP_DIR=$(cat "$BACKUP_ROOT/latest")
else
  echo "No backup specified and no $BACKUP_ROOT/latest pointer found."
  echo "Available backups:"
  ls -1 "$BACKUP_ROOT" 2>/dev/null || echo "  (none found in $BACKUP_ROOT)"
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory not found: $BACKUP_DIR"
  exit 1
fi

echo "================================================"
echo "Rolling back nginx using backup: $BACKUP_DIR"
if [ -f "$BACKUP_DIR/nginx-V.txt" ]; then
  echo "That backup was taken from this build:"
  cat "$BACKUP_DIR/nginx-V.txt"
fi
echo "================================================"

read -rp "Proceed with rollback? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# -------------------------------------------------------
# If there's a live new master from an in-progress USR2
# upgrade, shut it down first so we don't fight it.
# -------------------------------------------------------
if [ -f /run/nginx.pid.oldbin ]; then
  echo "Detected an in-progress binary upgrade (nginx.pid.oldbin exists)."
  NEW_PID=$(cat /run/nginx.pid 2>/dev/null || true)
  OLD_PID=$(cat /run/nginx.pid.oldbin 2>/dev/null || true)

  if [ -n "$NEW_PID" ] && kill -0 "$NEW_PID" 2>/dev/null; then
    echo "Stopping new master (PID $NEW_PID)..."
    kill -QUIT "$NEW_PID" || true
    sleep 1
  fi

  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Old master (PID $OLD_PID) is still alive — restoring its workers..."
    kill -HUP "$OLD_PID" || true
  fi
  rm -f /run/nginx.pid.oldbin
fi

# -------------------------------------------------------
# Restore binary and modules
# -------------------------------------------------------
if [ -f "$BACKUP_DIR/nginx.bin" ]; then
  echo "Restoring /usr/sbin/nginx..."
  cp -a "$BACKUP_DIR/nginx.bin" /usr/sbin/nginx
else
  echo "!! No nginx.bin found in backup — binary not restored."
fi

if [ -d "$BACKUP_DIR/modules" ]; then
  echo "Restoring dynamic modules..."
  rm -rf /usr/lib64/nginx/modules
  cp -a "$BACKUP_DIR/modules" /usr/lib64/nginx/modules
fi

for f in "$BACKUP_DIR"/libmodsecurity.so*; do
  [ -e "$f" ] && cp -a "$f" /usr/local/modsecurity/lib/ 2>/dev/null || true
done

# -------------------------------------------------------
# Restore config (including owasp-crs)
# -------------------------------------------------------
if [ -d "$BACKUP_DIR/etc-nginx" ]; then
  echo "Restoring /etc/nginx..."
  rm -rf /etc/nginx.rollback-old
  mv /etc/nginx /etc/nginx.rollback-old
  cp -a "$BACKUP_DIR/etc-nginx" /etc/nginx
  echo "(previous /etc/nginx saved to /etc/nginx.rollback-old in case you need it)"
else
  echo "!! No etc-nginx found in backup — config not restored."
fi

# -------------------------------------------------------
# Validate and restart
# -------------------------------------------------------
echo "Validating restored config..."
if ! nginx -t; then
  echo "!! Restored config failed validation. Not restarting nginx."
  echo "!! Inspect /etc/nginx and $BACKUP_DIR manually."
  exit 1
fi

echo "Restarting nginx on restored binary..."
systemctl restart nginx || (nginx -s stop 2>/dev/null; nginx)

echo "================================================"
echo "Rollback complete."
nginx -V
echo "================================================"