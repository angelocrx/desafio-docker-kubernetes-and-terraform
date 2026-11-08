# Mural de Recados: do Compose ao Kubernetes com Terraform

Entrega do desafio Docker + Kubernetes + Terraform. O Mural (front em nginx, API em Go e Postgres)
sai de um `docker compose` e vai para um cluster **kind** provisionado e implantado só com Terraform.

- Passo a passo para rodar (Terraform, só Docker ou só Helm): [`TUTORIAL.md`](TUTORIAL.md)
- Arquitetura-alvo: [`docs/arquitetura.md`](docs/arquitetura.md)

Resumo:

```bash
cd infra/terraform
terraform init
terraform apply      # cria o cluster, builda e carrega as imagens, instala o Traefik e o chart
# abra http://mural.localtest.me
terraform apply      # segunda vez: "No changes"
terraform destroy    # remove tudo
```

## Tamanho da imagem da API

| Versão | Base final | No disco | Download (compactada) |
|--------|-----------|---------:|----------------------:|
| Antes: `go run` no compose | `golang:1.23-alpine` | 291,4 MB | 78,2 MB |
| Primeira tentativa: multi-stage | `alpine:3.19` | 21,8 MB | 10,2 MB |
| **Agora: multi-stage** | **`gcr.io/distroless/static-debian12:nonroot`** | **14,9 MB** | **4,1 MB** |

Medido com `docker history` (soma das camadas descompactadas) e `docker image inspect` (conteúdo compactado).

O que fez a diferença:

- **Multi-stage**: o estágio `golang` compila e é descartado; a imagem final leva só o binário.
- **Binário estático e enxuto**: `CGO_ENABLED=0` (não depende da libc) e `-ldflags="-s -w"` (sem tabela de
  símbolos e informação de debug), o que derrubou o binário de 13,7 MB para 9,4 MB.
- **distroless/static**: sem shell e sem gerenciador de pacotes, só certificados, fuso horário e `/etc/passwd`.
  A variante `nonroot` já roda como usuário sem privilégio (UID 65532).

## Decisões

- **Front parametrizável**: o `web.Dockerfile` copia o `app/web/nginx.conf.template` para
  `/etc/nginx/templates/`. No boot, a imagem oficial do nginx troca `${API_UPSTREAM}` pelo valor da variável
  de ambiente, então a mesma imagem serve no compose (`api:8080`) e no cluster (definido pelo chart).
- **Probes**: liveness em `/healthz` (só diz que o processo está vivo) e readiness em `/readyz` (só passa com o
  banco respondendo e a tabela criada). Liveness no `/readyz` mataria o pod enquanto a migração não roda.
- **Migração**: um `Job` com `psql` aplica as migrations, montadas de um `ConfigMap`. A readiness da API segura o
  tráfego até ele terminar.
- **Postgres**: `StatefulSet` com `volumeClaimTemplates`, para os dados sobreviverem a restart do pod.
- **Senha do banco**: o Terraform gera com `random_password` e passa ao chart como valor sensível; o chart
  monta um `Secret` e a API recebe a `DATABASE_URL` por `secretKeyRef`. O `values.yaml` não tem senha, e o
  chart recusa instalar sem uma.
- **Requests e limits** em API, front e Postgres, definidos no `values.yaml`.
- **Ingress**: Traefik, com o host vindo do `values.yaml` (`mural.localtest.me`, que resolve para 127.0.0.1);
  `/api` vai para a API e `/` para o front.
- **Traefik no kind**: o kind não tem LoadBalancer, então o Traefik usa `hostPort` 80/443 no nó com o label
  `ingress-ready=true` e Service `ClusterIP`.
- **Idempotência**: a tag de cada imagem é o hash dos arquivos que a compõem. Sem mudança no código, a tag é a
  mesma e o Terraform não rebuilda nem reimplanta nada.
