variable "prefix" {
  description = "A prefix used for all Google Cloud resources created by this script"
  type        = string
}

variable "namespace" {
  description = "Namespace that the service account and cluster role binding will placed."
  type        = string
  default     = "kube-system"
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = false
}

variable "path" {}
variable "cluster_name" {}
variable "endpoint" {}
variable "ca_crt" {}
variable "client_crt" {}
variable "client_key" {}
variable "token" {}


