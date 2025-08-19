variable "use_nat_gateway" {
  description = "true = NAT Gateway, false = FCK-NAT"
  type        = bool
}

variable "fck_nat_ami" {
  description = "Optional FCK-NAT AMI ID. Leave empty to auto-fetch."
  type        = string
  default     = ""
}

