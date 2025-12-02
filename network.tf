
resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "vpc-igw"
  }
}


# Egress-Only Internet Gateway (for IPv6 outbound)
resource "aws_egress_only_internet_gateway" "egress" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "vpc-eoigw"
  }
}


resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 0)
  availability_zone               = data.aws_availability_zones.azs.names[0]
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  tags = {
    Name = "ipv6-subnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 1)
  availability_zone               = data.aws_availability_zones.azs.names[1]
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = false
  tags = {
    Name = "ipv6-subnet"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_egress_only_internet_gateway.egress.id
  }

  tags = {
    Name = "public-rtb"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_egress_only_internet_gateway.egress.id
  }
  lifecycle {
    ignore_changes = [route]
  }

  tags = {
    Name = "private-rtb"
  }
}


resource "aws_security_group" "fck_nat_sg" {
  name        = "fck-nat-sg"
  description = "Allow traffic from VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
