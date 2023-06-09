#!/bin/bash
DISTRIBUTION_PATH="./distribution"

# Configure the k8s secrets to access the Kubeflow Pipelines dependencies

# Generate access keys for Minio credentials
MINIO_ACCESS_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
MINIO_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow mlpipeline-minio-artifact --from-literal=accesskey=${MINIO_ACCESS_KEY} --from-literal=secretkey=${MINIO_SECRET_KEY} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/pipelines/overlays/longhorn/patches/minio/mlpipeline-minio-artifact-sealedsecret.yaml

# Generate the root password for MySQL
MYSQL_USER=root
MYSQL_PASS=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
kubectl create secret generic -n kubeflow mysql-secret --from-literal=username=${MYSQL_USER} --from-literal=password=${MYSQL_PASS} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/kubeflow/pipelines/overlays/longhorn/patches/mysql/mysql-sealedsecret.yaml