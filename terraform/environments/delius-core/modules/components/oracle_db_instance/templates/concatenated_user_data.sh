${default}

${ssh_setup}

###########################################
## SCHEDULE SCRIPTS AND SECURITY UPDATES ##
###########################################

cat > ~/mycron << EOF
# */15 * * * * /usr/bin/db/sync_users
# 0 0 * * * yum -y update --security
*/10 * * * * /usr/bin/db/sync_s3
EOF
crontab ~/mycron
rm ~/mycron
