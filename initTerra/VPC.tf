provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}
################### VPC #######################
resource "aws_vpc" "d10_vpc" {
  cidr_block = "10.0.0.0/16"
    
    tags = {
    "Name" = "D10VPC"
  }
}
################## IGW #######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.d10_vpc.id
}
############### ROUTE TABLE ################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.d10_vpc.id
}
############# Routes #########################
resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
############ Association #######################
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

############### SUBNETS ####################
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.d10_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "d10_public | us-east-1a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.d10_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "d10_public | us-east-1b"
  }
}