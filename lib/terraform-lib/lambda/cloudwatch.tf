resource "aws_cloudwatch_event_rule" "every-x-minutes" {
    name = "every-${var.trigger_timing}-minutes"
    description = "Fires every ${var.trigger_timing} minutes"
    schedule_expression = "rate(${var.trigger_timing} minutes)"
}

resource "aws_cloudwatch_event_target" "run-lambda-every-x-minutes" {
    rule = "${aws_cloudwatch_event_rule.every-x-minutes.name}"
    target_id = "${var.project_name}-lambda"
    arn = "${aws_lambda_function.lambda.arn}"
}

resource "aws_lambda_permission" "allow-cloudwatch-to-call-lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every-x-minutes.arn}"
}
