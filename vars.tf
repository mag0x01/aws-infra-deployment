variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "app_name" {
  description = "My Python app"
  type        = string
}

variable "aws_access_key_id" {
  description = "The AWS access key."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "The AWS secret key."
  type        = string
  sensitive   = true
}