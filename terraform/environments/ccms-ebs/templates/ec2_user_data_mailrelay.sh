#!/usr/bin/env bash

EHOSTS=/etc/hosts
ERCONF=/etc/resolv.conf

cloudwatch_agent_setup() {
    amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config
}

etc_hosts() {
    H=$(ec2-metadata --local-ipv4 |cut -d' ' -f2)
    echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > $${EHOSTS}.new
    echo "$${H} ${hostname} ${hostname}.${mp_fqdn} ${hostname}.${smtp_fqdn}" >> $${EHOSTS}.new
    mv $${EHOSTS}.new $${EHOSTS}
}

etc_resolv_conf() {
    sed -i "s/^search .*/search ${mp_fqdn} ${smtp_fqdn}/" $${ERCONF}
}

hostname_setup() {
    hostnamectl set-hostname mailrelay
}

postfix_setup() {
    S=$(aws secretsmanager get-secret-value --secret-id ses-smtp-credentials --region eu-west-2 |jq '.SecretString')
    U=$(cut -d'"' -f 3 <<< $${S} |tr -d \\134)
    P=$(cut -d'"' -f 5 <<< $${S} |tr -d \\134)

    if [[ $${#U} -eq 20 ]] && [[ $${#P} -eq 44 ]]; then
        echo "Setting up credentials in /etc/postfix/sasl_passwd"
        echo "[email-smtp.us-west-2.amazonaws.com]:587 $${U}:$${P}" > /etc/postfix/sasl_passwd
        postmap hash:/etc/postfix/sasl_passwd
        chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
        echo -e "\n# Configuration for SES:\n" >> /etc/postfix/main.cf

        echo "Running postconf with additional options."
        postconf -e \
            "myhostname = mailrelay.${smtp_fqdn}" \
            "relayhost = [email-smtp.us-west-2.amazonaws.com]:587" \
            "smtp_sasl_auth_enable = yes" \
            "smtp_sasl_security_options = noanonymous" \
            "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
            "smtp_tls_security_level = encrypt" \
            "smtp_tls_note_starttls_offer = yes" \
            "smtp_use_tls = yes"

        echo "Enabling the Postfix service."
        systemctl enable postfix
        echo "Starting the Postfix service."
        systemctl restart postfix
    else
      echo "Error: incorrect length of credentials. Please investigate."
    fi
}

yum_install() {
    yum install -y amazon-cloudwatch-agent cyrus-sasl-plain jq nc postfix telnet
}

hostname_setup
etc_hosts
etc_resolv_conf
yum_install
postfix_setup
cloudwatch_agent_setup