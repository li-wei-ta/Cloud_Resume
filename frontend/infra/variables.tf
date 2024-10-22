variable "canada_region" {
  description = "storing value of ca-central region"
}

variable "cr_bucket_name" {
  description = "bucket to store the frontend website code"
}

variable "my_domain_name" {
  description = "Domain name registered for my cloud resume"
}
variable "cloudfront_aliases" {
  description = "the cnames that your acm certificate is attached to"
}

variable "acm_arn" {
  description = "The arn resource from US-east-1 (virginia)"
}

variable "objects" {
  type = map(object({
    path         = string
    content_type = string
  }))
  default = {
    "index.html" = {
      path         = "../src/index.html"
      content_type = "text/html"
    }
    "assets/img/avatar.jpg" = {
      path         = "../src/assets/img/avatar.jpg"
      content_type = "image/jpeg"
    }
    "assets/img/aws_cloud_practitioner_badge.png" = {
      path         = "../src/assets/img/aws_cloud_practitioner_badge.png"
      content_type = "image/png"
    }
    "assets/img/aws_solution_architect_badge.png" = {
      path         = "../src/assets/img/aws_solution_architect_badge.png"
      content_type = "image/png"
    }
    "assets/js/script.js" = {
      path         = "../src/assets/js/script.js"
      content_type = "application/javascript"
    }
    "assets/css/style.css" = {
      path         = "../src/assets/css/style.css"
      content_type = "text/css"
    }
  }
}
