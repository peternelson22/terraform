terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

locals {
  project_name = "Server"
}

data "aws_vpc" "main" {
  id = "vpc-0d88ed54916205ae7"
}

resource "aws_security_group" "sg-server" {
  name        = "sgserver"
  description = "My security group"
  vpc_id      = data.aws_vpc.main.id

  ingress = [
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC26DDumnXVQ2WkAFOAsdj6Tilve2E7SgcRxc+u5DBhzVuql4gqHR/ncL8+bxLSLqxfb26fw6K/pt9kBid4u+zabzWZyWZO5WPAkChlqnsnAnOQ909RZBuPp9LFDH/SVp98uMLdoap5OtaVNyy//fjPCDEsWFYDNUg7VRgKZYw5Y0nEsrE2Q2XuGVZ7sFeI6Q1jsOpIVlAemmxsROiRNqdNf+NeOUOBdeJpR/mkw7c9tVLYY4cczmePhCTQbZjl67Xdksl/XCmEKyxM+C+HWI7NncO5+tX6Mj+nRzORw8IILCaYGAMGtGoVz/dI/CekBmJuG+VQBOSDHwr/A4Vz7/MIzuMszJZi4C44RaIN4Q2a6+wFCR3nufYbSKRz9vyhcUFpLE9hA2vLrHU98wNcxs3V0Y78E5FJ80LhkMUjMQXU5B9Grb4ypPstvoPO2kyg3/KVBPT8sGCIs2rcl0zyB+9cV6TtbMGjmobbZ3o1+P7qMlSJFiomekv5qkiawUPDbMc= nelson@nelson"

}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

resource "aws_instance" "example" {
  ami                    = "ami-079db87dc4c10ac91"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg-server.id]
  user_data              = data.template_file.user_data.rendered

 provisioner "file" {
    content     = "Earth"
    destination = "/home/ec2-user/foo.txt"
  }
  # provisioner "local-exec" {
  #   command = "echo ${self.private_ip} >> private_ips.txt"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt"
  #   ]
  # }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/tf")
    host        = self.public_ip
  }
  tags = {
    Name = "Example-${local.project_name}"
  }
}

