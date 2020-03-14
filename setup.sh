#!/bin/bash


RED='\033[1;31m'
BLUE='\033[1;34m'
if [ "$#" -ne 2 ]; then
    printf "${RED}please pass your Google Cloud Project Name and desired Chainlink Admin Email\nExample: ./run.sh my-google-project admin@acme.org\n"
    exit 1
fi

#The ID of the project you just created.
PROJECT_ID=$1
#your email address, used to login into the node's web portal
USER_EMAIL=$2
#the description and name for the Service Account
SA_DESC="chainlink terraform service account"
SA_NAME=cl-terraform

echo "Using Google Cloud Project: $PROJECT_ID"
echo "Chainlink admin username: $USER_EMAIL"


#enable the required API Services
gcloud services enable compute.googleapis.com --project $PROJECT_ID
gcloud services enable container.googleapis.com --project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project $PROJECT_ID

#create Service Account
gcloud iam service-accounts create $SA_NAME --display-name "$SA_DESC" --project $PROJECT_ID

#SA needs some time to propagate before we can get its email
sleep 5

#extract the email from the newly generated Service Account
SA_EMAIL=$(gcloud --project $PROJECT_ID iam service-accounts list \
    --filter="displayName:$SA_DESC" \
    --format='value(email)')

#download a JSON private key for the Service Account
gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL

#grant our new Service Account the role of Project Editor
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SA_EMAIL \
    --role roles/editor

#IAM needs some time to propagate before we can can execute
sleep 5

#fill project id in terraform variables - $sed needs backup file path in OS X.
cp chainlink.tfvars.template chainlink.tfvars
case `uname` in
  Darwin)
    sed -i ".bak" "s/REPLACE_ME_WITH_PROJECT_ID/$PROJECT_ID/g" chainlink.tfvars
    sed -i ".bak" "s/REPLACE_ME_WITH_USER_EMAIL/$USER_EMAIL/g" chainlink.tfvars
    rm chainlink.tfvars.bak
  ;;
  Linux)
    sed -i "s/REPLACE_ME_WITH_PROJECT_ID/$PROJECT_ID/g" chainlink.tfvars
    sed -i "s/REPLACE_ME_WITH_USER_EMAIL/$USER_EMAIL/g" chainlink.tfvars
  ;;
esac


terraform init .

terraform plan -var-file="chainlink.tfvars" --out tf.plan

terraform apply tf.plan
