provider "aws" {
  region = var.region
}

# -------------------------------
# AMI DATA SOURCES (DYNAMIC)
# -------------------------------

# Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# RedHat
data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*-x86_64-*"]
  }
}

# -------------------------------
# SECURITY GROUP
# -------------------------------

resource "aws_security_group" "ansible_sg" {
  name = "ansible-sg"

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

# -------------------------------
# REDHAT INSTANCES (6)
# -------------------------------

resource "aws_instance" "redhat_db" {
  count         = 3
  ami           = data.aws_ami.redhat.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "redhat-db-${count.index}"
    role = "db"
  }
}

resource "aws_instance" "redhat_web" {
  count         = 3
  ami           = data.aws_ami.redhat.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "redhat-web-${count.index}"
    role = "web"
  }
}

# -------------------------------
# UBUNTU INSTANCES (3)
# -------------------------------

resource "aws_instance" "ubuntu_backend" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "ubuntu-backend-${count.index}"
    role = "backend"
  }
}

# -------------------------------
# AMAZON LINUX (8)
# -------------------------------

locals {
  env_tags = ["dev", "test", "stage", "prod"]
}

resource "aws_instance" "amazon_env" {
  count         = 8
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "amazon-${local.env_tags[count.index % 4]}-${count.index}"
    env  = local.env_tags[count.index % 4]
  }
}