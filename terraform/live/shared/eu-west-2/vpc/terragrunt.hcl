include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.38.0"
}

locals {
  aws_region  = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["environment"]
  custom_tags = yamldecode(file("${find_in_parent_folders("custom_tags.yaml")}"))
  app      = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["application"]
  mandatory_tags = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))
}

inputs = {

  aws = {
    "region" = local.aws_region
  }

  tags = merge(
    {
      "kubernetes.io/cluster/${local.app}-${local.env}-eks" = "shared"
    },
    local.custom_tags
    ,
    local.mandatory_tags
  )

  name = "${local.env}-vpc-eks"

  cidr = "10.0.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  assign_generated_ipv6_cidr_block = true

  enable_nat_gateway = true
  single_nat_gateway  = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = merge(
    {
      "kubernetes.io/cluster/eks-${local.app}-${local.env}" = "shared"
      "kubernetes.io/role/elb"                                 = "1"
    }
  )

    private_subnet_tags = merge(
    {
    "kubernetes.io/cluster/${local.app}-${local.env}-eks" = "shared"
    "kubernetes.io/role/internal-elb"                        = "1"
    }
  )
    tags = merge(
    local.custom_tags
    ,
    local.mandatory_tags
    )
}
