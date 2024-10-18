variable "canada_region" {
  description = "storing value of ca-central region"
}


variable "my_dynamoDB_table_name" {
  description = "table to store my counter"
}

variable "partition_key" {
  description = "partition key for dynamoDB table"
}


variable "my_lambda_counter_name" {
  description = "increments the counter stored in dynamoDB"

}

variable "lambda_basic_iam_policy" {
  description = "basic execution role policy of lambda"

}

variable "lambda_zip_file_path" {
  description = "path to lambda source code"
}


variable "my_dynamo_table_arn" {
  description = "resource name for my dynamoDB table"
}



variable "my_resume_api_name" {
  description = "RESTapi throiugh API gateway for my lambda function"

}
