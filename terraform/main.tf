provider "aws" {
  region = var.region
}

# -------------------------
# Get latest Ubuntu AMI
# -------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# -------------------------
# Get latest RedHat AMI
# -------------------------
data "aws_ami" "redhat" {
  most_recent = true

  owners = ["309956199498"] # RedHat

  filter {
    name   = "name"
    values = ["RHEL-9.*-x86_64-*"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------------------------
# Security Group
# -------------------------
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

# -------------------------
# Ubuntu Instances (db)
# -------------------------
resource "aws_instance" "ubuntu" {
  count         = 6
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "db-${count.index + 1}"
  }
}

# -------------------------
# RedHat Instances (mtn)
# -------------------------
resource "aws_instance" "redhat" {
  count         = 6
  ami           = data.aws_ami.redhat.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "mtn-${count.index + 1}"
  }
}

resource "aws_instance" "amazon_linux" {
  count         = 6
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "dev-web-${count.index + 1}"
  }
}



# -------------------------
# Generate Ansible Inventory
# -------------------------
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    ubuntu_ips      = aws_instance.ubuntu[*].public_ip
    redhat_ips      = aws_instance.redhat[*].public_ip
    amazon_linux_ips = aws_instance.amazon_linux[*].public_ip
  })
}