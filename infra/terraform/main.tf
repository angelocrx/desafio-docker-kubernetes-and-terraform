locals {
  app_dir = abspath("${path.module}/../../app")

  # Cada imagem é reconstruída e recarregada no kind só quando algum arquivo de origem muda.
  images = {
    api = {
      name       = "docker-api"
      dockerfile = "docker/api.Dockerfile"
      sources    = ["api/**", "docker/api.Dockerfile"]
    }
    web = {
      name       = "docker-frontend"
      dockerfile = "docker/web.Dockerfile"
      sources    = ["web/**", "docker/web.Dockerfile"]
    }
  }

  image_tags = {
    for key, image in local.images : key => substr(sha1(join("", [
      for file in sort(flatten([for pattern in image.sources : tolist(fileset(local.app_dir, pattern))])) :
      filesha1("${local.app_dir}/${file}")
    ])), 0, 12)
  }
}

# 1. Cluster kind com o nó preparado para receber o Ingress em localhost:80/443
resource "kind_cluster" "default" {
  name            = var.cluster_name
  kubeconfig_path = pathexpand("~/.kube/${var.cluster_name}-config")
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [<<-EOT
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
  }
}

# 2. Provedores apontando para o cluster recém-criado
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

# 3. Imagens da aplicação: build local e carga no nó do kind (não há registry)
resource "terraform_data" "image" {
  for_each = local.images

  input            = local.image_tags[each.key]
  triggers_replace = [local.image_tags[each.key], kind_cluster.default.id]

  provisioner "local-exec" {
    working_dir = local.app_dir
    command     = "docker build -t ${each.value.name}:${self.input} -f ${each.value.dockerfile} . && kind load docker-image ${each.value.name}:${self.input} --name ${kind_cluster.default.name}"
  }
}

# 4. Ingress controller (Traefik) escutando nas portas 80/443 do nó mapeadas pelo kind
resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "41.7.1"
  namespace        = "traefik"
  create_namespace = true

  values = [yamlencode({
    nodeSelector = { "ingress-ready" = "true" }
    service      = { spec = { type = "ClusterIP" } }
    ports = {
      web       = { hostPort = 80 }
      websecure = { hostPort = 443 }
    }
    # Com hostPort não cabem dois pods no mesmo nó; o padrão (maxSurge 1) travaria o rollout.
    updateStrategy = {
      rollingUpdate = { maxUnavailable = 1, maxSurge = 0 }
    }
  })]
}

# 5. Credencial do banco gerada aqui, fora de qualquer arquivo versionado
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "kubernetes_namespace" "mural" {
  metadata {
    name = var.namespace
  }
}

# 6. Deploy do chart do Mural
resource "helm_release" "mural" {
  name      = var.release_name
  chart     = "${path.module}/../helm/mural"
  namespace = kubernetes_namespace.mural.metadata[0].name

  values = [yamlencode({
    namespace = kubernetes_namespace.mural.metadata[0].name
    api = {
      image = local.images.api.name
      tag   = terraform_data.image["api"].output
    }
    web = {
      image = local.images.web.name
      tag   = terraform_data.image["web"].output
    }
    ingress = { host = var.ingress_host }
  })]

  set_sensitive {
    name  = "postgres.password"
    value = random_password.db.result
  }

  depends_on = [helm_release.traefik]
}
