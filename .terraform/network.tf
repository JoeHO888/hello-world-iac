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