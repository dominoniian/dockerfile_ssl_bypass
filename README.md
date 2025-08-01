# Docker com Certificado Corporativo SSL

Este Dockerfile cria uma imagem Alpine Linux que funciona perfeitamente em ambientes corporativos com inspeção SSL/Deep Packet Inspection, sem desabilitar verificações de segurança.

## Arquivos Necessários

- `Dockerfile` - Arquivo principal da imagem
- `host-ca-certificates.crt` - Bundle de certificados CA do sistema host

## Como Gerar o Bundle de Certificados

Para criar o arquivo `host-ca-certificates.crt` necessário:

```bash
cp /etc/ssl/certs/ca-certificates.crt ./host-ca-certificates.crt
```

Este arquivo contém todos os certificados confiáveis do sistema host, incluindo o certificado corporativo.

## Explicação do Dockerfile

### Linha por Linha

```dockerfile
FROM alpine:3.22
```
**Base da imagem:** Usa Alpine Linux 3.22 como sistema operacional base.

```dockerfile
COPY host-ca-certificates.crt /tmp/host-certs.crt
```
**Backup do bundle:** Copia o bundle de certificados CA do sistema host para um local temporário.

```dockerfile
RUN sed -i 's|https://|http://|g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache ca-certificates curl wget openssl && \
    cp /tmp/host-certs.crt /etc/ssl/certs/ca-certificates.crt && \
    sed -i 's|http://|https://|g' /etc/apk/repositories && \
    apk update
```
**Processo híbrido de instalação:**
1. Temporariamente muda repositórios APK para HTTP (necessário para ambiente corporativo)
2. Atualiza índices de pacotes e instala ferramentas essenciais
3. Substitui o bundle de certificados Alpine pelo bundle do sistema host (que já confia no certificado corporativo)
4. Restaura repositórios APK para HTTPS 
5. Testa que APK agora funciona via HTTPS com o novo bundle


## Como Usar

### 1. Preparar o bundle de certificados:
```bash
cp /etc/ssl/certs/ca-certificates.crt ./host-ca-certificates.crt
```

### 2. Construir a imagem:
```bash
docker build -t minha-imagem-ssl .
```

### 3. Executar o container:
```bash
docker run -it minha-imagem-ssl
```

### 4. Testar conectividade SSL:
```bash
# Dentro do container
curl -v https://www.google.com
wget https://httpbin.org/json
```

## Vantagens desta Solução

✅ **Solução definitiva:** Restaura HTTPS para APK e aplicações  
✅ **Sem compromissos de segurança:** Não usa repositórios HTTP permanentes ou flags inseguros  
✅ **Híbrida inteligente:** HTTP apenas durante instalação, HTTPS para uso final  
✅ **Universal:** Funciona em qualquer ambiente corporativo com DPI  
✅ **Mínima:** Apenas 7 linhas efetivas no Dockerfile  
✅ **Compatível:** Suporta Python requests, curl, wget, apk e todas as ferramentas SSL  

## Como Funciona

A solução usa uma abordagem híbrida:

1. **Fase de Build (HTTP temporário):** Durante a construção da imagem, usa repositórios HTTP temporariamente para instalar os pacotes necessários, evitando problemas de SSL com o APK.

2. **Integração do Bundle:** Substitui o bundle de certificados padrão do Alpine pelo bundle do sistema host, que já confia no certificado corporativo.

3. **Restauração HTTPS:** Após a instalação, restaura os repositórios APK para HTTPS, que agora funcionam graças ao bundle corporativo.

4. **Resultado Final:** Container com APK e todas as aplicações funcionando 100% via HTTPS de forma segura.

## Solução de Problemas

Se ainda houver problemas de SSL, verifique:

1. **Bundle do host está atualizado:**
   ```bash
   ls -la /etc/ssl/certs/ca-certificates.crt
   ```

2. **Container confia no certificado:**
   ```bash
   docker run --rm minha-imagem-ssl openssl s_client -connect google.com:443 -verify_return_error
   ```

3. **APK funciona via HTTPS:**
   ```bash
   docker run --rm minha-imagem-ssl apk update
   ```