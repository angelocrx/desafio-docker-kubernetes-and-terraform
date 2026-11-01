output "cluster_name" {
  value       = kind_cluster.default.name
  description = "Nome do cluster Kind criado"
}

output "namespace_name" {
  value       = kubernetes_namespace.mural.metadata[0].name
  description = "Namespace utilizado no Kubernetes"
}

output "helm_release_status" {
  value       = helm_release.mural.status
  description = "Status atual do release do Helm"
}

output "app_url" {
  value       = "http://mural.localtest.me"
  description = "Endereço do Mural (localtest.me resolve para 127.0.0.1)"
}

output "kubeconfig_path" {
  value       = kind_cluster.default.kubeconfig_path
  description = "Kubeconfig do cluster: kubectl --kubeconfig <caminho> get pods -n mural"
}
