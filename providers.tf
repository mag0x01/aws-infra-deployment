  terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.72.0"
    }
  }
  backend "s3" {
  bucket         = "github-hw-terraform-aws-tfstate"
  key            = "terraform/state.tfstate"
  region         = "ap-southeast-1"
  encrypt        = true
  }
}