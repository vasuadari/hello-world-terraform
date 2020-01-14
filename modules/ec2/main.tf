variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type = map
}

variable "user_data" {
  type = string
}

variable "security_groups" {
  type = list
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  user_data = var.user_data
  security_groups = var.security_groups

  tags = var.tags
}

output "instance_id" {
  value = aws_instance.web.id
}
