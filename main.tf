provider "aws" {
  region      = var.region
  access_key  = var.aws_access_key_id
  secret_key  = var.aws_secret_access_key
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

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
    cidr_blocks = ["185.198.44.208/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#IAM Role for EC2 to access S3
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
    user_data = <<-EOF
              #!/bin/bash
              # Install necessary packages
              sudo yum update -y
              sudo yum install -y git
              mkdir actions-runner && cd actions-runner
              curl -o actions-runner-linux-x64-2.320.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz
              tar xzf ./actions-runner-linux-x64-2.320.0.tar.gz
              ./config.sh --url https://github.com/mag0x01/aws-app-deploy --token AOAQHUMVMHYPW43XM6YE7HTHCJ6CW
              sudo ./svc.sh install
              sudo ./svc.sh start
              EOF
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