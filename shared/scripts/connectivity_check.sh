#!/bin/bash

PASS=0
FAIL=0

check() {
  nc -zv "$2" "$3" >/dev/null 2>&1 && { echo "  [OK]   $1"; ((PASS++)); } || { echo "  [FAIL] $1"; ((FAIL++)); }
}

echo "======================================================"
echo "  Siebel Lab Connectivity Check"
echo "======================================================"

check "siebdb  :1521 Oracle"          siebdb.lab.helmy  1521
check "siebgw  :2320 Gateway/ZK"      siebgw.lab.helmy  2320
check "siebgw  :8090 Internal Tomcat" siebgw.lab.helmy  8090
check "siebapp :8443 App container"   siebapp.lab.helmy 8443
check "siebapp :2321 SCBroker"        siebapp.lab.helmy 2321
check "siebai  :8443 AI HTTPS"        siebai.lab.helmy  8443
check "siebai  :8080 AI HTTP"         siebai.lab.helmy  8080

echo "  Passed: $PASS  Failed: $FAIL"

echo ruok | nc -w 2 siebgw.lab.helmy 2320 2>/dev/null | grep -q imok && echo "  ZK: imok" || echo "  ZK: no response"