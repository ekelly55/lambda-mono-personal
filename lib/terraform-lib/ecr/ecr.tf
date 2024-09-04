resource "aws_ecr_repository" "lambda-ecr" {
  name = "${var.environment}-${var.project_name}-lambda-ecr"
  image_scanning_configuration {
    scan_on_push = true
  }
}