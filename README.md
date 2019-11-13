# Chainlink node running on Kubernetes

## Prerequisits
In order to have a smooth installation, it is assumed you have created a project on Google Cloud Platform and have installed and authenticated the [GCloud SDK](https://cloud.google.com/sdk/install).

## Basic Installation
The most basic installation can be done running `setup.sh`.

## Advanced Installation
Users familiar with terraform are encouraged to fill the `terraform/chainlink.tfvars` with their preferred configuration and use remote state storage on a Google Cloud Storage or AWS S3 bucket.