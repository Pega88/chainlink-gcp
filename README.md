# Chainlink node on Google Cloud Platform

## Context
This repository helps you install a high-available pool of chainlink nodes on Google Cloud Platform, running on Kubernetes and Cloud SQL. The setup follows the best practices put forward by the [Chainlink documentation](https://docs.chain.link/docs/best-security-practices).

## Prerequisits
In order to have a smooth installation, it is assumed you have created a project on Google Cloud Platform and have installed and authenticated the [Google Cloud SDK](https://cloud.google.com/sdk/install) on your local machine.

You will also need to install [Terraform](https://www.terraform.io/). This setup has been tested with version `0.12`.

## Installation
To enable Terraform to manage resources on Google Cloud Platform, it needs a projects and a Service Account with access to that project to authenticate with. Following steps guide you to create a project in Google Cloud Platform, create a Service Account and grant it the required role to deploy the resources we need.

If you are familiar with Google Cloud Platform or have an existing projects, feel free to skip related steps.

**SECURITY REMARK:** We will be downloading the private key of a Service Account. Please ensure safekeeping of this Service Account, as it grants whoever has access to it, access to your node. However, if you lose it without compromising it (e.g. hard disk crash), you can generate a new key as long as you have access to the Google Account that you initialized the Google Cloud SDK with (probably your personal GMail account). For more information on Service Accounts and best practices, visit [Google's documentation](https://cloud.google.com/iam/docs/understanding-service-accounts).

While all steps have been tested on Mac OS X Catalina, they should be portable to any other OS capable of running Terraform and the Google Cloud SDK. All steps should be followed in sequence and executed in the same shell, as specific variables are used across multiple steps.


### 1. Getting the code
We'll need the files in this repo, so go ahead and clone it to your local machine. If you're unfamiliar with git, download a ZIP of this repo and extract it.
```bash
git clone https://github.com/Pega88/chainlink-gcp
cd chainlink-gcp
```
### 2. Preparing your environment
Follow [Google's documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects) and create a new project and __enable billing__ on the project. If you are a new user you might be elegible to use the [Free Tier](https://cloud.google.com/free/), currently $300. Once done, fill your project ID in the variable below and execute all commands in your Terminal.

```bash
#our project id - must be unique
export PROJECT_ID=ENTER_YOUR_PROJECT_ID_HERE
#the description and name for the Service Account
export SA_DESC="chainlink terraform service account"
export SA_NAME=cl-terraform
```

### 3. Create Service Account with required access in Google Cloud Platform
We'll now prepare our Google Cloud Platform (GCP) environment.
```bash
#create a project
gcloud projects create $PROJECT_ID

#enable the required API Services
gcloud services enable compute.googleapis.com --project $PROJECT_ID
gcloud services enable container.googleapis.com --project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project $PROJECT_ID

#create Service Account
gcloud iam service-accounts create $SA_NAME --display-name=$SA_DESC --project $PROJECT_ID

#extract the email from the newly generated Service Account
SA_EMAIL=$(gcloud --project $PROJECT_ID iam service-accounts list \
    --filter="displayName:$SA_DESC" \
    --format='value(email)')

#download a JSON private key for the Service Account
gcloud iam service-accounts keys create terraform/key.json --iam-account=$SA_EMAIL

#grant our new Service Account the role of Project Editor
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SA_EMAIL \
    --role roles/editor
```

### 3. Create resources in Google Cloud Platform using Terraform
After having created a project and a Service Account, we can use [Terraform](https://www.terraform.io/downloads.html) to create and manage all other resources. Users experienced with the Google Cloud SDK can also create all resources using the `gcloud` CLI, however the use of Terraforms allows us to leverage all advantages of [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code), hence we limit the amount of `gcloud` commands above to a bare minimum.

#### Initialize Terraform
```bash
pushd terraform
terraform init .
```
#### Plan changes
Using the `plan` command, we pass terraform our variables and write the plan to an out-file. This allows us to inspect the changes that are proposed.
```bash
terraform plan -var-file="chainlink.tfvars" --out tf.plan
```
#### Apply changes
If all changes look good and there are no warnings, go ahead and `apply` your newly-generated plan.

```bash
terraform apply tf.plan
popd
```
