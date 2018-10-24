# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI):

* [sandbox](sandbox) deploys a single instance running the Cloudera Docker container.  This is a good fit for people who want to explore Cloudera on OCI at a very low cost.
* [development](development) is the next step up and deploys five instances.
* [production](production) is the most powerful preconfigured option.  It provides high density, high performance and high availability.  It is an appropriate entry point for scaling up a production big data practice.
* [n-node](n-node) deploys a cluster of arbitrary size.
* [ad-spanning](ad-spanning) is a variation of the N-Node deployment that spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/cloud-partners/oci-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/cloud-partners/oci-cloudera-edh.git
    cd oci-couchbase/terraform
    ls

## Password and User Details
Modify the script `startup.sh` and look for the `MAIN CLUSTER CONFIGURATION` section - this is which you can input your contact information, and set up the Cloudera Manager credentials prior to deployment.

## Deploy
Pick a module and `cd` into the directory containing it.  You can deploy with the following Terraform commands:

    terraform init
    terraform plan
    terraform apply

When complete, Terraform will print information on how you can access the deployment.

## Post Deployment
Post deployment is automated using a scripted process that uses the Bash and Cloudera Manager API via Python.  Clusters are preconfigured with tunings based around instance type (in the `cmx.py` script).  Log in to the Bastion host after Terraform completes, then run the following commands to watch installation progress.  The public IP will output as a result of the Terraform completion:

    ssh -i ~/.ssh/id_rsa opc@<public_ip_of_bastion>
    sudo su -
    screen -r

Cluster provisioning can take up to half an hour.  After SCM setup is complete, you can monitor progress  directly using the Cloudera Manager UI.  The URL for this is also output as part of the Terraform provisioning process.

## Security and Post-Deployment Auditing
Note that as part of this deployment, ssh keys are used for root level access to provisioned hosts in order to setup software.  The key used is the same as the OPC user which has super-user access to the hosts by default.  If enhanced security is desired, then the following steps should be taken after the Cluster is up and running:

Remove ssh private keys from Utility host:

    rm -f /home/opc/.ssh/id_rsa

Replace the authorized_keys file in `/root/.ssh/` on all hosts with the backup copy

    sudo mv /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

    terraform destroy
