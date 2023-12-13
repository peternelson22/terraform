variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t2.micro"
}
variable "number_of_instances" {
  description = "Number of instance"
  type = number
  default = 1
}
variable "enable_public_ip" {
  description = "Enable public IP"
  type = bool
  default = true
}
variable "create_iam_users" {
  description = "Create many IAM users"
  type = list(string)
  default = ["user1", "user2", "user3"]
}

variable "instance_type_tfvars" {
  description = "Using tfvars to identify instance type"
  type = string
}

variable "tag" {
  description = "Name of EC2"
  type = string
}