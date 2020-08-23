# Configure the AWS provider
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

locals {
  public_a_subnet_cidr_block = "10.1.1.0/24"
  public_b_subnet_cidr_block = "10.1.4.0/24"
  private_subnet_cidr_block = "10.1.2.0/24"
}

module "vpc" {
  source = "./modules/vpc"
  cidr_block = "10.1.0.0/16"
  subnet = {
    public-a = {
      cidr_block = local.public_a_subnet_cidr_block
      availability_zone = "ap-south-1a"
    },
    public-b = {
      cidr_block = local.public_b_subnet_cidr_block
      availability_zone = "ap-south-1b"
    },
    private = {
      cidr_block = local.private_subnet_cidr_block
      availability_zone = "ap-south-1b"
    }
  }
}

resource "aws_security_group" "internal_http" {
  name = "allow http to public subnet"
  description = "Allow HTTP to public subnet"
  vpc_id = module.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [local.public_a_subnet_cidr_block, local.public_b_subnet_cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http" {
  name = "allow http to internet"
  description = "Allow HTTP to internet"
  vpc_id = module.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web-lb-egress" {
  name = "allow outgoing to internal network"
  description = "allow outgoing to internal network"
  vpc_id = module.vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [local.private_subnet_cidr_block]
  }
}

resource "aws_lb" "web" {
  name = "app-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.http.id, aws_security_group.web-lb-egress.id]
  subnets = [module.vpc.public_a_subnet_id, module.vpc.public_b_subnet_id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

module "ec2" {
  source = "./modules/ec2"
  instance_type = "t2.micro"
  subnet_id = module.vpc.private_subnet_id
  user_data = templatefile("${path.module}/init.tmpl", { dns_name = aws_lb.web.dns_name })
  security_groups = [aws_security_group.internal_http.id]

  tags = {
    Name = "hello-world-app"
  }
}

resource "aws_lb_target_group" "hello-world" {
  name = "hello-world-tg"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = module.vpc.id

  health_check {
    path = var.healthcheck_path
    port = 80
  }
}

resource "aws_lb_target_group_attachment" "hello-world" {
  target_group_arn = aws_lb_target_group.hello-world.arn
  target_id = module.ec2.instance_id
  port =  80
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.web.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.hello-world.arn
  }
}
