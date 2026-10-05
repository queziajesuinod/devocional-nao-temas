# ---------- Stage 1: clona o repositório ----------
FROM alpine:3.20 AS source

ARG REPO_URL=https://github.com/queziajesuinod/devocional-nao-temas.git
ARG REPO_REF=main
# Passe --build-arg CACHEBUST=$(date +%s) para forçar novo clone (sem cache)
ARG CACHEBUST=0

WORKDIR /tmp

RUN apk add --no-cache git
RUN echo "cachebust=${CACHEBUST}" && \
    git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" project

# ---------- Stage 2: serve com nginx ----------
FROM nginx:1.27-alpine

# Configuração do nginx (inclui o endpoint /healthz)
COPY --from=source /tmp/project/nginx/default.conf /etc/nginx/conf.d/default.conf

# Página de venda, página de obrigado e arquivos estáticos
COPY --from=source /tmp/project/index.html /usr/share/nginx/html/index.html
COPY --from=source /tmp/project/obrigado   /usr/share/nginx/html/obrigado
COPY --from=source /tmp/project/fonts      /usr/share/nginx/html/fonts
COPY --from=source /tmp/project/img        /usr/share/nginx/html/img

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
