#!/usr/bin/env bash

# Script to distrust Emudhra certificates by adding them to the system's blacklist/blocklist and updating the CA trust.

B=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
S=/etc/pki/ca-trust/source

if command -v openssl >/dev/null 2>&1; then
  echo "openssl is available."
else
  echo "openssl is not available, exiting."
  exit 1
fi

if [[ ! -f $B ]]; then
  echo "Not found: $B, exiting."
  exit 1
fi

if [[ -d "$S/blacklist" ]]; then
  L=$S/blacklist
  V="a"
elif [[ -d "$S/blocklist" ]]; then
  L=$S/blocklist
  V="o"
else
  echo "ERROR: no blacklist/blocklist directory under $S" >&2
  echo "You need to create that directory manually:" >&2
  echo "$S/blacklist on old Linux distributions (based on RH 7.9)." >&2
  echo "$S/blacklist on newer Linux distributions." >&2
  echo "Then run the script again." >&2
  exit 1
fi
echo "Using $L"

D=$(mktemp -d)
cd "$D"
csplit -s -z -f cert- "$B" '/-----BEGIN TRUSTED CERTIFICATE-----/' '{*}'

for f in cert-*; do
  echo -n "Processing: $f ... "
  O=$(openssl x509 -noout -subject -in "$f"  2>/dev/null |grep -iP 'CN=\K(?:aaa certificate|emsign|emudhra)')
  if [[ -n $O ]]; then
    echo "dirty."
    F=$(openssl x509 -in "$f" -noout -fingerprint -sha256 |cut -d= -f2 | tr -d :)
    N=$(grep -oP 'CN=\K[^,]+' <<< $O |tr \\040 \\137)
    openssl x509 -in "$f" -out "$L/$N-$F.pem"
    echo "Extracted and added to the block list: $(openssl x509 -in "$f" -noout -subject)"
  else
    echo "clean."
  fi
done

echo
ls -l $L |grep '\.pem'
echo

for f in $L/*.pem; do
  echo -n "$(basename $f): "
  openssl x509 -in "$f" -noout -subject 2>/dev/null
done

echo -e "\nRunning extraction.\n"
update-ca-trust extract
echo "Run these commands now:"
echo "trust list --filter=bl${V}cklist"
echo "curl https://dv-g3b-emudhra.we-have-a-problem.com/"
echo

cd / && rm -rf "$D"