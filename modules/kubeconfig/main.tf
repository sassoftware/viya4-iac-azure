locals {
  service_account_name        = "${var.prefix}-cluster-admin-sa"
  cluster_role_binding_name   = "${var.prefix}-cluster-admin-crb"
  service_account_secret_name = "${var.prefix}-sa-secret"
}

# Provider based kube config data/template/resources
data "template_file" "kubeconfig_provider" {
  count = var.create_static_kubeconfig ? 0 : 1
  template = file("${path.module}/templates/kubeconfig-provider.tmpl")

  vars = {
    cluster_name = var.cluster_name
    endpoint     = var.endpoint
    ca_crt       = var.ca_crt
    client_crt   = var.client_crt
    client_key   = var.client_key
    token        = var.token
  }
}

# 1.24 change: Create service account secret
resource "kubernetes_secret" "sa_secret" {
  metadata {
    name      = local.service_account_secret_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = local.service_account_name
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Service Account based kube config data/template/resources
data "kubernetes_secret" "sa_secret" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name = "${kubernetes_secret.sa_secret.metadata.0.name}"
    namespace = var.namespace
  }
}

data "template_file" "kubeconfig_sa" {
  count = var.create_static_kubeconfig ? 1 : 0
  template = file("${path.module}/templates/kubeconfig-sa.tmpl")

  vars = {
    cluster_name = var.cluster_name
    endpoint     = var.endpoint
    name         = local.service_account_name
    ca_crt       = base64encode(lookup(data.kubernetes_secret.sa_secret.0.data,"ca.crt", ""))
    token        = lookup(data.kubernetes_secret.sa_secret.0.data,"token", "")
    namespace    = var.namespace
  }
}

## Warning message from hashicorp/terraform-provider-kubernetes is expected 
# Message: "Warning: 'default_secret_name' is no longer applicable for Kubernetes 'v1.24.0' and above"
resource "kubernetes_service_account" "kubernetes_sa" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.service_account_name
    namespace = var.namespace
  }
}


resource "kubernetes_cluster_role_binding" "kubernetes_crb" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.cluster_role_binding_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = var.namespace
  }
}

# kube config file generation
resource "local_file" "kubeconfig" {
  content              = var.create_static_kubeconfig ? data.template_file.kubeconfig_sa.0.rendered : data.template_file.kubeconfig_provider.0.rendered
  filename             = var.path
  file_permission      = "0644"
  directory_permission = "0755"
}
