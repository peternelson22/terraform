provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "stage-servers"
  instance_type = "t2.micro"
  max_size = 2
  min_size = 2

  enable_autoscaling = false
}