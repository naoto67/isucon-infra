provider "aws" {
  region  = "ap-northeast-1"
  profile = var.profile
}

// spot fleetリクエストを利用するためのロール作成
resource "aws_iam_role" "spotfleet_role" {
  name               = "spotfleet_role"
  assume_role_policy = data.aws_iam_policy_document.assume_spotfleet.json
}

resource "aws_iam_policy_attachment" "spotfleet_policy_attachment" {
  name       = "spotfleet_policy_attachment"
  roles      = [aws_iam_role.spotfleet_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
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

// ec2
// spot instance pattern
resource "aws_spot_fleet_request" "default" {
  iam_fleet_role = aws_iam_role.spotfleet_role.arn

  target_capacity                     = 3
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = "true"

  launch_specification {
    ami                         = "ami-0cfa3caed4b487e77"
    instance_type               = "t3.small"
    spot_price                  = "0.009"
    key_name                    = aws_key_pair.isucon_key.id
    vpc_security_group_ids      = [aws_default_security_group.default.id]
    subnet_id                   = aws_subnet.public.id
    associate_public_ip_address = true

    tags = {
      Name = "isucon-instance"
    }
  }
}
