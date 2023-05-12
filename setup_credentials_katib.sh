#!/bin/bash

# Configure the k8s secrets to access the Kubeflow Katib mysql dependencies

# Generate a password
MYSQL_ROOT_PASSWORD=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow katib-mysql-secrets --from-literal=MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/katib/overlays/rook-ceph/patches/katib-mysql-secrets.yaml