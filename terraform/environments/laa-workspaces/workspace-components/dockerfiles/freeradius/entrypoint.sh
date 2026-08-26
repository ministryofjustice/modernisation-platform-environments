#!/bin/bash
set -e

# Generate clients.conf with the secret injected by ECS from Secrets Manager
cat > /etc/freeradius/3.0/clients.conf <<EOF
client localhost {
  ipaddr  = 127.0.0.1
  secret  = ${RADIUS_SECRET}
}

client workspaces_vpc {
  ipaddr  = ${VPC_CIDR}
  secret  = ${RADIUS_SECRET}
}
EOF

chmod 640 /etc/freeradius/3.0/clients.conf
chown root:freerad /etc/freeradius/3.0/clients.conf

exec freeradius -f
