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

module "template_files" {
  source  = "hashicorp/dir/template"
  base_dir = "${path.module}/web"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example
  ]
  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
  
}

resource "aws_s3_bucket_policy" "awspolicy" {
  depends_on = [ aws_s3_bucket.bucket,aws_s3_bucket_acl.s3_bucket_acl ]
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" :"2012-10-17",
    "Statement": [
        {
            "Sid" : "PublicRead",
            "Effect" : "Allow",
            "Principal" : "*",
            "Action" : "s3:*"
            "Resource" : ["arn:aws:s3:::${var.bucket_name}/*"]
        }
    ]
})
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_object" "aws_s3_object" {
  for_each = module.template_files.files
  bucket = aws_s3_bucket.bucket.id
  key = each.key
  content_type = each.value.content_type
  source  = each.value.source_path
  content = each.value.content
  etag = each.value.digests.md5
}
