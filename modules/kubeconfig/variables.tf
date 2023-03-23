# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used for all Azure Cloud resources created by this script."
  type        = string
}

variable "namespace" {
  description = "Namespace that the service account and cluster role binding will placed."
  type        = string
  default     = "kube-system"
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider/service account based kube config file."
  type        = bool
  default     = true
}

variable "path" {
  description = "Path to the file that will be read. The data source will return an error if the file does not exist."
  type        = string
}

variable "cluster_name" {
  description = "The name for the AKS resources created in the specified Azure Resource Group."
  type        = string
}

variable "endpoint" {
  description = "The Kubernetes cluster server host."
  type        = string
}

variable "ca_crt" {
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster."
  type        = string
}

variable "client_crt" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster."
  type        = string
}

variable "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster."
  type        = string
}

variable "token" {
  description = "A password or token used to authenticate to the Kubernetes cluster."
  type        = string
}
