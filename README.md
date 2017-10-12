# Cross-Region Replication for RDS

I was recently asked if you can you set up cross-region replication on an RDS database instance? Yes you can!

Here is how!

# Motivation

Imagine you are pharmaceutical company with operations in one country and a distribution network in another.

Results of compute runs in your R&amp;D region must be replicated to another region for consumption by doctors and nurses.

For example, this could involve developing and distributing medication for cancer treatment.

<!-- Insert an architecture diagram including VPC, AZ, security groups, and EC2/RDS instances. -->

## Basic Concepts in RDS

### What is RDS

RDS is Amazon's Relational Database Service, a managed service for relational databases such as Amazon Aurora and MySQL. Amazon launched RDS in 2009 and support for popular Relational Database Management Systems (RDBMS) has been growing ever since. This includes open source and commercial RDBMS including at the time of writing MySQL, PostgreSQL, Maria DB (all open source), and Microsoft SQL Server and Oracle (commercial). In addition, Amazon released its own RDBMS, Amazon Aurora, in November 2014.

Amazon recommends using RDS for transactional workloads, otherwise know as Online Transaction Processing (OLTP) workloads.

### Multi-AZ availability

Multi-AZ availability creates and identical clone for your database in another availability zone. In case of a failure on the primary database, AWS automatically fails over to the secondary database.

This allows you to have an automated HA mechanism all within your virtual private cloud.

### RDS read replicas

Read replicas allow you to offload read workloads from the primary database. This can be useful if you need to meet have some users that primarily have read requirements (reporting) without affecting the write performance and user experience of users that primarily have write requirements (transaction processing).

### Promoting secondary databases to primary databases

Finally, you can promote read replicas to become your primary database. This can be useful in scenarios in which you need to perform a data migration from one region to another region.

For example, you can use read replicas to create a replica of your primary database in another region and then promote the read replica in the target region once the replication process has completed.

This will be the approach we will demonstrate and discuss in more detail in the following.

## Basic Security Configuration

We start by configuring our EC2 security group. We launch EC2 instances into this security group when accessing our RDS instance via the MySQL CLI.

In order to access the MySQL CLI from our computer, we open SSH port 22 (you can restrict this to only your current IP if you like to lock things down).

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+01+01.png)

One nice thing about security groups is that we can cross-reference other security groups when controlling access to AWS resources in the group.

We us this to restrict access to our RDS instance on port 3306 to resources in our EC2 security group.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+01+02.png)

## Setting Up Master Database in Source Region

We begin by setting up our master database in the source region.

For the purpose of this demonstration, we will use the Sydney region as our source region and the Singapore region as our target region. You can modify this according to your requirements.

In this section, we select our database engine, specify database details, and configure network and security settings of our RDS instance.

We begin by selecting a database engine. For demonstration purposes, we will use a free-tier eligible instance of MySQL. Your production requirements may differ so it is worthwhile consulting the AWS RDS documentation on the similarities and differences between the available RDS database engines.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+02+01.png)

After selecting MySQL as our database engine, we provide the instance specification.

You do not need to change the default settings shown in the screenshot below.

Multi-AZ availability is not eligible for the AWS free tier but is not required in our demo scenario.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+02+02.png)

Scroll down to set database settings such as database instance identifier and admin credentials.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+02+03.png)

We are now ready to launch our database into the RDS security group we set up earlier.

For convenience, I am setting an initial database name (this is optional).

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+02+04.png)

Click launch. RDS will now begin creating your RDS instance and database configuration.

After some time, RDS provides you with the details of the newly created database.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+02+04.png)

<!-- Do we need to note the AZ or can we access the instance from all AZs in the same/different region? -->

## Provisioning MySQL Client in Source Region

Our RDS security group is configured to only allow access from resources in our EC2 security group.

We launch an EC2 instance and provision the MySQL CLI to test our newly minted RDS database.

Select the standard AWS Linux AMI.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+03+01.png)

We'll use a free-tier compatible t2.micro EC2 instance type.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+03+02.png)

Scroll down to set the provisioning script. This will install the MySQL CLI on our EC2 instance

The script is provided in the scripts folder of this GitHub project.

You can either copy/paste or upload the script file.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+03+03.png)

Make sure to launch the instance into the EC2 security group we defined earlier. Otherwise we will not have access to our RDS instance.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+03+04.png)

Create a new EC2 keypair or use an existing one. Do not forget to download the keypair.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+03+05.png)

## Testing Database Connectivity via the MySQL CLI

In order to test our newly minted RDS database, we must log into the EC2 instance.

First, make sure you set the right file permissions on the PEM file you downloaded (EC2 keypair).

For example, CHMOD 400 (read by owner).

Copy the public IP from the EC2 instance dashboard.

Use SSH to log into the instance from your terminal using the ec2-user, public instance IP, and keypair.

You should now be connected to the EC2 instance (type yes to accept connecting to the instance).

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+04+01.png)

Once you are connected, you can use the MySQL CLI to connect.

Copy the RDS instance URL from the RDS instance dashboard.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+04+02.png)

You can now use the user and password you set up earlier to connect via the MySQL CLI.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+04+03.png)

<!-- Troubleshooting: what can go wrong and how to fix it! -->

## Setting Up Slave Database in Target Region

Setting up the slave database/read replica is straightforward.

Select the RDS instance in the RDS instance dashboard and click on instance actions.

Select the create read replica action and proceed.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+05+01.png)

Now, set the instance specification, database settings, and networking for the read replica.

You can use the settings as per below (master as source, slave as target, Singapore as target region).

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+05+02.png)

Cross-region replication and transfer speed.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+05+03.png)

## Modifying RDS Instance Details

We need to launch our RDS replica into the right security group so we do not expose it to unnecessary security risks.

Before you proceed, replicate the RDS and EC2 security groups we created in the Sydney region in the Singapore region.

RDS places the read replica into the default security group.

<!-- Need to confirm and need to add a screenshot -->

Use the modify instance action to make the required changes.

<!-- Need to add a screenshot that shows the action -->

 Assign the read replica to our RDS security group in the Singapore region.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+06+01.png)

## Provisioning MySQL Client in Target Region

Follow the same steps as before to launch an EC2 instance into the EC2 security group you configured in the Singapore region. Make sure you download the EC2 keypair for this region as before.

Make a note of the public IP address of the EC2 instance.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+07+01.png)

## Testing Database Connection and Data Replication

Connect to EC2 instance in target region.

You should now have two open SSH connections.

Verify the database details via the MySQL CLI in the target region.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+08+01.png)

Switch over to the target region. The database details are identical.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+08+02.png)

Next, let's create a table in the source region.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+08+03.png)

The changes are replicated to the target region.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+08+04.png)

## Promoting Read Replica to Primary Database

You can promote the secondary database/read replica to become your primary database.

This can be an effective strategy to perform a full-scale data migration between two AWS regions.

Select the RDS instance in the RDS dashboard in the target region (Singapore).

You can promote this instance to a primary database using an instance action.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+09+01.png)

Make sure the read replica has had time to catch up to the master database and avoid creating new records in the master database to avoid loosing transactional data.

![Screenshot](https://github.com/kploesser/aws-cross-region-rds/raw/master/images/image+09+02.png)

## Alternative Architecture Options

An alternative to using read replicas and promoting secondaries to primaries for cross-region data migration is to use the Amazon Database Migration Service (DMS).

DMS allows you to consolidate and replicate existing databases in your on-prem data centre or Amazon virtual private cloud to a target in AWS.

Bear in mind that DMS is a paid services and you will incur additional charges unlike in the case of read replicas.

Another alternative for data replication within a single region is to use multi-AZ availability. This means that the primary database is automatically replicated to a failover instance in another AZ.

However, this option does not allow access to the secondary database. In case of a failure, the primary instance automatically fails over to the secondary instance.

## Cost Impact

Read replicas use the same instance pricing as the primary database. You can optimise your monthly costs by following guidelines to optimise the configuration and use of RDS instances.

Data transfer between the master database and read replica itself is free of charge.

<!-- Confirm this is indeed the case!! It may be useful to calculate 1 or 2 scenarios. -->

## References

Enabling cross-region replication on RDS:

Information on RDS read replicas
https://aws.amazon.com/rds/details/read-replicas/

Security group details
http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.Scenarios.html

Connecting to DB instance via CLI
https://dev.mysql.com/doc/refman/5.7/en/connecting.html

Creating tables in MySQL
https://dev.mysql.com/doc/refman/5.7/en/creating-tables.html

Amazon RDS for MySQL pricing
https://aws.amazon.com/rds/mysql/pricing/
