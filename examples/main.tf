
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "../modules/vpc"
  name    = "example-vpc"
  vpc_cidr = "10.0.0.0/16"

  public_subnets = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" }
  ]

  private_subnets = [
    { cidr = "10.0.11.0/24", az = "us-east-1a" },
    { cidr = "10.0.12.0/24", az = "us-east-1b" }
  ]

  use_nat_gateway       = var.use_nat_gateway
  fck_nat_ami           = var.fck_nat_ami
  fck_nat_instance_type = "t3.micro"

  tags = { Environment = "dev" }
}

