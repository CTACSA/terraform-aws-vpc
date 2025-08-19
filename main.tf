terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

##############################
# VPC + Subnets
##############################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

##############################
# Public Subnets
##############################

resource "aws_subnet" "public" {
  for_each                = { for idx, subnet in var.public_subnets : idx => subnet }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value.az

  tags = merge(var.tags, { Name = "${var.name}-public-${each.key}" })
}

##############################
# Private Subnets
##############################

resource "aws_subnet" "private" {
  for_each          = { for idx, subnet in var.private_subnets : idx => subnet }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}


##############################
# Public Route Table
##############################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

##############################
# NAT Resources
##############################

# NAT Gateway (when use_nat_gateway = true)
resource "aws_eip" "nat" {
  count = var.use_nat_gateway ? 1 : 0
  vpc   = true
  tags  = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(aws_subnet.public[*].id, 0)

  tags = merge(var.tags, { Name = "${var.name}-nat-gateway" })
}

# Fetch latest FCK-NAT AMI if none provided
data "aws_ssm_parameter" "fck_nat_latest" {
  count = var.use_nat_gateway || (var.fck_nat_ami != null && var.fck_nat_ami != "") ? 0 : 1
  name  = "/aws/service/fck-nat/latest/ami-id"
}

# FCK-NAT Instance (when use_nat_gateway = false)
resource "aws_instance" "fck_nat" {
  count                       = var.use_nat_gateway ? 0 : 1
  ami                         = var.fck_nat_ami != null && var.fck_nat_ami != "" ? var.fck_nat_ami : data.aws_ssm_parameter.fck_nat_latest[0].value
  instance_type               = var.fck_nat_instance_type
  subnet_id                   = element(aws_subnet.public[*].id, 0)
  associate_public_ip_address = true
  source_dest_check           = false

  tags = merge(var.tags, { Name = "${var.name}-fck-nat" })
}

##############################
# Private Route Table
##############################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route" "private_nat" {
  count = 1
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.use_nat_gateway ? aws_nat_gateway.this[0].id : null
  instance_id            = var.use_nat_gateway ? null : aws_instance.fck_nat[0].id
}

resource "aws_route_table_association" "private" {
  cou

