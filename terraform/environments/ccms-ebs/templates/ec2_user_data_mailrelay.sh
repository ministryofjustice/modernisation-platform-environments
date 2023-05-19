#!/usr/bin/env bash

EHOSTS=/etc/hosts
ERCONF=/etc/resolv.conf

hostnamectl set-hostname mailrelay

yum install -y amazon-cloudwatch-agent cyrus-sasl-plain curl jq nc postfix telnet
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

H=$(ec2-metadata --local-ipv4 |cut -d' ' -f2)
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > $${EHOSTS}.new
echo "$${H} ${hostname} ${hostname}.${smtp_fqdn}" >> $${EHOSTS}.new
mv $${EHOSTS}.new $${EHOSTS}

sed -i "s/^search .*/search ${smtp_fqdn}/" $${ERCONF}

S=$(aws secretsmanager get-secret-value --secret-id ses-smtp-credentials --region eu-west-2 |jq '.SecretString')
U=$(cut -d'"' -f 3 <<< $${S} |tr -d \\134)
P=$(cut -d'"' -f 5 <<< $${S} |tr -d \\134)

echo "[email-smtp.us-west-2.amazonaws.com]:587 $${U}:$${P}" > /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
echo -e "\n# Configuration for SES:\n" >> /etc/postfix/main.cf

postconf -e \
  "myhostname = mailrelay.${smtp_fqdn}" \
  "relayhost = [email-smtp.us-west-2.amazonaws.com]:587" \
  "smtp_sasl_auth_enable = yes" \
  "smtp_sasl_security_options = noanonymous" \
  "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
  "smtp_tls_security_level = encrypt" \
  "smtp_tls_note_starttls_offer = yes" \
  "smtp_use_tls = yes"

systemctl enable postfix
systemctl restart postfix