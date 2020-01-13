# Configure the AWS provider
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

module "vpc" {
  source = "./modules/vpc"
  cidr_block = "10.1.0.0/16"
  subnet = {
    public = {
      cidr_block = "10.1.1.0/24"
      availability_zone = "ap-south-1a"
    },
    private = {
      cidr_block = "10.1.2.0/24"
      availability_zone = "ap-south-1b"
    }
  }
}
