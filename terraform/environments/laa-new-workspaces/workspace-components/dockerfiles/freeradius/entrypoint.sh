#!/bin/bash
set -e

# Generate clients.conf with the secret injected by ECS from Secrets Manager.
# This must be /etc/freeradius/clients.conf (not .../3.0/clients.conf) -
# that's the actual confdir radiusd.conf's $INCLUDE clients.conf resolves
# against; a .../3.0/ copy is silently never read.
cat > /etc/freeradius/clients.conf <<EOF
client localhost {
  ipaddr  = 127.0.0.1
  secret  = ${RADIUS_SECRET}
}

client workspaces_vpc {
  ipaddr  = ${VPC_CIDR}
  secret  = ${RADIUS_SECRET}
}
EOF

chmod 640 /etc/freeradius/clients.conf
chown root:freerad /etc/freeradius/clients.conf

exec freeradius -f
