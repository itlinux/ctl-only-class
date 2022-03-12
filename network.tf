locals {
  base_cidr_block = var.base_cidr_block
}
resource "aws_vpc" "main" {
  count                = var.number_of_clusters
  cidr_block           = local.base_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = format("%s-k8s", random_id.id[count.index].hex)
  }
}
resource "aws_internet_gateway" "igw" {
  count  = var.number_of_clusters
  vpc_id = aws_vpc.main[count.index].id
  tags = {
    Name = format("%s-k8s", random_id.id[count.index].hex)
  }
}
resource "aws_subnet" "main" {
  count             = var.number_of_clusters
  vpc_id            = aws_vpc.main[count.index].id
  cidr_block        = cidrsubnet(aws_vpc.main[count.index].cidr_block, 8, 1 + count.index)
  availability_zone = var.availability_zone

  tags = {
    Name = format("%s-k8s", random_id.id[count.index].hex)
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
    Name = format("%s-k8s", random_id.id[count.index].hex)
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

  # you gotta open everything up within the
  # network otherwise services don't respond
  # and you have to micro-manage all of the
  # ports for all of the services
  ingress {
    description = "all-internal"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_vpc.main[count.index].cidr_block]
  }
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = var.trusted_cidr
  }
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "TCP"
    cidr_blocks = var.trusted_cidr
  }
  ingress {
    from_port   = "123"
    to_port     = "123"
    protocol    = "TCP"
    cidr_blocks = var.trusted_cidr
  }
  ingress {
    from_port   = "8443"
    to_port     = "8443"
    protocol    = "TCP"
    cidr_blocks = var.trusted_cidr
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = var.trusted_cidr
  }

  # access to the API server
  ingress {
    description = "API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidr
  }
  #
  # ingress {
  #   description = "smtp"
  #   from_port   = 25
  #   to_port     = 25
  #   protocol    = "tcp"
  #   cidr_blocks = var.trusted_cidr
  # }
  # ingress {
  #   description = "dns"
  #   from_port   = 53
  #   to_port     = 53
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }


  # access to the nodeport ports
  ingress {
    description = "nodeport"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidr
  }
  # access to the prometheus port
  ingress {
    description = "prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidr
  }
  # access to the grafana port
  ingress {
    description = "grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidr
  }
  # access to the prometheus-kube-state-metrics
  ingress {
    description = "metrics"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidr
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
