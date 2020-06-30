remote_state {
  backend = "s3"
  config = {
    bucket         = "${yamldecode(file("mandatory_tags.yaml"))["application"]}-tf-state-store-${yamldecode(file("mandatory_tags.yaml"))["environment"]}-${yamldecode(file("common_values.yaml"))["aws_region"]}"
    key            = "${path_relative_to_include()}"
    region         = "${yamldecode(file("mandatory_tags.yaml"))["aws_region"]}"
    encrypt        = true
    dynamodb_table = "${yamldecode(file("mandatory_tags.yaml"))["application"]}-tf-state-store-lock-${yamldecode(file("mandatory_tags.yaml"))["environment"]}-${yamldecode(file("common_values.yaml"))["aws_region"]}"
  }
}

iam_role = "arn:aws:iam::${yamldecode(file("common_values.yaml"))["aws_account_id"]}:role/admin"
