#!/bin/bash
set -e

CERT_DIR="/home/siebel/siebel_shared_cert"
CERT_PWD="siebel2026"

mkdir -p "$CERT_DIR"

openssl genrsa -out "$CERT_DIR/ca.key" 4096
openssl req -new -x509 -days 3650 -key "$CERT_DIR/ca.key" -out "$CERT_DIR/ca.crt" -subj "/C=EG/ST=Cairo/O=SiebelLab/CN=SiebelLabCA"
openssl genrsa -out "$CERT_DIR/server.key" 2048

cat > "$CERT_DIR/san.cnf" <<EOF
[req]
distinguished_name = req_dn
req_extensions = req_ext
prompt = no

[req_dn]
C=EG
ST=Cairo
O=SiebelLab
CN=siebgw.lab.helmy

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = siebgw.lab.helmy
DNS.2 = siebai.lab.helmy
DNS.3 = siebapp.lab.helmy
DNS.4 = siebdb.lab.helmy
EOF

openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" -config "$CERT_DIR/san.cnf"
openssl x509 -req -days 3650 -in "$CERT_DIR/server.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial -out "$CERT_DIR/server.crt" -extensions req_ext -extfile "$CERT_DIR/san.cnf"
openssl pkcs12 -export -in "$CERT_DIR/server.crt" -inkey "$CERT_DIR/server.key" -out "$CERT_DIR/siebel_bundle.p12" -name "siebel" -passout pass:$CERT_PWD

keytool -importkeystore \
  -srckeystore "$CERT_DIR/siebel_bundle.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass "$CERT_PWD" \
  -destkeystore "$CERT_DIR/siebelkeystore.jks" \
  -deststorepass "$CERT_PWD" \
  -deststoretype JKS \
  -alias siebel \
  -noprompt

keytool -import \
  -trustcacerts \
  -alias siebelca \
  -file "$CERT_DIR/ca.crt" \
  -keystore "$CERT_DIR/siebeltruststore.jks" \
  -storepass "$CERT_PWD" \
  -noprompt

chown -R siebel:oinstall "$CERT_DIR"
chmod 600 "$CERT_DIR"/*.key "$CERT_DIR"/*.p12
chmod 644 "$CERT_DIR"/*.crt "$CERT_DIR"/*.jks

echo "Certs done. Copy to other nodes:"
echo "  scp -r /home/siebel/siebel_shared_cert siebel@siebai:/home/siebel/"
echo "  scp -r /home/siebel/siebel_shared_cert siebel@siebapp:/home/siebel/"