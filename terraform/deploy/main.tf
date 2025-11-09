provider "aws" {
  region     = "us-west-2"
  access_key = "poo"
  secret_key = "pee"
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "terraform_gateway"
}

resource "aws_api_gateway_resource" "resource_id" {
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "id"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_resource" "id_param" {
  parent_id   = aws_api_gateway_resource.resource_id.id
  path_part   = "{id}"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}


resource "aws_api_gateway_method" "get_id" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.id_param.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.id_param.id
  http_method             = aws_api_gateway_method.get_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_api_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.js"
  output_path = "${path.module}/../lambda/function.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "terraform_lambda_function"
  role             = aws_iam_role.lambda_api_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      ENVIRONMENT = "dev"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "dev"
    Application = "example"
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"
}


resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource_id.id,
      aws_api_gateway_method.get_id.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}