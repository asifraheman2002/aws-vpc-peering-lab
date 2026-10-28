terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Mumbai
  default_tags {
    tags = {
      Project = "EWB-VPC-Peering"
      Student = "Asif"
    }
  }
}

# -------------------------------------------------------------
# 0. KEY PAIR (Auto-generated RSA key saved locally as ewb-lab.pem)
# -------------------------------------------------------------
resource "tls_private_key" "lab_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ewb_lab" {
  key_name   = "ewb-lab"
  public_key = tls_private_key.lab_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.lab_key.private_key_pem
  filename = "${path.module}/ewb-lab.pem"
}

# -------------------------------------------------------------
# 1. NETWORKING: VPC A (10.10.0.0/16)
# -------------------------------------------------------------
resource "aws_vpc" "vpc_a" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ewb-vpc-a"
  }
}

resource "aws_subnet" "a_public" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "ewb-a-public"
  }
}

resource "aws_subnet" "a_private" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "ewb-a-private"
  }
}

resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "ewb-igw-a"
  }
}

# -------------------------------------------------------------
# 2. NETWORKING: VPC B (10.20.0.0/16)
# -------------------------------------------------------------
resource "aws_vpc" "vpc_b" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ewb-vpc-b"
  }
}

resource "aws_subnet" "b_private" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "ewb-b-private"
  }
}

# -------------------------------------------------------------
# 3. PEERING CONNECTION (ewb-a-b-peer)
# -------------------------------------------------------------
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true
  tags = {
    Name = "ewb-a-b-peer"
  }
}

# -------------------------------------------------------------
# 4. ROUTE TABLES & ASSOCIATIONS
# -------------------------------------------------------------
resource "aws_route_table" "rt_a_public" {
  vpc_id = aws_vpc.vpc_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }

  route {
    cidr_block                = "10.20.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "ewb-rt-a-public"
  }
}

resource "aws_route_table_association" "a_public_assoc" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.rt_a_public.id
}

resource "aws_route_table" "rt_a_private" {
  vpc_id = aws_vpc.vpc_a.id

  route {
    cidr_block                = "10.20.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "ewb-rt-a-private"
  }
}

resource "aws_route_table_association" "a_private_assoc" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.rt_a_private.id
}

resource "aws_route_table" "rt_b_private" {
  vpc_id = aws_vpc.vpc_b.id

  route {
    cidr_block                = "10.10.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "ewb-rt-b-private"
  }
}

resource "aws_route_table_association" "b_private_assoc" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.rt_b_private.id
}

# -------------------------------------------------------------
# 5. SECURITY GROUPS
# -------------------------------------------------------------
variable "my_workstation_ip" {
  type        = string
  default     = "157.41.199.0/32"
  description = "Your public IP address allowed to SSH into the bastion"
}

resource "aws_security_group" "sg_bastion" {
  name        = "ewb-sg-bastion"
  description = "Allow inbound SSH to bastion from admin IP"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from admin workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_workstation_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-bastion"
  }
}

resource "aws_security_group" "sg_app_a" {
  name        = "ewb-sg-app-a"
  description = "Security group for App A"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from Bastion private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP Echo Request from App B"
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.20.1.10/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-a"
  }
}

resource "aws_security_group" "sg_app_b" {
  name        = "ewb-sg-app-b"
  description = "Security group for App B"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    description = "SSH from Bastion private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP Echo Request from App A"
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.2.10/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-b"
  }
}

# -------------------------------------------------------------
# 6. COMPUTE (Amazon Linux 2023 EC2 Instances)
# -------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ewb_lab.key_name
  subnet_id                   = aws_subnet.a_public.id
  private_ip                  = "10.10.1.10"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name = "ewb-bastion"
  }
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ewb_lab.key_name
  subnet_id                   = aws_subnet.a_private.id
  private_ip                  = "10.10.2.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg_app_a.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name = "ewb-app-a"
  }
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ewb_lab.key_name
  subnet_id                   = aws_subnet.b_private.id
  private_ip                  = "10.20.1.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg_app_b.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name = "ewb-app-b"
  }
}

# -------------------------------------------------------------
# 7. OUTPUTS
# -------------------------------------------------------------
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.peer.id
}