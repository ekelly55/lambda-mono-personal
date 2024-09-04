
# Set up the S3 submodule
module "s3" {
  source = "./s3"
  environment = var.environment
  project_name = var.project_name
  region = var.region
}

# Set up the ECR submodule
module "ecr" {
  source = "./ecr"
  environment = var.environment
  project_name = var.project_name
  region = var.region
}

# Set up the Lambda submodule
module "lambda" {
  source = "./lambda"
  environment = var.environment
  project_name = var.project_name
  region = var.region
}