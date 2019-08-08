#!/bin/bash

# this script compares the existing cert against the new cert in vault, and
# replaces existing cert only if it is newer and valid.

# TODO serious refactoring to apply DRY 
# TODO help / argument checking
# TODO need a force flag - also something that checks if all things match

# function defs
get_fingerprint() {
    openssl x509 -noout -fingerprint -in <(echo "$1") | awk -F= '{print $2}'
}

get_enddate() {
    date --date="$(openssl x509 -noout -enddate -in <(echo "$1")| awk -F= '{print $2}')" --iso-8601
}

deploy_cert() {
    NEWCERT=$1
    NEWKEY=$2
    NEWCHAIN=$3
    NEWFULLCHAIN=$4
    EXISTING_CERT_PATH=$5
    EXISTING_KEY_PATH=$6
    EXISTING_CHAIN_PATH=$7
    EXISTING_FULLCHAIN_PATH=$8
    
    echo "deploying cert to $EXISTING_CERT_PATH"
    echo "$NEWCERT" > $EXISTING_CERT_PATH
    echo "$NEWKEY"  > $EXISTING_KEY_PATH
    echo "$NEWCHAIN"  > $EXISTING_CHAIN_PATH
    echo "$NEWFULLCHAIN"  > $EXISTING_FULLCHAIN_PATH

}

# arguments
DOMAIN=$1
CERT_PREFIX=$2
EXISTING_CERT_DIR="${CERT_PREFIX}/${DOMAIN}"
EXISTING_CERT_PATH="${EXISTING_CERT_DIR}/cert.pem"
EXISTING_KEY_PATH="${EXISTING_CERT_DIR}/cert.key"
EXISTING_CHAIN_PATH="${EXISTING_CERT_DIR}/chain.pem"
EXISTING_FULLCHAIN_PATH="${EXISTING_CERT_DIR}/fullchain.pem"

# variables
ONE_WEEK=604800
TODAY=$(date --iso-8601)


NEWCERT_VAULT_PATH="/secret/letsencrypt/${DOMAIN}/cert.pem"
NEWKEY_VAULT_PATH="/secret/letsencrypt/${DOMAIN}/cert.key"
NEWCHAIN_VAULT_PATH="/secret/letsencrypt/${DOMAIN}/chain.pem"
NEWFULLCHAIN_VAULT_PATH="/secret/letsencrypt/${DOMAIN}/fullchain.pem"

# Get new cert info
NEWCERT=$(vault read -field=value $NEWCERT_VAULT_PATH) || exit -1
NEWKEY=$(vault read -field=value $NEWKEY_VAULT_PATH) || exit -1
NEWCHAIN=$(vault read -field=value $NEWCHAIN_VAULT_PATH) || exit -1
NEWFULLCHAIN=$(vault read -field=value $NEWFULLCHAIN_VAULT_PATH) || exit -1
NEWCERT_FINGERPRINT=$(get_fingerprint "$NEWCERT")
NEWCERT_ENDDATE=$(get_enddate "$NEWCERT")

# we need to bail right away if we don't have a valid new cert
if [ "$NEWCERT_FINGERPRINT" == "" ]
then
    echo "no valid new cert found!"
    exit -1
fi

#echo "new fingerprint: $NEWCERT_FINGERPRINT"
#echo "new enddate: $NEWCERT_ENDDATE"

# Get existing cert info if it exists.  if it doesn't exist, we don't need to
# check it, we can just deploy.

if [ -e $EXISTING_CERT_PATH ]
then 
    EXISTING_CERT=$(cat $EXISTING_CERT_PATH)
    EXISTING_CERT_FINGERPRINT=$(get_fingerprint "$EXISTING_CERT")
    EXISTING_CERT_ENDDATE=$(get_enddate "$EXISTING_CERT")
else
    # create destination dir if needed
    if [ ! -d $EXISTING_CERT_DIR ]
    then 
        mkdir -p $EXISTING_CERT_DIR
    fi
    deploy_cert "$NEWCERT" "$NEWKEY" "$NEWCHAIN" "$NEWFULLCHAIN" "$EXISTING_CERT_PATH" "$EXISTING_KEY_PATH" "$EXISTING_CHAIN_PATH" "$EXISTING_FULLCHAIN_PATH"
    exit 0
fi

#echo "existing fingerprint: $EXISTING_CERT_FINGERPRINT"
#echo "existing enddate: $EXISTING_CERT_ENDDATE"


# check that new cert is different
# if it is the same, exit normally, this will be the common case
if [ "$NEWCERT_FINGERPRINT" == "$EXISTING_CERT_FINGERPRINT" ]
then
    exit -1
fi

# check that new cert is newer than current cert
if [ "$EXISTING_CERT_ENDDATE" \> "$NEWCERT_ENDDATE" ]
then
    echo "existing cert expiration is older, exiting"
    exit -1
fi

# check that new cert is not expired
if [ "$NEWCERT_ENDDATE" \< "$TODAY" ]
then
    echo "new cert is expired, exiting"
    exit -1
fi

# if we made it this far, the cert looks good, replace it

deploy_cert "$NEWCERT" "$NEWKEY" "$NEWCHAIN" "$NEWFULLCHAIN" "$EXISTING_CERT_PATH" "$EXISTING_KEY_PATH" "$EXISTING_CHAIN_PATH" "$EXISTING_FULLCHAIN_PATH"



#openssl x509 -in <(vault read -field=value /secret/apidb.org/cert.pem) -noout -checkend 8640000


