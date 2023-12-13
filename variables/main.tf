provider "aws" {
  region     = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_instance" "ec2_example" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = var.instance_type_tfvars
  count                       = var.number_of_instances
  associate_public_ip_address = var.enable_public_ip

  tags = {
    Name = var.tag
  }
}