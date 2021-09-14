#!/bin/bash

RED='\033[1;31m'
BLUE='\033[1;34m'
normal=$(tput sgr0)
if [ "$#" -ne 2 ]; then
    printf "${RED}please pass your Google Cloud Project Name and desired Chainlink Admin Email\nExample: ./run.sh my-google-project admin@acme.org\n${normal}"
    exit 1
fi

#The ID of the project you just created.
PROJECT_ID=$1
#your email address, used to login into the node's web portal
USER_EMAIL=$2
#the description and name for the Service Account
SA_DESC="chainlink terraform service account"
SA_NAME=cl-terraform

printf "Using Google Cloud Project: ${BLUE}$PROJECT_ID\n${normal}"
printf "Chainlink admin username: ${BLUE}$USER_EMAIL\n${normal}\n"

#enable the required API Services
gcloud services enable compute.googleapis.com --project $PROJECT_ID
gcloud services enable container.googleapis.com --project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project $PROJECT_ID
gcloud services enable serviceusage.googleapis.com --project $PROJECT_ID
gcloud services enable iam.googleapis.com --project $PROJECT_ID
gcloud services enable cloudbilling.googleapis.com --project $PROJECT_ID

#check if SA exists from a previous run
SA_EMAIL=$(gcloud --project $PROJECT_ID iam service-accounts list \
    --filter="displayName:$SA_DESC" \
    --format='value(email)')

if [ -z "$SA_EMAIL" ]
then
	printf "${BLUE}Creating a Service Account to be used with Terraform\n${normal}...\n"
	#create Service Account
	gcloud iam service-accounts create $SA_NAME --display-name "$SA_DESC" --project $PROJECT_ID

	#SA needs some time to propagate before we can get its email
	sleep 5

	#extract the email from the newly generated Service Account
	SA_EMAIL=$(gcloud --project $PROJECT_ID iam service-accounts list \
	    --filter="displayName:$SA_DESC" \
	    --format='value(email)')
else
	printf "${BLUE}Reusing existing Service Account $SA_EMAIL\n${normal}"
fi

printf "${BLUE}Generating Service Account Key\n${normal}...\n"
#download a JSON private key for the Service Account
gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL

printf "${BLUE}Granting Service Account IAM Access\n${normal}...\n"
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


terraform init

terraform plan -var-file="chainlink.tfvars" --out tf.plan

#option to review/cancel
read -p "Press enter to continue"

terraform apply tf.plan

#explicitly show sensitive output
terraform output -json