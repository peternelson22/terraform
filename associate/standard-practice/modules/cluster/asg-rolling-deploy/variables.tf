variable "ami" {
  description = "Server Image"
  type        = string
  default     = "ami-079db87dc4c10ac91"
}
variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}
variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g.t2.micro)"
  type        = string
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type        = bool
}

variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}

variable "port" {
  description = "Port 8080"
  type        = string
  default     = "8080"
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
}
variable "target_group_arns" {
  description = "The ARNs of ELB target groups in which toregister Instances"
  type        = list(string)
  default     = []
}
variable "health_check_type" {
  description = "The type of health check to perform. Must be oneof: EC2, ELB."
  type        = string
  default     = "EC2"
}
variable "user_data" {
  description = "The User Data script to run in each Instance atboot"
  type        = string
  default     = null
}