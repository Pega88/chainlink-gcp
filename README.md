# Chainlink node running on Kubernetes

## Prerequisits
In order to have a smooth installation, it is assumed you have created a project on Google Cloud Platform and have installed and authenticated the [Google Cloud SDK](https://cloud.google.com/sdk/install).

You will also need to install [Terraform](https://www.terraform.io/). This setup has been tested with version `0.12`.

## Basic Installation
The most basic installation can be done running `setup.sh`. You will need to fill the value for the `GCP_PROJECT_ID` variable. Once filled, it can be run using

`sh setup.sh`

This will take following steps:
1. Enable required API's
2. Create a [Service Account](https://cloud.google.com/iam/docs/understanding-service-accounts) in your project
3. Create a JSON Key for this Service Account
4. Grant the Service Account the [IAM role](https://cloud.google.com/iam/docs/understanding-roles) of Project Editor
5. Setup the infrastructure using terrafom.

## Advanced Installation

Users familiar with terraform are encouraged to fill the `terraform/chainlink.tfvars` with their preferred configuration and use remote state storage on a Google Cloud Storage or AWS S3 bucket.

You also might want to consider restring the Role, as Project Editor is a wide role that is overgranted, which is against the security best-practice of least-privileged acccess.