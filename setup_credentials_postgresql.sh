#!/bin/bash
DISTRIBUTION_PATH="./distribution"


password=${password:-thepassword} # The password to set for solo user access
postgres-password=${postgresql-password:-thepostgrespassword} # The password to set for postgres access
replication-password=${replication-password:-thereplicationpassword} # The password to set for the replication account

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2 # Optional to see the parameter:value result
   fi

  shift
done

kubectl create secret generic -n postgresql postgresql-secret --from-literal=password=${password} --from-literal=postgres-password=${postgres-password} --from-literal=replication-password=${replication-password} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/postgresql/base/postgresql-secret.yaml