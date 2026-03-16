#!/bin/bash
set -e

SIEBEL_ROOT="/siebgw"

dnf install -y csh 2>/dev/null || dnf install -y tcsh

for item in include conf release legal bin lib; do
  [ ! -e "$SIEBEL_ROOT/jre/$item" ] && ln -s "$SIEBEL_ROOT/jre/21.0/$item" "$SIEBEL_ROOT/jre/$item" 2>/dev/null || true
done

for item in bin lib locale; do
  [ ! -e "$SIEBEL_ROOT/gtwysrvr/$item" ] && ln -s "$SIEBEL_ROOT/siebsrvr/$item" "$SIEBEL_ROOT/gtwysrvr/$item" 2>/dev/null || true
done

for dir in dbsrvr eaiconn; do
  for item in bin lib locale; do
    [ ! -e "$SIEBEL_ROOT/$dir/$item" ] && ln -s "$SIEBEL_ROOT/siebsrvr/$item" "$SIEBEL_ROOT/$dir/$item" 2>/dev/null || true
  done
done

ZK_CONF="$SIEBEL_ROOT/gtwysrvr/registry/conf"
[ -d "$ZK_CONF" ] && [ -f "$ZK_CONF/registry.cfg" ] && [ ! -e "$ZK_CONF/zoo.cfg" ] && ln -s "$ZK_CONF/registry.cfg" "$ZK_CONF/zoo.cfg"

CERT_SRC="/home/siebel/siebel_shared_cert"
CERT_DST="$SIEBEL_ROOT/applicationcontainer_internal/siebelcerts"
[ -d "$CERT_SRC" ] && [ -d "$CERT_DST" ] && cp "$CERT_SRC"/*.jks "$CERT_DST/" && chown siebel:oinstall "$CERT_DST"/*.jks

JAVA11=$(find /usr/lib/jvm -maxdepth 1 -name "java-11-openjdk*" -type d | head -1)
printf 'JAVA_HOME=%s\nexport JAVA_HOME\nunset JRE_HOME\nexport PATH="$JAVA_HOME/bin:$PATH"\n' "$JAVA11" > "$SIEBEL_ROOT/applicationcontainer_internal/bin/setenv.sh"
chmod 750 "$SIEBEL_ROOT/applicationcontainer_internal/bin/setenv.sh"

echo "GW post-install fix done. Start with:"
echo "  cd $SIEBEL_ROOT/gtwysrvr && . ./siebenv.sh && start_ns"
echo "  cd $SIEBEL_ROOT/applicationcontainer_internal/bin && ./startup.sh"