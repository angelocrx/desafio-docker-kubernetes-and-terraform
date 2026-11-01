# 1. Criação do Cluster Kubernetes local via Kind
resource "kind_cluster" "default" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      extra_port_mappings {
        container_port = 30080
        host_port      = 8080
        protocol       = "TCP"
      }
    }
  }
}

# 2. Configuração dos provedores utilizando diretamente os atributos do Kind
provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}

# 3. Deploy do Helm Chart local (o Helm cria e gerencia o namespace automaticamente)
resource "helm_release" "mural" {
  name             = var.release_name
  repository       = "../helm"
  chart            = "mural"
  namespace        = var.namespace
  create_namespace = true

  depends_on = [
    kind_cluster.default
  ]
}