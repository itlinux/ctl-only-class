locals {
  base_cidr_block = var.base_cidr_block
}
resource "aws_vpc" "main" {
  count                = var.number_of_clusters
  cidr_block           = local.base_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = format("%s-ceots2022", random_id.id[count.index].hex)
  }
}
resource "aws_internet_gateway" "igw" {
  count  = var.number_of_clusters
  vpc_id = aws_vpc.main[count.index].id
  tags = {
    Name = format("%s-coets2022", random_id.id[count.index].hex)
  }
}
resource "aws_subnet" "main" {
  count             = var.number_of_clusters
  vpc_id            = aws_vpc.main[count.index].id
  cidr_block        = cidrsubnet(aws_vpc.main[count.index].cidr_block, 8, 1 + count.index)
  availability_zone = var.availability_zone

  tags = {
    Name = format("%s-ceots2022", random_id.id[count.index].hex)
  }
}

resource "aws_route_table" "main" {
  count  = var.number_of_clusters
  vpc_id = aws_vpc.main[count.index].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[count.index].id
  }
  tags = {
    Name = format("%s-coets2022", random_id.id[count.index].hex)
  }
}
resource "aws_route_table_association" "subnet-association" {
  count          = var.number_of_clusters
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[count.index].id
}


resource "aws_security_group" "controller" {
  count       = var.number_of_clusters
  name        = "controller_sg"
  description = "Allow necessary controller traffic"
  vpc_id      = aws_vpc.main[count.index].id

dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = var.trusted_cidr
    }
  }
dynamic "ingress" {
    for_each = var.sg_ports_udp
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "udp"
      cidr_blocks = var.UDP_Ports_IP_ALLOWED
    }
  }
ingress {
    description = "all-internal"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_vpc.main[count.index].cidr_block]
  }
ingress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "ICMP"
    cidr_blocks = var.trusted_cidr
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

tags    = {
    Name  = "controller_sg"
    owner = var.owner
  }
}
