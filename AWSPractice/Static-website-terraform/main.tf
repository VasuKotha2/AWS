terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

