terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.72.0"
    }
  }
  backend "s3" {
  bucket         = var.bucket_name.name
  key            = "terraform/state.tfstate"
  region         = var.region
  encrypt        = true
  }
}

provider "aws" {
  region      = var.region
  access_key  = var.aws_access_key_id
  secret_key  = var.aws_secret_access_key
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name
}

# resource "aws_s3_bucket_acl" "aws_s3_bucket_acl" {
#   bucket = aws_s3_bucket.app_bucket.id
#   acl   = "private"
# }

resource "aws_security_group" "ec2_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow HTTP and SSH traffic"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["193.33.93.43/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect    = "Allow"
      Sid       = ""
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.app_name}-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_instance" "app_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.ec2_sg.name]
  
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = var.app_name
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

output "instance_ip" {
  value = aws_instance.app_instance.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}