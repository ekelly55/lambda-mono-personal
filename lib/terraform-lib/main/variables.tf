variable "environment" {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
}

variable "aws_account_id" {
  description = "account id for provisioned aws account"
  type        = string
}

variable "project_name" {
    description = "the name of the project"
    type = string
}

variable "trigger_timing" {
    description = "how often cloudwatch should trigger the lambda"
    type = number
    default = 10
}

variable "region" {
    description = "aws region for project"
    type = string
    default = "us-east-2"
}