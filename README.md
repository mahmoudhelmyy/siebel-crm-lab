# Siebel CRM v25.12 -- 4-Node Vagrant Lab

**Author:** Mahmoud Helmy

Complete lab environment for Siebel CRM v25.12 (IP2019) on Oracle Linux 8 + Oracle DB 19c.

## Lab Architecture

| Node    | FQDN                  | IP              | Role                          | Ports       |
|---------|-----------------------|-----------------|-------------------------------|-------------|
| siebdb  | siebdb.lab.helmy      | 192.168.56.10   | Oracle DB 19c                 | 1521        |
| siebgw  | siebgw.lab.helmy      | 192.168.56.102  | Cloud Gateway + ZooKeeper     | 2320, 8443  |
| siebapp | siebapp.lab.helmy     | 192.168.56.103  | App Server + DB Config Utils  | 8443, 2321  |
| siebai  | siebai.lab.helmy      | 192.168.56.104  | Application Interface (SMC)   | 8443, 8080  |

## Requirements
- VirtualBox 7+
- Vagrant 2.3+
- `vagrant plugin install vagrant-disksize`
- Siebel 25.12 installer (Oracle licensed -- not included)
- Oracle 19c DB installer (Oracle licensed -- not included)

## Quick Start

```bash
git clone https://github.com/mahmoudhelmyy/siebel-crm-lab.git
cd siebel-crm-lab
# Add media to shared/25.12/install/ and shared/oracle/
vagrant up
vagrant ssh siebgw
```

## Install Sequence

Strict order: DB -> Gateway -> Enterprise -> App Server -> App Interface

| Step | Node    | Action |
|------|---------|--------|
| 1    | siebgw  | bash /installers/scripts/gen_shared_certs.sh |
| 2    | siebdb  | Install Oracle 19c + siebel_db_setup.sh |
| 3    | siebgw  | Siebel OUI (Enterprise Container) + gw_postinstall_fix.sh |
| 4    | siebai  | Siebel OUI (App Interface) + ai_postinstall.sh |
| 5    | browser | SMC: https://siebai.lab.helmy:8443/siebel/smc |
| 6    | siebapp | Siebel OUI + app_oracle_client_setup.sh + deploy from SMC |
| 7    | any     | bash /installers/scripts/connectivity_check.sh |

## Credentials

| Service          | User     | Password     |
|------------------|----------|--------------|
| Oracle DB SYS    | SYS      | sysdba2026   |
| Siebel owner     | SIEBEL   | siebel2026   |
| Siebel admin     | SADMIN   | sadmin2026   |
| SMC first login  | smclogin | smclogin     |
| SMC after setup  | SADMIN   | sadmin2026   |
| SSL keystores    | --       | siebel2026   |
| OS siebel user   | siebel   | siebel2026   |

## Key Lessons from Real Lab

| Issue | Cause | Fix |
|-------|-------|-----|
| OUI symlinks missing | /bin/csh not installed | dnf install -y csh BEFORE runInstaller.sh |
| libsslcsecm.so missing | Siebel lib path not set | Add /siebapp/siebsrvr/lib to LD_LIBRARY_PATH |
| ddlimp fails | ODBC DSN not resolved | Set ODBCINI, link ~/.odbc.ini to sys/.odbc.ini |
| Installer steps 8-16 skipped | Oracle client not in PATH | source ~/.bash_profile before OUI |
| ZooKeeper not starting | zoo.cfg missing | ln -s registry.cfg zoo.cfg |
| AI container wrong Java | setenv.sh missing | Create with JAVA_HOME=/siebapp/jre/21.0 |
| ORA-06550 grantusr.sql | Bare DDL in PL/SQL | Wrap ALTER USER in EXECUTE IMMEDIATE |
| ODBC IM002 error | Wrong ODBCINI path | export ODBCINI=/home/siebel/.odbc.ini |
| siebapp1 crash restart | Stale shm/osdf files | Move stale files before start_server |
