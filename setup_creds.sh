#!/bin/bash
DISTRIBUTION_PATH="./distribution"
COOKIE_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
OIDC_CLIENT_ID=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
OIDC_CLIENT_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

# Create the Keycloak secrets for Cookie, OIDC-Client ID and OIDC-Client Secret with KubeSeal
kubectl create secret generic -n auth oauth2-proxy --from-literal=client-id=${OIDC_CLIENT_ID} --from-literal=client-secret=${OIDC_CLIENT_SECRET} --from-literal=cookie-secret=${COOKIE_SECRET} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/oidc-auth/overlays/keycloak/oauth2-proxy-secret.yaml

DATABASE_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
POSTGRESQL_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
KEYCLOAK_ADMIN_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
KEYCLOAK_MANAGEMENT_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')

kubectl create secret generic -n auth keycloak-secret --from-literal=admin-password=${KEYCLOAK_ADMIN_PASS} --from-literal=database-password=${DATABASE_PASS} --from-literal=management-password=${KEYCLOAK_MANAGEMENT_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/oidc-auth/overlays/keycloak/keycloak-secret.yaml
kubectl create secret generic -n auth keycloak-postgresql --from-literal=postgresql-password=${DATABASE_PASS} --from-literal=postgresql-postgres-password=${POSTGRESQL_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/oidc-auth/overlays/keycloak/postgresql-secret.yaml

email=${email:-admin@araneae.io} # Email param with default admin@araneae.io
username=${username:-admin} # Username param with default admin
firstname=${firstname:-FirstName} # First Name param with default FirstName
lastname=${lastname:-LastName} # Last Name param with default LastName
password=${password:-$(python3 -c 'import secrets; print(secrets.token_hex(16))')} # Password for admin credentials generated 

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2 // Optional to see the parameter:value result
   fi

  shift
done

yq eval -j -P ".users[0].username = \"${username}\" | .users[0].email = \"${email}\" | .users[0].firstName = \"${firstname}\" | .users[0].lastName = \"${lastname}\" | .users[0].credentials[0].value = \"${password}\" | .clients[0].clientId = \"${OIDC_CLIENT_ID}\" | .clients[0].secret = \"${OIDC_CLIENT_SECRET}\"" ${DISTRIBUTION_PATH}/oidc-auth/overlays/keycloak/kubeflow-realm-template.json | kubectl create secret generic -n auth kubeflow-realm --dry-run=client --from-file=kubeflow-realm.json=/dev/stdin -o json | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/oidc-auth/overlays/keycloak/kubeflow-realm-secret.yaml