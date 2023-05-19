#!/bin/bash
DISTRIBUTION_PATH="./distribution"

# Configure the k8s secrets to access the Kubeflow Pipelines dependencies

# Generate the passwords
MYSQL_USER=root
MYSQL_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow mysql-secret --from-literal=username=${MYSQL_USER} --from-literal=password=${MYSQL_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/pipelines/overlays/rook-ceph/patches/mysql-secret.yaml