provider "aws" {
  region = var.canada_region
}

# -------------- DynamoDB Table --------------
resource "aws_dynamodb_table" "resume_table" {
  name         = var.my_dynamoDB_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.partition_key

  attribute {
    name = var.partition_key
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "count_item" {
  table_name = aws_dynamodb_table.resume_table.name
  hash_key   = var.partition_key

  item = <<ITEM
{
  "id": {"S": "visit-counter"},
  "count": {"N": "0"}
}
ITEM
}

# -------------- Lambda Function --------------
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "lambda-policy-attach"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = var.lambda_basic_iam_policy
}

resource "aws_lambda_function" "my_lambda" {
  function_name = var.my_lambda_counter_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "counter.lambda_handler"
  runtime       = "python3.12"
  filename      = var.lambda_zip_file_path
  timeout       = 3
  memory_size   = 128
}

resource "aws_iam_policy" "lambda_access_dynamo_policy" {
  name        = "lambda_dynamodb_access_policy"
  description = "allow lambda to access dynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem"
        ],
        Resource = var.my_dynamo_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_access_dynamo_policy.arn
}

# -------------- API Gateway --------------
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.my_resume_api_name
}

resource "aws_api_gateway_resource" "visitors_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "visitors"
}

# GET Method for /visitors resource
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.visitors_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# CORS Method Response for GET
resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.visitors_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# API Gateway Lambda Integration for GET
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.visitors_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

# Integration Response for CORS (GET)
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.visitors_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# OPTIONS Method for CORS Preflight
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.visitors_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# MOCK Integration for OPTIONS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.visitors_resource.id
  http_method             = aws_api_gateway_method.options_method.http_method
  integration_http_method = "OPTIONS"
  type                    = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Method Response for OPTIONS CORS
resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.visitors_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integration Response for OPTIONS CORS
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.visitors_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.options_integration
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_method.get_method,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.method_response,
    aws_api_gateway_integration_response.integration_response,
    aws_api_gateway_method.options_method,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_method_response.options_method_response,
    aws_api_gateway_integration_response.options_integration_response
  ]
}

# Lambda Permissions for API Gateway Invocation
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}
