# sandbox
This sets up an instance running the Cloudera VM Docker image.  Once complete, Terraform will print URLs you can use to access the sandbox.  This work was done for the [OCI Jumpstart](https://oci.qloudable.com/demoLab/public-preview/5aca74fe-8615-4699-8b0a-32595a19cee7).  You probably want to look at [development](../development) instead.

If you want to SSH into the machine running Docker and check on status, you can do this:

    ssh -i ~/.ssh/id_rsa opc@<sandbox_public_ip>
    sudo docker ps

Output from that command will show a container ID that you can us to start an interactive shell on the container:

    sudo docker exec -it <container_id> bash
