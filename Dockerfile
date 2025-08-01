FROM alpine:3.22
COPY host-ca-certificates.crt /tmp/host-certs.crt

RUN sed -i 's|https://|http://|g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache ca-certificates curl wget openssl && \
    cp /tmp/host-certs.crt /etc/ssl/certs/ca-certificates.crt && \
    sed -i 's|http://|https://|g' /etc/apk/repositories && \
    apk update

