#!/bin/bash

declare -a users=$1

[ -f testusers.ldif ] && mv testusers.ldif testusers.ldif.bak
for username in ${users[@]}; do
    dn=cn=$username,ou=Users,dc=moj,dc=com
    echo Getting user $dn...
    ldapsearch -Y external -Q -H ldapi:// -LLL -b "$dn" >> testusers.ldif
done

awk '!NF {delete seen;print;next}; !seen[$0]++' testusers.ldif > testusers.no-duplicates.ldif
#mv testusers.no-duplicates.ldif testusers.ldif
