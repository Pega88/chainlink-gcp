#!/bin/bash

export GCP_PROJECT_ID=pega88-dlt
export SA_DESC="chainlink terraform service account"
export SA_NAME=cl-terraform

echo "project_name= \"$GCP_PROJECT_ID\"" >> terraform/chainlink.tfvars


#enable the required API Services
gcloud services enable compute.googleapis.com --project $GCP_PROJECT_ID
gcloud services enable container.googleapis.com --project $GCP_PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project $GCP_PROJECT_ID

#create service account
gcloud iam service-accounts create $SA_NAME --display-name=$SA_DESC --project $GCP_PROJECT_ID

#extract the email from the newly generated service account
SA_EMAIL=$(gcloud --project $GCP_PROJECT_ID iam service-accounts list \
    --filter="displayName:$SA_DESC" \
    --format='value(email)')

#download a JSON key
gcloud iam service-accounts keys create terraform/key.json --iam-account=$SA_EMAIL

#grant our new Service Account the role of Project Editor
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member serviceAccount:$SA_EMAIL \
    --role roles/editor

pushd terraform
terraform init .
terraform plan -var-file="chainlink.tfvars" --out tf.plan
#can/should be done manually to inspect the result of the plan, otherwise we could just apply directly.
terraform apply tf.plan
popd