# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI):

* [single-ad](single-ad) deploys a cluster of arbitrary size.
* [multi-ad](multi-ad) spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/cloud-partners/oci-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/cloud-partners/oci-cloudera-edh.git
    cd oci-couchbase/terraform
    ls

## Deploy
Pick a module and `cd` into the directory containing it.  You can deploy with the following Terraform commands:

    terraform init
    terraform plan
    terraform apply

When complete, Terraform will print information on how you can access the deployment.

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

    terraform destroy
