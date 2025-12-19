terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
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
