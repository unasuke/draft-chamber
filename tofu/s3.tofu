resource "aws_s3_bucket" "draft_chamber_production" {
  region = "ap-northeast-1"
  bucket = "draft-chamber-production-3a2bf32c"
}

resource "aws_s3_bucket_public_access_block" "draft_chamber_production" {
  bucket                  = aws_s3_bucket.draft_chamber_production.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
