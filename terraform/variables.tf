variable "aws_region" {
  default = "us-east-1"
}

variable "ami" {}

variable "instance_type" {
  default = "t3.small"
}

variable "public_key" {
  description = "SSH Public Key"
}
