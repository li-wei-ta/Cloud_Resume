provider "aws" {
  region = var.canada_region
}

# ---------  S3 bucket ---------
resource "aws_s3_bucket" "cr_bucket" {
  bucket = var.cr_bucket_name
}

resource "aws_s3_object" "my_objects" {
  for_each     = var.objects
  bucket       = aws_s3_bucket.cr_bucket.id
  key          = each.key
  source       = each.value.path
  etag         = filemd5(each.value.path)
  content_type = each.value.content_type
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.cr_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "OnlyAllowCloudFrontAccess",
      Effect = "Allow",
      Principal = {
        Service = "cloudfront.amazonaws.com"
      },
      Action   = "s3:GetObject",
      Resource = "${aws_s3_bucket.cr_bucket.arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" : "${aws_cloudfront_distribution.cr_s3_distribution.arn}"
        }
      }
    }]
  })
  depends_on = [
    aws_cloudfront_distribution.cr_s3_distribution,
    aws_cloudfront_origin_access_control.cloud_resume_OAC
  ]
}

# --------- CloudFront Distribution ---------

resource "aws_cloudfront_origin_access_control" "cloud_resume_OAC" {
  name = "cr-cloudfront-origin-access-control"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cr_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.cr_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloud_resume_OAC.id
    origin_id                = "S3-${aws_s3_bucket.cr_bucket.id}"
  }

  aliases = var.cloudfront_aliases

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Resume Cloud Challenge CloudFront"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.cr_bucket_name}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_s3_bucket.cr_bucket]
}

# --------- Route 53 ---------

data "aws_route53_zone" "my_hosted_zone" {
  name         = var.my_domain_name
  private_zone = false
}

resource "aws_route53_record" "a_record" {
  zone_id = data.aws_route53_zone.my_hosted_zone.zone_id
  name    = var.my_domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cr_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cr_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


