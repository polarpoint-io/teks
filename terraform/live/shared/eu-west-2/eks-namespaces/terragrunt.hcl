include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-kubernetes-namespaces.git?ref=v4.0.1"
}

locals {
  aws_region     = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env            = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["environment"]
  app            = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["application"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_id = "cluster-name"
  }
}

inputs = {

  aws = {
    "region" = local.aws_region
  }

  eks = {
    "cluster_id" = dependency.eks.outputs.cluster_id
  }

  //
  // [env]
  //
  env = local.env

  //
  // [namespaces]
  //
  namespaces = [
    {
      "name"                       = "${local.app}-${local.env}"
      "kiam_allowed_regexp"        = "^$"
      "requests.cpu"               = "50"
      "requests.memory"            = "10Gi"
      "pods"                       = "100"
      "count/cronjobs.batch"       = "100"
      "count/ingresses.extensions" = "5"
      "requests.nvidia.com/gpu"    = "0"
      "services.loadbalancers"     = "0"
      "services.nodeports"         = "0"
      "services"                   = "20"
    }
  ]
}
