VAGRANTFILE_API_VERSION = "2"

NODES = {
  "siebdb"  => { ip: "192.168.56.10",  cpus: 2, memory: 4096 },
  "siebgw"  => { ip: "192.168.56.102", cpus: 2, memory: 4096 },
  "siebapp" => { ip: "192.168.56.103", cpus: 2, memory: 6144 },
  "siebai"  => { ip: "192.168.56.104", cpus: 2, memory: 4096 },
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box              = "oraclelinux/8"
  config.vm.box_url          = "https://oracle.github.io/vagrant-projects/boxes/oraclelinux/8.json"
  config.vm.box_check_update = false
  config.vm.synced_folder "./shared", "/installers",
    owner: "root", group: "root", mount_options: ["dmode=755","fmode=644"]

  NODES.each do |name, cfg|
    config.vm.define name do |node|
      node.vm.hostname = "#{name}.lab.helmy"
      node.vm.network "private_network", ip: cfg[:ip]

      node.vm.provider "virtualbox" do |vb|
        vb.name   = "siebel-lab-#{name}"
        vb.cpus   = cfg[:cpus]
        vb.memory = cfg[:memory]
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
      end

      node.vm.provision "shell", name: "hosts", inline: <<~SHELL
        printf "127.0.0.1 localhost\n192.168.56.10 siebdb.lab.helmy siebdb\n192.168.56.102 siebgw.lab.helmy siebgw\n192.168.56.103 siebapp.lab.helmy siebapp\n192.168.56.104 siebai.lab.helmy siebai\n" > /etc/hosts
      SHELL

      node.vm.provision "shell", name: "os-base", inline: <<~SHELL
        setenforce 0 2>/dev/null || true
        sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
        systemctl stop firewalld 2>/dev/null || true
        systemctl disable firewalld 2>/dev/null || true
        dnf install -y csh tcsh net-tools nc wget curl unzip lsof openssl vim 2>/dev/null || true
        groupadd -f oinstall
        id siebel >/dev/null 2>&1 || useradd -m -g oinstall -s /bin/bash siebel
        echo "siebel:siebel2026" | chpasswd
        mkdir -p /u01/app/oraInventory
        chown -R siebel:oinstall /u01/app/oraInventory
        chmod -R 775 /u01/app/oraInventory
        printf "inventory_loc=/u01/app/oraInventory\ninst_group=oinstall\n" > /etc/oraInst.loc
        chmod 664 /etc/oraInst.loc
      SHELL

      case name
      when "siebdb"
        node.vm.provision "shell", name: "db-prep", inline: <<~SHELL
          dnf install -y oracle-database-preinstall-19c 2>/dev/null || dnf install -y binutils gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libgcc libstdc++ make sysstat unzip
          mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1 /u01/oradata/SIEBEL /u01/fra/SIEBEL
          chown -R oracle:oinstall /u01 2>/dev/null || chown -R siebel:oinstall /u01
        SHELL
      when "siebgw"
        node.vm.provision "shell", name: "gw-prep", inline: <<~SHELL
          dnf install -y java-11-openjdk java-11-openjdk-headless 2>/dev/null || true
          rm -rf /siebgw && mkdir -p /siebgw
          chown siebel:oinstall /siebgw && chmod 775 /siebgw
          mkdir -p /home/siebel/siebel_shared_cert
          chown -R siebel:oinstall /home/siebel/siebel_shared_cert
        SHELL
      when "siebapp"
        node.vm.provision "shell", name: "app-prep", inline: <<~SHELL
          dnf install -y java-21-openjdk java-21-openjdk-headless 2>/dev/null || true
          dnf install -y libnsl.i686 glibc.i686 libstdc++.i686 libgcc.i686 libaio.i686 zlib.i686 ncurses-libs.i686 libxcrypt.i686 2>/dev/null || true
          LIBNSL32=$(find /usr/lib -name "libnsl-*.so" 2>/dev/null | head -1)
          [ -n "$LIBNSL32" ] && ln -sf "$LIBNSL32" /usr/lib/libnsl.so.1 2>/dev/null || true
          rm -rf /siebapp && mkdir -p /siebapp /siebfs
          chown siebel:oinstall /siebapp /siebfs && chmod 775 /siebapp /siebfs
        SHELL
      when "siebai"
        node.vm.provision "shell", name: "ai-prep", inline: <<~SHELL
          dnf install -y java-21-openjdk java-21-openjdk-headless 2>/dev/null || true
          dnf install -y libnsl.i686 glibc.i686 libstdc++.i686 libxcrypt.i686 2>/dev/null || true
          rm -rf /siebai && mkdir -p /siebai
          chown siebel:oinstall /siebai && chmod 775 /siebai
          mkdir -p /home/siebel/siebel_shared_cert
          chown -R siebel:oinstall /home/siebel/siebel_shared_cert
        SHELL
      end

      node.vm.provision "shell", name: "done", inline: "echo '=== #{name.upcase} provisioned OK ==='"
    end
  end
end