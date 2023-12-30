provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Owner     = "nel"
      ManagedBy = "Terraform"
    }
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  ami           = "ami-079db87dc4c10ac91"
  cluster_name  = "prod-servers"
  instance_type = "t2.micro"
  max_size      = 5
  min_size      = 2

  enable_autoscaling = true

  custom_tags = {
    Owner     = "team-foo"
    ManagedBy = "terraform"
  }
}

