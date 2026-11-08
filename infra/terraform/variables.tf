variable "cluster_name" {
  type        = string
  default     = "kind-cluster-angelo"
  description = "Cluster gerado pelo Kind"
}

variable "namespace" {
  type        = string
  default     = "mural"
  description = "Namespace do Kubernetes"
}

variable "ingress_host" {
  type        = string
  default     = "mural.localtest.me"
  description = "Host do Ingress (localtest.me resolve para 127.0.0.1)"
}

variable "release_name" {
  type        = string
  default     = "mural-release"
  description = "Release do Helm"
}
