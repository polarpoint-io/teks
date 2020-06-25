# terragrunt-aws-all-infra

![terragrunt:env:shared](https://github.com/polarpoint-io/terragrunt-aws-all-infra/workflows/terragrunt:env:shared/badge.svg)

A set of Terraform / Terragrunt modules designed to get you everything you need to run a Full Software Delivery service on AWS with sensible defaults and addons with their configurations that work out of the box.

![Alt text](https://github.com/polarpoint-io/terragrunt-aws-all-infra/blob/master/docs/images/architecture.png)


## Main purposes

The main goal of this project is to glue together commonly used tooling with Kubernetes/EKS and to get from an AWS Account to a production cluster with everything you need without any manual configuration.

## What you get

A production cluster all defined in IaaC with Terraform/Terragrunt:

* AWS VPC if needed based on [`terraform-aws-vpc`](https://github.com/terraform-aws-modules/terraform-aws-vpc)
* EKS cluster base on [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks)
* Kubernetes addons based on [`terraform-kubernetes-addons`](https://github.com/polarpoint-io/terraform-kubernetes-addons): provides various addons that are often used on Kubernetes and specifically on EKS.
* Kubernetes namespaces quota management based on [`terraform-kubernetes-namespaces`](https://github.com/polarpoint-io/terraform-kubernetes-addons): allows administrator to manage namespaces and quotas from a centralized configuration with Terraform.

Everything is tied together with Terragrunt and allows you to deploy a multi cluster architecture in a matter of minutes (ok maybe an hour) and different AWS accounts for different environments.

## Curated Features

The main additionals features are the curated addons list, see [here](https://github.com/clusterfrak-dynamics/terraform-kubernetes-addons) and in the customization of the cluster policy

### Enforced security

* Default PSP is removed and sensible defaults are enforced
* All addons have specific PSP enabled
* No IAM credentials on instances, everything is enforced with [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) or [KIAM](https://github.com/uswitch/kiam)
* Each addons is deployed in it's own namespace with sensible default network policies

### Out of the box monitoring

* Prometheus Operator with defaults dashboards
* Addons that support metrics are enable along with their `serviceMonitor`
* Custom grafana dashboard are available by default.

### Helm v3 provider

* All addons support Helm v3 configuration
* All charts are easily customizable

### Other and not limited to

* priorityClasses for addons
* use of [`kubectl-provider`], no more local exec and custom manifest are properly handled
* lot of manual stuff have been automated under the hood

## Requirements

Terragrunt is not a hard requirement but all the modules are tested with Terragrunt.

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

[`terraform/live`](terraform/live) folder provides a best practice layout.



