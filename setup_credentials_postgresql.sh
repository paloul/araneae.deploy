#!/bin/bash
DISTRIBUTION_PATH="./distribution"


POSTGRESQL_DB_PASS=${password:-$(python3 -c 'import secrets; print(secrets.token_hex(16))')}} # The password to set for solo user access
POSTGRESQL_POSTGRES_PASS=${postgresql-password:-$(python3 -c 'import secrets; print(secrets.token_hex(16))')}} # The password to set for postgres access
POSTGRESQL_REPL_PASS=${replication-password:-$(python3 -c 'import secrets; print(secrets.token_hex(16))')}} # The password to set for the replication account

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2 # Optional to see the parameter:value result
   fi

  shift
done

kubectl create secret generic -n postgresql postgresql-secret --from-literal=password=${POSTGRESQL_DB_PASS} --from-literal=postgres-password=${POSTGRESQL_POSTGRES_PASS} --from-literal=replication-password=${POSTGRESQL_REPL_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/postgresql/base/postgresql-secret.yaml