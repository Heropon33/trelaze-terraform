terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "public_key_file" {
  description = "Chemin vers la clé publique"
  default     = "ansible.pub"
}


data "aws_vpc" "default" {
  default = true
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "keypair1" {
  key_name   = "keypair1"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "keypair1"
  }
}

resource "aws_instance" "otl" {
  ami = "resolve:ssm:/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"

  instance_type = "t3.micro"

  key_name = aws_key_pair.keypair1.key_name

  vpc_security_group_ids = [
    aws_security_group.sg1.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /root/.ssh
              echo "${file(var.public_key_file)}" >> /root/.ssh/authorized_keys
              chmod 600 /root/.ssh/authorized_keys
              chmod 700 /root/.ssh
              EOF

  tags = {
    Name = "otl"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

}

resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Security group pour nos webservers"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "sg1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.sg1.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"

  description = "Autoriser SSH depuis le monde entier"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.sg1.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Autoriser tout le trafic sortant"
}

output "otl_public_ip" {
  value       = aws_instance.otl.public_ip
  description = "IP publique de l'instance otl"
}
