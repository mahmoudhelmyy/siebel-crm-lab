#!/bin/bash
set -e

IC_DIR="/siebapp/oracle/instantclient_19_29"

cd /home/siebel
[ -f "instantclient-basic-linux-19.29.0.0.0dbru.zip" ] || { echo "ERROR: basic zip missing"; exit 1; }
[ -f "instantclient-sqlplus-linux-19.29.0.0.0dbru.zip" ] || { echo "ERROR: sqlplus zip missing"; exit 1; }

unzip -o instantclient-basic-linux-19.29.0.0.0dbru.zip -d /home/siebel/
unzip -o instantclient-sqlplus-linux-19.29.0.0.0dbru.zip -d /home/siebel/

mkdir -p "$IC_DIR"
cp -a /home/siebel/instantclient_19_29/. "$IC_DIR/"
chown -R siebel:oinstall "$IC_DIR"

cd "$IC_DIR"
ln -sf libclntsh.so.19.1 libclntsh.so 2>/dev/null || true
ln -sf libocci.so.19.1   libocci.so   2>/dev/null || true

mkdir -p "$IC_DIR/network/admin"

cat > "$IC_DIR/network/admin/tnsnames.ora" <<EOF
SIEBEL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = siebdb.lab.helmy)(PORT = 1521))
    (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = SIEBEL))
  )

SiebelInstall_DSN =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = siebdb.lab.helmy)(PORT = 1521))
    (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = SIEBEL))
  )
EOF

cat > "$IC_DIR/network/admin/sqlnet.ora" <<EOF
NAMES.DIRECTORY_PATH = (TNSNAMES, EZCONNECT)
EOF

cat > /home/siebel/.odbc.ini <<EOF
[ODBC Data Sources]
SiebelInstall_DSN = Oracle Wire Protocol

[SiebelInstall_DSN]
ColumnSizeAsCharacter=1
ColumnsAsChar=1
Driver=/siebapp/siebsrvr/../oracledbclient/libsqora.so.19.1
LobPrefetchSize=8388608
FetchBufferSize=1048576
ServerName=SiebelInstall_DSN
EOF

mkdir -p /siebapp/siebsrvr/sys
ln -sf /home/siebel/.odbc.ini /siebapp/siebsrvr/sys/.odbc.ini 2>/dev/null || true

grep -q "SiebelInstall_DSN" /home/siebel/.bash_profile 2>/dev/null || cat >> /home/siebel/.bash_profile <<EOF

export ORACLE_HOME=$IC_DIR
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export SIEBEL_DATA_SOURCE=SiebelInstall_DSN
export LD_LIBRARY_PATH=/siebapp/siebsrvr/lib:\$ORACLE_HOME:\$LD_LIBRARY_PATH
export PATH=\$ORACLE_HOME:\$PATH
export ODBCINI=/home/siebel/.odbc.ini
export SIEBEL_UNIXUNICODE_DB=ORACLE
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
EOF

source /home/siebel/.bash_profile

nc -zv siebdb.lab.helmy 1521 && echo "DB 1521 OK" || echo "DB 1521 FAILED"
nc -zv siebgw.lab.helmy 2320 && echo "GW 2320 OK" || echo "GW 2320 FAILED"

echo "Setup complete"