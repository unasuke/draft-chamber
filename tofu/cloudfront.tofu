# ========== ACM Certificate (us-east-1, CloudFront requires) ==========
resource "aws_acm_certificate" "draft_chamber" {
  region            = "us-east-1"
  domain_name       = "draft-chamber.unasuke.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_validation_records" {
  value = aws_acm_certificate.draft_chamber.domain_validation_options
}

# ========== OAC for S3 ==========
resource "aws_cloudfront_origin_access_control" "draft_chamber_s3" {
  name                              = "draft-chamber-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ========== Managed Cache Policies ==========
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# ========== Managed Origin Request Policies ==========
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

# ========== Variables ==========
variable "cloudfront_origin_verify_secret" {
  type      = string
  sensitive = true
}

# ========== Distribution 1: App (Lightsail) ==========
resource "aws_cloudfront_distribution" "draft_chamber_app" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Draft Chamber - Rails App"
  price_class     = "PriceClass_200"
  aliases         = ["draft-chamber.unasuke.dev"]

  origin {
    domain_name = "draft-chamber-app.unasuke.dev"
    origin_id   = "lightsail-rails"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      ip_address_type        = "ipv6"
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = var.cloudfront_origin_verify_secret
    }
  }

  # Default behavior: dynamic content (no cache)
  default_cache_behavior {
    target_origin_id       = "lightsail-rails"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # Static assets: long-term cache (Propshaft fingerprinted)
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "lightsail-rails"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.draft_chamber.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ========== Distribution 2: CDN (S3 Active Storage) ==========
resource "aws_cloudfront_distribution" "draft_chamber_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Draft Chamber - Active Storage CDN"
  price_class     = "PriceClass_200"

  origin {
    domain_name              = aws_s3_bucket.draft_chamber_production.bucket_regional_domain_name
    origin_id                = "s3-active-storage"
    origin_access_control_id = aws_cloudfront_origin_access_control.draft_chamber_s3.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-active-storage"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ========== Outputs ==========
output "cloudfront_app_domain_name" {
  value = aws_cloudfront_distribution.draft_chamber_app.domain_name
}

output "cloudfront_cdn_domain_name" {
  value = aws_cloudfront_distribution.draft_chamber_cdn.domain_name
}
