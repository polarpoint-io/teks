include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v12.0.0"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.4.2/terraform-provider-kubectl-darwin-amd64 && chmod +x terraform-provider-kubectl"]
  }

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig label ns kube-system name=kube-system --overwrite"]
  }

  after_hook "remove-default-psp" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig delete psp eks.privileged || true"]
  }
  after_hook "remove-default-psp-clusterrolebindind" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig delete clusterrolebinding eks:podsecuritypolicy:authenticated || true"]
  }
  after_hook "remove-default-psp-clusterrole" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig delete clusterrole eks:podsecuritypolicy:privileged || true"]
  }
}

locals {
  aws_region     = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env            = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["environment"]
  app            = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["app"]
  aws_account_id = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_account_id"]
  custom_tags    = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))
  cluster_name   = "${local.app}-${local.env}-eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

inputs = {

  aws = {
    "region" = local.aws_region
  }

  psp_privileged_ns = [
    "istio-system"
  ]

  tags = merge(
    local.custom_tags
  )

  cluster_name     = local.cluster_name
  subnets          = dependency.vpc.outputs.private_subnets
  vpc_id           = dependency.vpc.outputs.vpc_id
  write_kubeconfig = false
  enable_irsa      = true

  kubeconfig_aws_authenticator_additional_args = [ "-r",                                                                            
    "arn:aws:iam::${local.aws_account_id}:role/admin","--region", "${local.aws_region}"]




  cluster_version           = "1.16"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  manage_worker_autoscaling_policy = false

  worker_groups_launch_template = [
    {
      name                 = "default-${local.aws_region}a"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[0]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
      ]
    },
    {
      name                 = "default-${local.aws_region}b"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[1]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
      ]
    },
    {
      name                 = "default-${local.aws_region}c"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[2]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
      ]
    },
  ]
}
