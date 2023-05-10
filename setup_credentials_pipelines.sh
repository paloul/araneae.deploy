#!/bin/bash

# Configure the k8s secrets to access the Kubeflow Pipelines dependencies

# Generate the passwords for admin 'postgres' account and the user for the specific kubeflow dbs
POSTGRESQL_DB_USER=<<__kubeflow.pipelines.postgres.db.username__>>
POSTGRESQL_DB_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
POSTGRESQL_POSTGRES_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow pipelines-postgresql-secret --from-literal=postgres-password=${POSTGRESQL_POSTGRES_PASS} --from-literal=username=${POSTGRESQL_DB_USER} --from-literal=password=${POSTGRESQL_DB_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/pipelines/base/resources/postgresql-secret.yaml