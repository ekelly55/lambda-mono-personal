
data "terraform_remote_state" "lambda-ecr" { 
  backend = "s3"
  config = {
    bucket = "${var.environment}-${var.project_name}-lambda-terraform-state"
    key    = "terraform/${var.project_name}-lambda/ecr/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.environment}-${var.project_name}-lambda"
  timeout       = 60 # seconds
  image_uri     = "${data.terraform_remote_state.lambda-ecr.outputs.lambda-ecr-url}:latest" 
  package_type  = "Image"
  role          = "arn:aws:iam::${var.aws_account_id}:role/lambda_role"
}