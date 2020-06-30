include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/polarpoint-io/terraform-kubernetes-addons.git?ref=v5.3.1"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.4.2/terraform-provider-kubectl-darwin-amd64 && chmod +x terraform-provider-kubectl"]
  }
}

locals {
  env        = yamldecode(file("${find_in_parent_folders("mandatory_tags.yaml")}"))["environment"]
  aws_region = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
}

dependency "eks" {
  config_path = "../eks"

   # Configure mock outputs for the `validate` and `plan` commands that are returned when there are no outputs available (e.g the
   # module hasn't been applied yet.
  #mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_id              = "cluster-name"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-3.amazonaws.com/id/0000000000000000"
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnets_cidr_blocks = [
      "10.0.0.0/16",
      "192.168.0.0/24"
    ]
  }
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  aws = {
    "region" = local.aws_region
  }

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
  }

  nginx_ingress = {
    version                = "0.30.0"
    chart_version          = "1.35.0"
    enabled                = true
    default_network_policy = true
    ingress_cidr           = "0.0.0.0/0"
    use_nlb                = false
    use_l7                 = false
  }

  istio_operator = {
    enabled = true
  }

  cluster_autoscaler = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    iam_policy_override       = ""
    version                   = "v1.15.6"
    chart_version             = "7.2.0"
    enabled                   = true
    default_network_policy    = true
    cluster_name              = dependency.eks.outputs.cluster_id
    extra_values              = <<EXTRA_VALUES
image:
  repository: eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler
EXTRA_VALUES
  }

  external_dns = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    iam_policy_override       = ""
    version                   = "0.7.1-debian-10-r2"
    chart_version             = "2.20.10"
    enabled                   = true
    default_network_policy    = true
  }

  cert_manager = {
    repository = "https://charts.jetstack.io"
    create_iam_resources_kiam      = false
    create_iam_resources_irsa      = true
    iam_policy_override            = ""
    version                        = "v0.15.0"
    chart_version                  = "v0.15.0"
    enabled                        = true
    default_network_policy         = true
    acme_email                     = "surj@polarpoint.io"
    enable_default_cluster_issuers = true
    installCRDs                    = true
    allowed_cidrs                  = dependency.vpc.outputs.private_subnets_cidr_blocks
    extra_values              = <<EXTRA_VALUES
installCRDs: true
EXTRA_VALUES
  }

  kiam = {
    create_iam_user             = true
    create_iam_resources        = true
    assume_role_policy_override = ""
    version                     = "v3.5"
    chart_version               = "5.7.0"
    enabled                     = false
    default_network_policy      = false
    iam_user                    = ""
  }

  metrics_server = {
    version                = "v0.3.6"
    chart_version          = "2.10.2"
    enabled                = true
    default_network_policy = true
    allowed_cidrs          = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  flux = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    version                   = "1.19.0"
    chart_version             = "1.3.0"
    enabled                   = false
    default_network_policy    = true

    extra_values = <<EXTRA_VALUES
git:
  url: "ssh://git@github.com/polarpoint-io/flux-cd-${local.env}.git"
  pollInterval: "2m"
rbac:
  create: false
registry:
  automationInterval: "2m"
EXTRA_VALUES
  }

  prometheus_operator = {
    repository = "https://kubernetes-charts.storage.googleapis.com"
    chart_version          = "8.12.9"
    enabled                = false
    default_network_policy = true
    enable_prometheus_thanos_storage = false
    allowed_cidrs          = dependency.vpc.outputs.private_subnets_cidr_blocks
    extra_values = <<EXTRA_VALUES
prometheus:
  prometheusSpec:
    replicas: 2      # work in High-Availability mode
    retention: 72h   # we only need a few hours of retention, since the rest is uploaded to blob
    image:
      tag: v2.17.1    # use a specific version of Prometheus
    serviceMonitorNamespaceSelector : {}  # allows the operator to find target config from multiple namespaces
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi      
    thanos:         # add Thanos Sidecar
      tag: v0.8.0   # a specific version of Thanos
      objectStorageConfig: # blob storage configuration to upload metrics 
        key: thanos.yaml
        name: thanos-storage-config
grafana:
  deploymentStrategy:
    type: Recreate
  ingress:
    enabled: false
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: "letsencrypt"
    hosts:
      - dashboard.polarpoint.eu
    tls:
      - secretName: dashboard-polarpoint-eu
        hosts:
          - dashboard.polarpoint.eu
  persistence:
    enabled: true
    storageClassName: gp2
    accessModes:
      - ReadWriteOnce
    size: 10Gi               
EXTRA_VALUES
  }

  fluentd_cloudwatch = {
    create_iam_resources_kiam        = false
    create_iam_resources_irsa        = true
    default_network_policy           = true
    iam_policy_override              = ""
    chart_version                    = "0.12.1"
    version                          = "v1.7.4-debian-cloudwatch-1.0"
    enabled                          = false
    containers_log_retention_in_days = 180
  }

  jenkins_operator = {
    chart_version          = "1.7.1"
    version                = "v0.8.1"
    enabled                = true
    default_network_policy = true
  }

  spinnaker = {
    chart_version          = "1.7.1"
    version                = "v0.8.1"
    enabled                = true
    default_network_policy = true
  }

  argocd = {
    chart_version          = "1.7.1"
    version                = "v0.8.1"
    enabled                = true
    default_network_policy = true
  }
 

  npd = {
    chart_version          = "1.7.1"
    version                = "v0.8.1"
    enabled                = true
    default_network_policy = true
  }

  sealed_secrets = {
    chart_version          = "1.8.0"
    version                = "v0.10.0"
    enabled                = false
    default_network_policy = true
  }

  cni_metrics_helper = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    enabled                   = true
    version                   = "v1.6.1"
    iam_policy_override       = ""
  }

  kong = {
    version                = "2.0"
    chart_version          = "1.4.1"
    enabled                = false
    default_network_policy = true
    ingress_cidr           = "0.0.0.0/0"
  }

  keycloak = {
    chart_version          = "7.5.0"
    version                = "9.0.2"
    enabled                = false
    default_network_policy = true
  }

  karma = {
    chart_version          = "1.5.1"
    version                = "v0.60"
    enabled                = false
    default_network_policy = true
    extra_values           = <<EXTRA_VALUES
ingress:
  enabled: true
  path: /
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt"
  hosts:
    - alerting.polarpoint.eu
  tls:
    - secretName: alerting-polarpoint-eu
      hosts:
        - alerting.polarpoint.eu    
env:
  - name: ALERTMANAGER_URI
    value: "http://prometheus-operator-alertmanager.monitoring.svc.cluster.local:9093"
  - name: ALERTMANAGER_PROXY
    value: "true"
  - name: FILTERS_DEFAULT
    value: "@state=active severity!=info severity!=none"
EXTRA_VALUES
  }
}