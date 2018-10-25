# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI).

* [sandbox](sandbox) deploys a single instance running the Cloudera Docker container.
* [production](production) deploys a cluster set up according to best practices in place at our financial services industry customers.  This is a push button way to get a production grade cluster in a few minutes.

Cloudera has a great sizing guide [here](https://www.cloudera.com/documentation/enterprise/release-notes/topics/hardware_requirements_guide.html).

| Application             | Worker                           | Bastion          | Utility          | Master           |
|-------------------------|----------------------------------|------------------|------------------|------------------|
| Small Development       | 3xVM.Standard2.16 with 1TB block | 1xVM.Standard2.4 | 1xVM.Standard2.8 |                  |                   
| Recommended Development | 3xVM.Standard2.24 with 1TB block | 1xVM.Standard2.4 | 1xVM.Standard2.8 |                  |
| Small Production        | 5xBM.DenseIO1.36                 | 1xVM.Standard2.4 | 1xVM.Standard2.8 | 2xVM.Standard2.8 |                                
| Recommended Production  | 5xBM.DenseIO2.52                 | 1xVM.Standard2.4 | 1xVM.Standard2.8 | 2xVM.Standard2.8 |                 

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
Post deployment is automated using a scripted process that uses the bash and Cloudera Manager API via Python.  Clusters are preconfigured with tunings based around instance type (in the `cmx.py` script).  Log in to the bastion host after Terraform completes, then run the following commands to watch installation progress.  The public IP will output as a result of the Terraform completion:

    ssh -i ~/.ssh/id_rsa opc@<public_ip_of_bastion>
    sudo su -
    screen -r

Cluster provisioning can take up to half an hour.  After SCM setup is complete, you can monitor progress directly using the Cloudera Manager UI.  The URL for this is also output as part of the Terraform provisioning process.

## Security and Post Deployment Auditing
Note that as part of this deployment, ssh keys are used for root level access to provisioned hosts in order to setup software.  The key used is the same as the OPC user which has root access to the hosts by default.  If enhanced security is desired, then the following steps should be taken after the cluster is up and running:

Remove SSH private keys from utility host:

    rm -f /home/opc/.ssh/id_rsa

Replace the `authorized_keys` file in `/root/.ssh/` on all hosts with the backup copy

    sudo mv /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

    terraform destroy
