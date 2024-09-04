terraform {
  backend "s3" {
    bucket = var.bucket_name
    key    = "terraform/state/ecr.tfstate"
    region = var.region
  }
}

provider "aws" {
  region = var.region
}
