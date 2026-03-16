#!/bin/bash
set -e

SIEBEL_ROOT="/siebai"
CERT_SRC="/home/siebel/siebel_shared_cert"
CERT_PWD="siebel2026"

JAVA21=$(find /usr/lib/jvm -maxdepth 1 -name "java-21-openjdk*" -type d | head -1)
[ -z "$JAVA21" ] && JAVA21="$SIEBEL_ROOT/jre/21.0"

printf 'JAVA_HOME=%s\nexport JAVA_HOME\nunset JRE_HOME\nexport PATH="$JAVA_HOME/bin:$PATH"\n' "$JAVA21" > "$SIEBEL_ROOT/applicationcontainer_external/bin/setenv.sh"
chmod 750 "$SIEBEL_ROOT/applicationcontainer_external/bin/setenv.sh"

CERT_DST="$SIEBEL_ROOT/applicationcontainer_external/siebelcerts"
mkdir -p "$CERT_DST"
[ -d "$CERT_SRC" ] && cp "$CERT_SRC"/*.jks "$CERT_DST/" && chown -R siebel:oinstall "$CERT_DST"

for p in "$SIEBEL_ROOT/applicationinterface" "$SIEBEL_ROOT/applicationcontainer_external" "$SIEBEL_ROOT/applicationcontainer_external/conf/server.xml"; do
  [ -e "$p" ] && echo "OK: $p" || echo "MISSING: $p"
done

cd "$SIEBEL_ROOT/applicationcontainer_external/bin"
./startup.sh
sleep 8
tail -50 ../logs/catalina.out
ss -lntp | egrep "8080|8443|8005"

echo "SMC URL: https://siebai.lab.helmy:8443/siebel/smc"
echo "First login: smclogin / smclogin"