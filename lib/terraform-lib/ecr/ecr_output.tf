output "lambda-ecr-name"{
    value = aws_ecr_repository.lambda-ecr.name
}

output "lambda-ecr-url"{
    value = aws_ecr_repository.lambda-ecr.repository_url
}