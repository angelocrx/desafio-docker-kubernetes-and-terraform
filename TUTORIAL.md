# Mural de Recados: do Compose ao Kubernetes com Terraform

Como eu resolvi o desafio e como você sobe a app aí na sua máquina.

A app tem três pedaços: um **front** em nginx, uma **API** em Go e um **Postgres**.

## A jornada

1. **Compose, um pedaço por vez.** Primeiro o front, depois a API (Dockerfile em dois estágios: um compila, o outro só leva o binário), depois o Postgres com healthcheck. Por último, fiz a API esperar o banco ficar saudável antes de subir.
2. **Manifestos na mão.** Front, API, Postgres (StatefulSet) e Ingress. Tomei um erro de namespace no caminho. O front começou como `NodePort` e virou `ClusterIP` quando o Ingress chegou.
3. **Helm.** Tudo virou um chart: configurações no `values.yaml`, senha num Secret e a migração num Job que roda antes de a API ficar pronta.
4. **Terraform.** A primeira versão criava o cluster, mas a app não subia: faltava carregar as imagens, instalar o Traefik e passar a senha. Na versão final, um comando faz tudo isso. O último tropeço foi o Traefik como LoadBalancer, que nunca fica pronto no kind; virou `ClusterIP` e passou. Rodei o `apply` duas vezes, e o segundo deu "No changes".

## Ferramentas

Confere se tudo responde:

```bash
git --version
docker info               # o Docker Desktop precisa estar aberto
kind version
terraform version         # 1.4 ou mais nova
kubectl version --client
helm version              # só para o caminho "só com Helm"
```

Faltou alguma? [Git](https://git-scm.com/downloads) · [Docker](https://docs.docker.com/get-docker/) · [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) · [Terraform](https://developer.hashicorp.com/terraform/install) · [kubectl](https://kubernetes.io/docs/tasks/tools/) · [Helm](https://helm.sh/docs/intro/install/)

Eu usei Git 2.54, Docker 29.5, kind 0.33, Terraform 1.16, kubectl 1.34 e Helm 4.3.

## Faxina (se já mexeu no projeto antes)

Roda da raiz do projeto. Pode rodar sem medo: se não existir nada, os comandos só seguem em frente.

```bash
kind delete cluster --name kind-cluster-angelo
kind delete cluster --name mural-helm
docker compose -f app/docker/docker-compose.yml down -v
```

Com o cluster apagado, apaga também a memória do Terraform:

```bash
# Linux / Mac / Git Bash
rm -f infra/terraform/terraform.tfstate* ~/.kube/kind-cluster-angelo-config

# Windows (PowerShell)
Remove-Item infra/terraform/terraform.tfstate*, $HOME/.kube/kind-cluster-angelo-config -Force -ErrorAction SilentlyContinue
```

## Subindo com Terraform

As portas 80 e 443 precisam estar livres.

```bash
git clone https://github.com/angelocrx/desafio-docker-kubernetes-and-terraform.git
cd desafio-docker-kubernetes-and-terraform/infra/terraform
terraform init
terraform apply           # responde yes
```

Abre **http://mural.localtest.me** (o `localtest.me` aponta para a sua própria máquina).

Para conferir:

```bash
kubectl --kubeconfig $HOME/.kube/kind-cluster-angelo-config get pods -n mural
```

API, front e Postgres têm que estar em `Running`, e o `mural-migrate` em `Completed`. Roda `terraform apply` de novo: tem que dar **No changes**.

Para desligar: `terraform destroy`.

## Outros jeitos de rodar

### Só com Docker

```bash
cd app/docker
docker compose up --build
```

Abre **http://localhost:9090**. Para parar: `Ctrl+C` e depois `docker compose down`. Esse modo usa as portas 9090, 8080 e 5432.

### Só com Helm

Da raiz do projeto:

```bash
kind delete cluster --name mural-helm
kind create cluster --name mural-helm

cd app
docker build -t docker-api:latest -f docker/api.Dockerfile .
docker build -t docker-frontend:latest -f docker/web.Dockerfile .
kind load docker-image docker-api:latest docker-frontend:latest --name mural-helm

cd ../infra/helm
helm install mural ./mural -n mural --create-namespace --set namespace=mural --set postgres.password=MinhaSenhaForte --set ingress.enabled=false
```

Quando o `kubectl get pods -n mural` mostrar tudo de pé, abre o túnel e acessa **http://localhost:8080**:

```bash
kubectl port-forward svc/nginx-frontend 8080:8080 -n mural
```

Para desligar: `kind delete cluster --name mural-helm`.
