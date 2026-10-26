FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copia os arquivos de dependências do Go
COPY ../api/go.mod ../api/go.sum* ./

# Baixa as dependências
RUN go mod download

# Copia o restante do código da API
COPY ../api/ ./

# Compila o binário estático
# CGO_ENABLED=0 garante um binário 100% estático sem dependências C
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:3.19

WORKDIR /root/

# Copia apenas o binário compilado do estágio anterior
COPY --from=builder /app/main .

EXPOSE 8080

# Comando para rodar a aplicação
CMD ["./main"]