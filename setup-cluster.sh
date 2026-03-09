#!/bin/bash

# ============================================================
# ميزة التنظيف الذاتي: إصلاح صيغة الويندوز (CRLF) إلى لينكس (LF) تلقائياً
# ============================================================
if grep -q $'\r' "$0"; then
    echo -e "\033[1;33m[!] تم اكتشاف صيغة Windows (CRLF). جاري تنظيف الملف وإعادة التشغيل تلقائياً...\033[0m"
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

#============================================================
# Nomad & Consul Cluster - Final Production Script
# OS: Ubuntu 24.04 (Multipass VMs)
# Usage:
#   Server: sudo bash setup-cluster.sh server <SERVER_IP>
#   Client: sudo bash setup-cluster.sh client <SERVER_IP> <CONSUL_KEY>
#============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step()    { echo -e "\n${CYAN}=== [STEP $1] $2 ===${NC}\n"; }
print_success() { echo -e "${GREEN}[OK] $1${NC}"; }
print_error()   { echo -e "${RED}[X] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }

# ===================== فحص الصلاحيات =====================
if [[ $EUID -ne 0 ]]; then
    print_error "يحتاج صلاحيات root: sudo bash $0 ..."
    exit 1
fi

# ===================== قراءة المدخلات =====================
NODE_ROLE="${1:-}"
NOMAD_SERVER_IP="${2:-}"
CONSUL_ENCRYPT_KEY="${3:-}"

if [[ -z "$NODE_ROLE" || -z "$NOMAD_SERVER_IP" ]]; then
    echo ""
    echo "Usage:"
    echo "  Server:  sudo bash $0 server <SERVER_IP>"
    echo "  Client:  sudo bash $0 client <SERVER_IP> <CONSUL_KEY>"
    echo ""
    echo "Example:"
    echo "  sudo bash $0 server 192.168.1.10"
    echo "  sudo bash $0 client 192.168.1.10 RBgDvT73wRJQ8PbgG..."
    exit 1
fi

if [[ "$NODE_ROLE" == "client" && -z "$CONSUL_ENCRYPT_KEY" ]]; then
    print_error "Client يحتاج مفتاح Consul"
    echo "  sudo bash $0 client <SERVER_IP> <CONSUL_KEY>"
    exit 1
fi

MY_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

echo ""
echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}  Role:      ${NODE_ROLE^^}${NC}"
echo -e "${YELLOW}  My IP:     ${MY_IP}${NC}"
echo -e "${YELLOW}  Hostname:  ${HOSTNAME}${NC}"
echo -e "${YELLOW}  Server IP: ${NOMAD_SERVER_IP}${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

#============================================================
# STEP 1: Docker + unzip
#============================================================
print_step "1" "تثبيت Docker و unzip"

apt-get update -y
apt-get install -y docker.io unzip

systemctl enable docker
systemctl start docker

ACTUAL_USER="${SUDO_USER:-$USER}"
usermod -aG docker "$ACTUAL_USER" 2>/dev/null || true

print_success "Docker $(docker --version | awk '{print $3}')"

#============================================================
# STEP 2: تثبيت Nomad و Consul من الملفات
#============================================================
print_step "2" "تثبيت Nomad و Consul"

NOMAD_VER="1.9.7"
CONSUL_VER="1.22.5"

cd /tmp

# ---- Nomad ----
if ! command -v nomad &> /dev/null; then
    if [[ ! -f ~/nomad.zip ]]; then
        print_warning "تحميل Nomad ${NOMAD_VER}..."
        wget -q "https://releases.hashicorp.com/nomad/${NOMAD_VER}/nomad_${NOMAD_VER}_linux_amd64.zip" -O nomad.zip || {
            print_error "فشل تحميل Nomad - تأكد من الاتصال أو انقل الملف يدوياً"
            exit 1
        }
    else
        cp ~/nomad.zip /tmp/nomad.zip
    fi
    unzip -o nomad.zip
    mv nomad /usr/local/bin/
    chmod +x /usr/local/bin/nomad
    rm -f nomad.zip
    print_success "Nomad $(nomad version | head -1)"
else
    print_success "Nomad موجود: $(nomad version | head -1)"
fi

# ---- Consul ----
if ! command -v consul &> /dev/null; then
    if [[ ! -f ~/consul.zip ]]; then
        print_warning "تحميل Consul ${CONSUL_VER}..."
        wget -q "https://releases.hashicorp.com/consul/${CONSUL_VER}/consul_${CONSUL_VER}_linux_amd64.zip" -O consul.zip || {
            print_error "فشل تحميل Consul - تأكد من الاتصال أو انقل الملف يدوياً"
            exit 1
        }
    else
        cp ~/consul.zip /tmp/consul.zip
    fi
    unzip -o consul.zip
    mv consul /usr/local/bin/
    chmod +x /usr/local/bin/consul
    rm -f consul.zip
    print_success "Consul $(consul version | head -1)"
else
    print_success "Consul موجود: $(consul version | head -1)"
fi

#============================================================
# STEP 3: إنشاء systemd services
#============================================================
print_step "3" "إنشاء systemd services"

# ---- Consul Service ----
cat > /etc/systemd/system/consul.service <<'EOF'
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# ---- Nomad Service ----
cat > /etc/systemd/system/nomad.service <<'EOF'
[Unit]
Description=Nomad Agent
Requires=network-online.target consul.service
After=network-online.target consul.service

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d/
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

print_success "systemd services created"

#============================================================
# STEP 4: إعداد Consul
#============================================================
print_step "4" "إعداد Consul"

mkdir -p /etc/consul.d /opt/consul

if [[ "$NODE_ROLE" == "server" ]]; then

    # توليد مفتاح إذا لم يمرر
    if [[ -z "$CONSUL_ENCRYPT_KEY" ]]; then
        CONSUL_ENCRYPT_KEY=$(consul keygen)
    fi

    echo ""
    echo -e "${RED}=======================================================${NC}"
    echo -e "${RED}  CONSUL KEY (احفظه لاستخدامه على الكلاينت):${NC}"
    echo -e "${RED}  ${CONSUL_ENCRYPT_KEY}${NC}"
    echo -e "${RED}=======================================================${NC}"
    echo ""
    echo "$CONSUL_ENCRYPT_KEY" > /root/consul-key.txt

cat > /etc/consul.d/consul.hcl <<EOF
datacenter    = "dc1"
data_dir      = "/opt/consul"
node_name     = "${HOSTNAME}"
bind_addr     = "${MY_IP}"
client_addr   = "0.0.0.0"
encrypt       = "${CONSUL_ENCRYPT_KEY}"

server           = true
bootstrap_expect = 1

ui_config {
  enabled = true
}

log_level = "INFO"
EOF

else

cat > /etc/consul.d/consul.hcl <<EOF
datacenter    = "dc1"
data_dir      = "/opt/consul"
node_name     = "${HOSTNAME}"
bind_addr     = "${MY_IP}"
client_addr   = "0.0.0.0"
encrypt       = "${CONSUL_ENCRYPT_KEY}"

server     = false
retry_join = ["${NOMAD_SERVER_IP}"]

log_level = "INFO"
EOF

fi

print_success "Consul config ready"

#============================================================
# STEP 5: إعداد Nomad
#============================================================
print_step "5" "إعداد Nomad"

mkdir -p /etc/nomad.d /opt/nomad

if [[ "$NODE_ROLE" == "server" ]]; then

cat > /etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
data_dir   = "/opt/nomad"
bind_addr  = "0.0.0.0"

advertise {
  http = "${MY_IP}"
  rpc  = "${MY_IP}"
  serf = "${MY_IP}"
}

server {
  enabled          = true
  bootstrap_expect = 1
}

consul {
  address = "127.0.0.1:8500"
}
EOF

else

cat > /etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
data_dir   = "/opt/nomad"
bind_addr  = "0.0.0.0"

advertise {
  http = "${MY_IP}"
  rpc  = "${MY_IP}"
  serf = "${MY_IP}"
}

client {
  enabled = true
  servers = ["${NOMAD_SERVER_IP}:4647"]
}

plugin "docker" {
  config {
    allow_privileged = false
    volumes {
      enabled = true
    }
  }
}

consul {
  address = "127.0.0.1:8500"
}
EOF

fi

print_success "Nomad config ready"

#============================================================
# STEP 6: تشغيل الخدمات
#============================================================
print_step "6" "تشغيل الخدمات"

systemctl enable consul nomad
systemctl start consul
sleep 3
systemctl start nomad
sleep 2

print_success "Consul: $(systemctl is-active consul)"
print_success "Nomad:  $(systemctl is-active nomad)"

#============================================================
# STEP 7: التحقق
#============================================================
print_step "7" "التحقق النهائي"

echo -e "${CYAN}Docker:${NC}  $(docker --version)"
echo -e "${CYAN}Nomad:${NC}   $(nomad version | head -1)"
echo -e "${CYAN}Consul:${NC}  $(consul version | head -1)"
echo ""

if [[ "$NODE_ROLE" == "server" ]]; then
    echo -e "${CYAN}Consul Members:${NC}"
    consul members 2>/dev/null || true
    echo ""
    echo -e "${CYAN}Nomad Server Members:${NC}"
    nomad server members 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  تم بنجاح! - ${NODE_ROLE^^} - ${HOSTNAME}${NC}"
echo -e "${GREEN}=======================================================${NC}"

if [[ "$NODE_ROLE" == "server" ]]; then
echo ""
echo -e "${YELLOW}  Consul UI:  http://${MY_IP}:8500${NC}"
echo -e "${YELLOW}  Nomad  UI:  http://${MY_IP}:4646${NC}"
echo ""
echo -e "${YELLOW}  لإضافة Client جديد:${NC}"
echo -e "${YELLOW}  sudo bash setup-cluster.sh client ${MY_IP} ${CONSUL_ENCRYPT_KEY}${NC}"
fi
echo ""