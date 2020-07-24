provider "aws" {
  region  = "ap-northeast-1"
  profile = var.profile
}

// VPC setting
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "isucon-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "isucon-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "public-1a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  // トラフィックをinternet gatewayを通じてinternetへ
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "isucon-route-table-public"
  }
}

resource "aws_route_table_association" "local" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

// security group setting
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.default.id

  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "isucon_key" {
  key_name   = "isucon-key"
  public_key = file(var.ssh_file_path)
}

resource "aws_network_interface" "private_ip" {
  count       = 3
  subnet_id   = aws_subnet.public.id
  private_ips = [format("10.0.1.10%d", count.index + 1)]

  tags = {
    Name = "private-network-interface"
  }
}

resource "aws_instance" "app" {
  count = 3

  ami           = "ami-0cfa3caed4b487e77"
  instance_type = "t3.small"
  key_name      = aws_key_pair.isucon_key.id

  network_interface {
    network_interface_id = element(aws_network_interface.private_ip, count.index).id
    device_index         = 0
  }
}

resource "aws_eip" "default" {
  count = 3
  vpc   = true

  instance = element(aws_instance.app, count.index).id
}
