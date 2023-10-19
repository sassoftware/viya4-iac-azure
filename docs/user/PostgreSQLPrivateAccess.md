# Azure Database for PostgreSQL Flexible Server with the Private access (VNet Integration)

Azure Database for PostgreSQL Flexible Server is a managed service that you can use to run, manage, and scale highly available PostgreSQL servers in the cloud. Azure Database for PostgreSQL - Flexible Server supports two types of mutually exclusive network connectivity methods to connect to your flexible server. The two options are:

* Public access (allowed IP addresses)
* Private access (VNet Integration)

In this document, we will focus on PostgreSQL server with Private access (VNet Integration).

You can deploy a flexible server into your Azure virtual network (VNet). Azure virtual networks provide private and secure network communication. Resources in a virtual network can communicate through private IP addresses that were assigned on this network. In Private access, the connections to the PostgreSQL server are restricted to only within your virtual network. To learn more about it, refer to [Private access (VNet Integration)](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking#private-access-vnet-integration).

To create PostgreSQL Flexible Server with the private access connectivity method use the example file provided [here](../../examples/sample-input-postgres.tfvars).

# Connect Azure Database for PostgreSQL Flexible Server with the private access connectivity method

Since the PostgreSQL Flexible server is in a virtual network, you can only connect to the server from other Azure services in the same virtual network as the server. The virtual machine must be created in the same region and same subscription. The Linux virtual machine can be used as an SSH tunnel to manage your database server. To connect and manage the server, you can either create a separate Linux virtual machine or use the jump server that was created with your cluster. Below we will see the steps to connect to the jump server and access the PostgreSQL Flexible Server.

## Connect to jump server

Create an SSH connection with the VM using Bash or PowerShell. At your prompt, open an SSH connection to your virtual machine. Replace the IP address with the one from your VM, and replace SSH user's private key used during cluster creation.

```bash
ssh -i <path_to_jump_svr_private_key> jumpuser@10.111.12.123
```

## Install PostgreSQL client tools

You need to install the postgresql-client tool to be able to connect to the server.

```bash
sudo apt-get update
sudo apt-get install postgresql-client
```

Connections to the database are enforced with SSL, hence you need to download the public SSL certificate.

```bash
wget --no-check-certificate https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem
```

With the psql client tool installed, we can now connect to the server from your local environment.

```bash
psql --host=mydemoserver-pg.postgres.database.azure.com --port=5432 --username=myadmin --dbname=postgres --set=sslmode=require --set=sslrootcert=DigiCertGlobalRootCA.crt.pem
```
