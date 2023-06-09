#!/bin/bash
DISTRIBUTION_PATH="./distribution"

# Configure the k8s secrets to access the Kubeflow Katib mysql dependencies

# Generate a password
MYSQL_ROOT_PASSWORD=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow katib-mysql-sealedsecrets --from-literal=MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/katib/overlays/longhorn/katib-mysql-sealedsecrets.yaml