terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }

  backend "s3" {
    bucket = "devops.joeho.xyz"
    key    = "hello-world/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

variable "public_key" {
  type = string
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "k3s_ssh_key"
  public_key = "${var.public_key}"
}

resource "aws_vpc" "k3s_vpc" {

  cidr_block = "172.16.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name = "k3s_vpc"
  }
}

resource "aws_subnet" "k3s_subnet" {
  vpc_id     = aws_vpc.k3s_vpc.id
  cidr_block = "172.16.10.0/24"
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.k3s.id
  allocation_id = aws_eip.elastic_ip.id
}

resource "aws_eip" "elastic_ip" {
}

resource "aws_internet_gateway" "k3s_gw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = {
    Name = "k3s_gw"
  }
}

resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.k3s_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s_gw.id
  }

}

resource "aws_security_group_rule" "allow_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_k8s_api_ingress" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group" "security_group" {
  vpc_id = aws_vpc.k3s_vpc.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ec2_key.key_name
  subnet_id              = aws_subnet.k3s_subnet.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    Name = "k3s"
  }
}

output "hostname" {
  value = aws_eip.elastic_ip.public_dns
}

output "ip" {
  value = aws_eip.elastic_ip.public_ip
}
