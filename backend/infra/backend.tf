terraform {
  backend "s3" {
    bucket  = "my-terraform-state-file-bucket-8"
    key     = "backend.tfstate"
    region  = "ca-central-1"
    encrypt = true
  }
}
