resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.environment}-${var.project_name}-lambda-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform-state-versioning" {
  bucket = "${var.environment}-${var.project_name}-lambda-terraform-state"
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_name" {
  value = "${var.environment}-${var.project_name}-lambda-terraform-state"
}
