output "kube_config" {
  value = local_file.kubeconfig.content
}
