# Terraform for hello-world app

## Objective

Setup hello-world app in a secure network which is served via the aws load-balancer.

## Details on how terraform sets up the infrastructure

### VPC

1. Creates VPC with 10.1.0.0/16 cidr block
2. A route table is created which routes all traffic to internet gateway
3. Two subnets are created with 10.1.1.0/24 and 10.1.4.0/24 cidr block and it
   is associated with previously created route table
4. A NAT gateway is created for private subnets
5. A route table is created which routes all traffic to NAT gateway
6. A private subnet with cidr block 10.1.2.0/24 and associated with previously
   created route table

### EC2

#### Instance

A t2.micro instance is created in a private subnet with a user data which installs
docker and starts the app on port 80. A security group is attached which allows
incoming traffic to public subnets and outgoing to internet.

#### Application Load Balancer

1. Creates an application load balancer with following security groups
   - allows incoming traffic to port 80
   - allows outgoing traffic to private subnet range

2. Creates a target group A with port 80 with healthcheck path

3. Attaches target group A with t2.micro instance in which app is deployed

4. Adds a listener rule to foward the incoming requests to target group A

### Instructions to use terraform

1. Install terraform version 0.12.19 via [brew](https://brew.sh/) or [asdf](https://asdf-vm.com/)

2. Install awscli via [brew](https://brew.sh/)

3. Create an IAM access keys with full access to EC2 and VPC and configure with your awscli client

   Run `aws configure` and set region to ap-south-1

4. Run `terraform init` to initializes all the plugins and modules

5. Run `terraform plan` to check the resources to be created

6. Run `terraform apply` to setup the complete infrastructure and to deploy the application
