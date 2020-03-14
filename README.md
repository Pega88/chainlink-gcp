# Hosting Chainlink Node on Google Cloud Using Terraform

## Context
This repository helps you install a high-available pool of chainlink nodes on Google Cloud Platform, running on Kubernetes and Cloud SQL. The setup follows the best practices put forward by the [Chainlink documentation](https://docs.chain.link/docs/best-security-practices).

## Prerequisits
In order to have a smooth installation, it is assumed you have created a project on Google Cloud Platform and have installed and authenticated the [Google Cloud SDK](https://cloud.google.com/sdk/install) on your local machine.

You will also need to install [Terraform](https://www.terraform.io/). This setup has been tested with version `0.12`.

## Installation
To enable Terraform to manage resources on Google Cloud Platform, it needs a projects and a Service Account with access to that project to authenticate with. Following steps guide you to create a project in Google Cloud Platform, create a Service Account and grant it the required role to deploy the resources we need.

If you are familiar with Google Cloud Platform or have an existing projects, feel free to skip related steps.

**SECURITY REMARK:** We will be downloading the private key of a Service Account. Please ensure safekeeping of this Service Account, as it grants whoever has access to it, access to your node. However, if you lose it without compromising it (e.g. hard disk crash), you can generate a new key as long as you have access to the Google Account that you initialized the Google Cloud SDK with (probably your personal Gmail account). For more information on Service Accounts and best practices, visit [Google's documentation](https://cloud.google.com/iam/docs/understanding-service-accounts).

While all steps have been tested on Mac OS X Catalina, they should be portable to any other OS capable of running Terraform and the Google Cloud SDK. All steps should be followed in sequence and executed in the same shell, as specific variables are used across multiple steps.


### 1. Getting the code
We'll need the files in this repo, so go ahead and clone it to your local machine. If you're unfamiliar with git, download a ZIP of this repo and extract it.
```bash
git clone https://github.com/Pega88/chainlink-gcp
cd chainlink-gcp
```
### 2. Preparing your environment
Follow [Google's documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects) and create a new project and __enable billing__ on the project. Remember the project id you chose.

![Creating a project](imgs/create-project.png)


### 3. Running the initialization
Run the `setup.sh` script passing 2 paramters:
* the project id of the project you created (**not** the project name). If you are unsure, you can run
`gcloud projects list` to get the list of your projects ids.
* the email address you wish to use for your Chainlink Node login. A password will be generated and shown as output of the script.

**for example**
```bash
sh setup.sh chainlink-dryrun-3 admin@gmail.com
```
