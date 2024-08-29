# Lambda Infrastructure How-To

## Naming Conventions

base-name (without "lambda"):

```sh
<your-project-name>
```

## Terraform

If necessary, install Terraform. See instructions [here](https://developer.hashicorp.com/terraform/install)

Create a terraform directory at the root of your project. In it, create three subdirectories: 
```sh
s3
ecr
lambda
```

## s3 Set Up

Create three files in terraform/s3:
```sh
s3.tf
provider.tf
variables.tf
```
### s3/variables.tf

```sh
variable "environment" {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
  default     = "<environment-name>"
}

variable "aws_account_id" {
  description = "account id for provisioned aws account"
  type        = string
  default     = "<account-id>"
}
```

### s3/provider.tf

```sh
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45.0"
    }
  }
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-2"
}
```

### s3/s3.tf

Creates s3 bucket to store Terraform state files. 
*Note that ``` ${var.environemt} ``` is  not allowed in s3 blocks.

```sh
  resource "aws_s3_bucket" "<base-name>-lambda-terraform-state" {
    bucket = "<environment>-<base-name>-lambda-terraform-state"
  
}

resource "aws_s3_bucket_versioning" "<environment>-<base-name>-lambda-terraform-state-versioning" {
    bucket = "<same-as-above>"
    versioning_configuration {
        status = "Enabled"
    }
}

  ```

## ECR Set Up

Create four files in terraform/ecr:
```sh
ecr.tf
provider.tf
variables.tf
output.tf
```
### ecr/variables.tf

```sh
variable "environment" {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
  default     = "<environment-name>"
}

```

### ecr/provider.tf

```sh
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45.0"
    }
  }
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "<environment>-<base-name>-lambda-terraform-state"
    key    = "terraform/<base-name>-lamdba/ecr/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}
```

### ecr/ecr.tf

Creates ECR repository to store lambda function as a Docker image.

```sh
resource "aws_ecr_repository" "<base-name>-lamdba-ecr" {
  name = "${var.environment}-<base-name>-lamdba"
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

### ecr/output.tf

Provides the ECR repository name and url after it's created.

```sh
output "<base-name>-lamdba-ecr-name"{
    value = aws_ecr_repository.<base-name>-lamdba-ecr.name
}

output "<base-name>-lamdba-ecr-url"{
    value = aws_ecr_repository.<base-name>-lamdba-ecr.repository_url
}
```

## Lambda Set Up

Create three files in terraform/lambda:

```sh
lambda.tf
provider.tf
variables.tf
```

### lambda/variables.tf

```sh
variable "environment" {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
  default     = "<environment-name>"
}

variable "aws_account_id" {
  description = "account id for provisioned aws account"
  type        = string
  default     = "<account-id>"
}

```

### lambda/provider.tf

```sh
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45.0"
    }
  }
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "<environment>-<base-name>-lambda-terraform-state"
    key    = "terraform/<base-name>-lamdba/lambda/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}
```

### lambda/lambda.tf

1. Data block: this allows your lambda function to access the ECR outputs from the ECR Terraform build. 
*Note that ``` ${var.environemt} ``` is  not allowed in s3 blocks.
```sh
data "terraform_remote_state" "<base-name>-lamdba-ecr" { 
  backend = "s3"
  config = {
    bucket = "<environment>-<base-name>-lambda-terraform-state"
    key    = "terraform/<base-name>-lamdba/ecr/terraform.tfstate"
    region = "us-east-2"
  }
}
```

2. Lambda resource block: creates your lambda function

```sh
resource "aws_lambda_function" "<base-name>-lamdba" {
  function_name = "${var.environment}-<base-name>-lamdba"
  timeout       = 60 # seconds
  image_uri     = "${data.terraform_remote_state.<base-name>-lamdba-ecr.outputs.<base-name>-lamdba-ecr-url}:latest" 
  package_type  = "Image"
  role          = "arn:aws:iam::${var.aws_account_id}:role/lambda_role"
}

```

#### If your lambda will be triggered by an API call (if not, skip to step 8):

3. API Gateway resource blocks: create REST API, API resource and method

```sh
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.environment}-<base-name>-api"
  description = "<your-description> api for ${var.environment} environment"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "<resource-name-i.e.-v1>"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id      = aws_api_gateway_rest_api.api_gateway.id
  resource_id      = aws_api_gateway_resource.api_resource.id
  http_method      = "<method-required-for-your-use-case>"
  authorization    = "NONE"
  api_key_required = true
}
```

4. Lambda integration resource block: allows your API to pass a request directly to the lambda
   * The integration http method must be "POST" regardless of the API method declared above.
```sh
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.<base-name>-lamdba.invoke_arn
}
```

5. API deployment resource block: creates a stage and deploys API to that stage

```sh
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = var.environment
}
```

6. Permission block: gives API permission to invoke lambda

```sh
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.<base-name>-lamdba.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}
```
7. API key and usage plan blocks: create api key and usage plan and associate API key and API stage with the usage plan:

```sh
resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.environment}-<base-name>-api-key"
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  name = "${var.environment}-<base-name>-api-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = aws_api_gateway_deployment.api_deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "api_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan.id
}
```
#### If your lambda is triggered regularly by CloudWatch:

8. CloudWatch blocks: creates rule for timing trigger, applies rule to lambda, grants CloudWatch permission to invoke lambda:

 ```sh
resource "aws_cloudwatch_event_rule" "every-<number>-minutes" {
    name = "every-<number>-minutes"
    description = "Fires every <number> minutes"
    schedule_expression = "rate(<int> minutes)"
}

resource "aws_cloudwatch_event_target" "run-moku-lucky-draw-lamdba-every-ten-minutes" {
    rule = "${aws_cloudwatch_event_rule.every-ten-minutes.name}"
    target_id = "<base-name>-lambda"
    arn = "${aws_lambda_function.<base-name>-lamdba.arn}"
}

resource "aws_lambda_permission" "allow-cloudwatch-to-call-<base-name>-lamdba" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.<base-name>-lamdba.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every-ten-minutes.arn}"
}

```

## Run Terraform
### s3
In s3 directory, run the following series of commands: 

```sh
terraform init
terraform plan
terraform apply
```

Log in to AWS console and check that your s3 bucket has been created.

### ECR Build
In ecr directory, run the following series of commands: 

```sh
terraform init
terraform plan
terraform apply
```

Check the AWS console to confirm that your ECR repository has been created.

### Initial Image Push
In the ECR console, click "View Push Commands". Run each in your root directory (or wherever your Dockerfile is located). This will provide the initial Docker image of your lambda to apply to the Terraform lambda build.
*If working from an M1 Mac, you may need to use command ```docker buildx build --platform linux/amd64 -t <tag-from-push-command>``` for the image to be compatible with lambda.

### Lambda Build

In the lambda directory, run the following series of commands: 

```sh
terraform init
terraform plan
terraform apply
```

Check the AWS console to confirm that your lambda has been created as well as your API gateway if applicable. 

## Workflows

Production and staging workflows are included and only require plugging in image URIs after the initial image build and push. 
