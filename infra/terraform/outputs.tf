output "cluster_name" {
  value       = kind_cluster.default.name
  description = "Nome do cluster Kind criado"
}

output "namespace_name" {
  value       = var.namespace
  description = "Namespace utilizado no Kubernetes"
}

output "helm_release_status" {
  value       = helm_release.mural.status
  description = "Status atual do release do Helm"
}