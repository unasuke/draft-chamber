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

resource "aws_s3_bucket_policy" "draft_chamber_cloudfront" {
  bucket = aws_s3_bucket.draft_chamber_production.id
  policy = data.aws_iam_policy_document.draft_chamber_cloudfront.json
}

data "aws_iam_policy_document" "draft_chamber_cloudfront" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.draft_chamber_production.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.draft_chamber_cdn.arn]
    }
  }
}
