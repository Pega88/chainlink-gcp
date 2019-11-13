#!/bin/bash
gcloud container clusters create chainlink-node
gcloud container clusters get-credentials chainlink-node
kubectl create configmap env-file --from-env-file=config/.env
kubectl create secret generic api-credentials --from-file=config/.api
kubectl create secret generic wallet-password  --from-file=config/.password
kubectl apply -f node.yaml
kubectl apply -f service.yaml