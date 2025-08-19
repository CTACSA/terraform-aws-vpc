variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets with CIDR and AZ"
  type = list(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Private subnets with CIDR and AZ"
  type = list(object({
    cidr = string
    az   = string
  }))
}


variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "use_nat_gateway" {
  description = "If true, use AWS NAT Gateway; if false, use FCK-NAT instance"
  type        = bool
}

variable "fck_nat_ami" {
  description = "AMI ID for FCK-NAT. If null or empty, latest is fetched from SSM."
  type        = string
  default     = null
}

variable "fck_nat_instance_type" {
  description = "Instance type for FCK-NAT instance"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

