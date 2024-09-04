terraform {
  backend "s3" {
    bucket = var.environment-var.project_name-lambda-terraform-state
    key    = "terraform/${var.project_name}-lambda/ecr/terraform.tfstate"
    region = var.region
  }
}

provider "aws" {
  region = var.region
}
