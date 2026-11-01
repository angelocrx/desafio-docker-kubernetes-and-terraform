variable "cluster_name" {
  type        = string
  default     = "kind-cluster-angelo"
  description = "Cluster gerado pelo Kind"
}

variable "namespace" {
  type        = string
  default     = "aula-docker"
  description = "Namespace do Kubernetes"
}

variable "release_name" {
  type        = string
  default     = "mural-release"
  description = "Release do Helm"
}