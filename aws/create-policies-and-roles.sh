#!/bin/bash

aws iam create-policy \
  --profile araneae \
  --policy-name araneae-lb-controller \
  --policy-document file://aws/iam-policies/lb-controller-v2_2_0-iam_policy.json

eksctl create iamserviceaccount \
  --cluster=araneae \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::654383687924:policy/araneae-lb-controller \
  --override-existing-serviceaccounts \
  --profile araneae \
  --approve

aws iam create-policy \
  --profile araneae \
  --policy-name araneae-cluster-autoscaler \
  --policy-document file://aws/iam-policies/cluster-autoscaler-policy.json

eksctl create iamserviceaccount \
  --cluster=araneae \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::654383687924:policy/araneae-cluster-autoscaler \
  --override-existing-serviceaccounts \
  --profile araneae \
  --approve

aws iam create-policy \
  --profile araneae \
  --policy-name araneae-external-dns \
  --policy-document file://aws/iam-policies/external-dns-policy.json

eksctl create iamserviceaccount \
  --cluster=araneae \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::654383687924:policy/araneae-external-dns \
  --override-existing-serviceaccounts \
  --profile araneae \
  --approve

aws iam create-policy \
  --profile araneae \
  --policy-name araneae-cert-manager \
  --policy-document file://aws/iam-policies/cert-manager-iam_policy.json

eksctl create iamserviceaccount \
  --cluster=araneae \
  --namespace=cert-manager \
  --name=cert-manager \
  --attach-policy-arn=arn:aws:iam::654383687924:policy/araneae-cert-manager \
  --override-existing-serviceaccounts \
  --profile araneae \
  --approve
