<div align="center">

# 🚀 Nomad & Consul Cluster Setup

<p>
  <img src="https://img.shields.io/badge/Nomad-1.9.7-00CA8E?style=for-the-badge&logo=nomad&logoColor=white" />
  <img src="https://img.shields.io/badge/Consul-1.22.5-F24C53?style=for-the-badge&logo=consul&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-Required-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" />
</p>

**Automated setup script for deploying a production-ready Nomad & Consul cluster with Docker support**

**سكربت آلي لنشر كلاستر Nomad & Consul جاهز للإنتاج مع دعم Docker**

<br/>

[English](#-english) · [العربية](#-العربية)

---

</div>

<br/>

# 🇬🇧 English

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start (Automated Script)](#-quick-start-automated-script)
- [Manual Installation (Recommended for Restricted Networks)](#-manual-installation-recommended-for-restricted-networks)
- [Verification](#-verification)
- [Web UIs](#-web-uis)
- [Troubleshooting](#-troubleshooting)
- [Useful Commands](#-useful-commands)

---

## 🔍 Overview

This project provides a **single, production-ready Bash script** (`setup-cluster.sh`) that automates the entire process of deploying a **HashiCorp Nomad & Consul** cluster on Ubuntu 24.04 servers.

### What the script does:

| Step | Description |
|:----:|-------------|
| 1️⃣ | Installs **Docker** and required utilities |
| 2️⃣ | Downloads & installs **Nomad** (v1.9.7) and **Consul** (v1.22.5) |
| 3️⃣ | Creates **systemd services** for automatic startup |
| 4️⃣ | Generates **Consul encryption key** (on server) and configures Consul |
| 5️⃣ | Configures **Nomad** as server or client based on the role |
| 6️⃣ | Starts all services and enables auto-start on boot |
| 7️⃣ | Runs **verification checks** to confirm everything is working |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│               NOMAD & CONSUL CLUSTER            │
├─────────────────────────────────────────────────┤
│                                                 │
│   ┌─────────────┐         ┌─────────────┐      │
│   │   SERVER     │         │   CLIENT    │      │
│   │ ───────────  │         │ ──────────  │      │
│   │ Nomad Server │◄───────►│ Nomad Client│      │
│   │ Consul Server│◄───────►│ Consul Agent│      │
│   │ Docker       │         │ Docker      │      │
│   └──────┬───────┘         └──────┬──────┘      │
│          │                        │              │
│          │    ┌─────────────┐     │              │
│          └───►│   CLIENT    │◄────┘              │
│               │ ──────────  │                    │
│               │ Nomad Client│                    │
│               │ Consul Agent│                    │
│               │ Docker      │                    │
│               └─────────────┘                    │
│                                                  │
│   🌐 Consul UI: http://<SERVER_IP>:8500          │
│   🌐 Nomad  UI: http://<SERVER_IP>:4646          │
└─────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

- **Operating System:** Ubuntu 24.04 LTS
- **Permissions:** Root / sudo access
- **Network:** Servers must be able to communicate with each other
- **Minimum Specs:** 2 CPU cores, 2 GB RAM per node (recommended)

### Required Ports

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| `4646` | TCP | Nomad HTTP | Web UI & API |
| `4647` | TCP | Nomad RPC | Internal communication |
| `4648` | TCP/UDP | Nomad Serf | Cluster gossip |
| `8300` | TCP | Consul Server | Server RPC |
| `8301` | TCP/UDP | Consul Serf LAN | LAN gossip |
| `8500` | TCP | Consul HTTP | Web UI & API |
| `8600` | TCP/UDP | Consul DNS | DNS interface |

---

## ⚡ Quick Start (Automated Script)

### Step 1 — Setup the Server Node

```bash
# Download the script to your server
wget https://raw.githubusercontent.com/<YOUR_USERNAME>/nomad/main/setup-cluster.sh

# Make it executable
chmod +x setup-cluster.sh

# Run on the SERVER node
sudo bash setup-cluster.sh server <YOUR_SERVER_IP>
```

**Example:**

```bash
sudo bash setup-cluster.sh server 192.168.1.10
```

> [!IMPORTANT]
> After the server setup completes, the script will output a **Consul Encryption Key**.
> **Save this key!** You will need it to join client nodes to the cluster.

The output will look like:
```
=======================================================
  CONSUL KEY (Save it for client use):
  RBgDvT73wRJQ8PbgG...  ← Save this key
=======================================================
```

### Step 2 — Setup Client Nodes

```bash
# Run on each CLIENT node
sudo bash setup-cluster.sh client <SERVER_IP> <CONSUL_KEY>
```

**Example:**

```bash
sudo bash setup-cluster.sh client 192.168.1.10 RBgDvT73wRJQ8PbgG...
```

> [!TIP]
> You can add as many client nodes as you need by repeating this command on each machine.

---

## 🔧 Manual Installation (Recommended for Restricted Networks)

> [!WARNING]
> If the automated script fails to download Nomad or Consul (due to network restrictions, firewalls, or blocked access to HashiCorp servers), you can install them **manually** using the method below.

### Why Manual Installation?

Some servers have restricted internet access and cannot reach `releases.hashicorp.com`. In this case, you can:
1. **Download** the binaries on a machine that has internet (e.g., your Windows PC using a VPN)
2. **Transfer** the files to the servers manually via `scp` or any file transfer tool
3. **Run** the script — it will detect the files and skip downloading

### Step-by-Step Manual Process

#### 1. Download on Windows (with VPN if needed)

Download the following files in your browser:

| Tool | Download Link |
|------|---------------|
| **Nomad** | [nomad_1.9.7_linux_amd64.zip](https://releases.hashicorp.com/nomad/1.9.7/nomad_1.9.7_linux_amd64.zip) |
| **Consul** | [consul_1.22.5_linux_amd64.zip](https://releases.hashicorp.com/consul/1.22.5/consul_1.22.5_linux_amd64.zip) |

> [!NOTE]
> If the HashiCorp website is blocked in your region, enable a **VPN** before downloading.

#### 2. Transfer to Server via SCP

```bash
# From your local machine (Git Bash, PowerShell, or Terminal)
scp nomad_1.9.7_linux_amd64.zip  user@<SERVER_IP>:~/nomad.zip
scp consul_1.22.5_linux_amd64.zip user@<SERVER_IP>:~/consul.zip
```

**PowerShell example:**
```powershell
scp C:\Users\YourUser\Downloads\nomad_1.9.7_linux_amd64.zip  user@192.168.1.10:~/nomad.zip
scp C:\Users\YourUser\Downloads\consul_1.22.5_linux_amd64.zip user@192.168.1.10:~/consul.zip
```

> [!IMPORTANT]
> The files **must** be placed in the home directory (`~/`) and named exactly:
> - `~/nomad.zip`
> - `~/consul.zip`
>
> The script checks for these files before attempting to download.

#### 3. Run the Script

After transferring the files, run the script normally:

```bash
# Server node
sudo bash setup-cluster.sh server <YOUR_SERVER_IP>

# Client nodes
sudo bash setup-cluster.sh client <SERVER_IP> <CONSUL_KEY>
```

The script will **automatically detect** `~/nomad.zip` and `~/consul.zip` and use them instead of downloading.

#### 4. Alternative: Fully Manual Installation (Without the Script)

If you prefer to install everything manually without the script:

```bash
# 1. Install Docker
sudo apt-get update -y
sudo apt-get install -y docker.io unzip
sudo systemctl enable docker && sudo systemctl start docker

# 2. Install Nomad
cd /tmp
sudo cp ~/nomad.zip /tmp/nomad.zip    # if you already transferred it
sudo unzip -o nomad.zip
sudo mv nomad /usr/local/bin/
sudo chmod +x /usr/local/bin/nomad
nomad version   # verify

# 3. Install Consul
sudo cp ~/consul.zip /tmp/consul.zip  # if you already transferred it
sudo unzip -o consul.zip
sudo mv consul /usr/local/bin/
sudo chmod +x /usr/local/bin/consul
consul version  # verify

# 4. Generate Consul encryption key (on server only)
consul keygen
# Save the output key for client configuration

# 5. Create directories
sudo mkdir -p /etc/consul.d /opt/consul /etc/nomad.d /opt/nomad

# 6. Then configure Consul and Nomad manually
# See the script source for example configurations
```

---

## ✅ Verification

After setup, verify everything is running:

```bash
# Check service status
sudo systemctl status consul
sudo systemctl status nomad

# Check cluster members (on server)
consul members
nomad server members
nomad node status

# Check versions
docker --version
nomad version
consul version
```

**Expected output for a healthy cluster:**

```
$ consul members
Node        Address             Status  Type    Build   Protocol  DC
server-01   192.168.1.10:8301   alive   server  1.22.5  2         dc1
client-01   192.168.1.11:8301   alive   client  1.22.5  2         dc1
client-02   192.168.1.12:8301   alive   client  1.22.5  2         dc1
```

---

## 🌐 Web UIs

Once the server is set up, you can access the management dashboards:

| Service | URL | Description |
|---------|-----|-------------|
| **Consul** | `http://<SERVER_IP>:8500` | Service discovery, health checks, KV store |
| **Nomad** | `http://<SERVER_IP>:4646` | Job management, cluster monitoring |

---

## 🛠️ Troubleshooting

<details>
<summary><b>❌ Download failed — cannot reach releases.hashicorp.com</b></summary>

**Solution:** Use the [Manual Installation](#-manual-installation-recommended-for-restricted-networks) method. Download the files on a machine with internet access (use VPN if needed), then transfer via `scp`.

</details>

<details>
<summary><b>❌ Consul/Nomad service won't start</b></summary>

```bash
# Check logs for errors
sudo journalctl -u consul -f
sudo journalctl -u nomad -f

# Common fix: ensure bind address is correct
hostname -I   # verify your IP
```

</details>

<details>
<summary><b>❌ Client can't join the cluster</b></summary>

1. Verify the **Consul encryption key** matches the server
2. Ensure required **ports** are open between server and client
3. Check that the **server IP** is reachable from the client:
   ```bash
   ping <SERVER_IP>
   telnet <SERVER_IP> 8301
   ```

</details>

<details>
<summary><b>❌ Docker permission denied</b></summary>

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Then logout and login again, or run:
newgrp docker
```

</details>

---

## 📌 Useful Commands

```bash
# ─── Service Management ───
sudo systemctl restart consul nomad
sudo systemctl stop consul nomad
sudo systemctl status consul nomad

# ─── Logs ───
sudo journalctl -u consul -f --no-pager
sudo journalctl -u nomad -f --no-pager

# ─── Consul ───
consul members              # List cluster members
consul catalog services     # List registered services
consul kv get <key>         # Get value from KV store

# ─── Nomad ───
nomad server members        # List server members
nomad node status           # List client nodes
nomad job status            # List running jobs
nomad job run <file.nomad>  # Deploy a job
```

---

<br/>
<br/>

---

<div align="center">

# 🇸🇦 العربية

</div>

## 📋 جدول المحتويات

- [نظرة عامة](#-نظرة-عامة)
- [هيكل الكلاستر](#-هيكل-الكلاستر)
- [المتطلبات](#-المتطلبات)
- [البدء السريع (السكربت الآلي)](#-البدء-السريع-السكربت-الآلي)
- [التثبيت اليدوي (للشبكات المقيدة)](#-التثبيت-اليدوي-للشبكات-المقيدة)
- [التحقق من التشغيل](#-التحقق-من-التشغيل)
- [واجهات الويب](#-واجهات-الويب)
- [حل المشاكل](#-حل-المشاكل)
- [أوامر مفيدة](#-أوامر-مفيدة)

---

## 🔍 نظرة عامة

يوفر هذا المشروع **سكربت Bash واحد** (`setup-cluster.sh`) يقوم بأتمتة عملية نشر كلاستر **HashiCorp Nomad & Consul** بالكامل على سيرفرات Ubuntu 24.04.

### ماذا يفعل السكربت؟

| الخطوة | الوصف |
|:------:|-------|
| 1️⃣ | تثبيت **Docker** والأدوات المطلوبة |
| 2️⃣ | تحميل وتثبيت **Nomad** (v1.9.7) و **Consul** (v1.22.5) |
| 3️⃣ | إنشاء خدمات **systemd** للتشغيل التلقائي |
| 4️⃣ | توليد **مفتاح تشفير Consul** (على السيرفر) وإعداد Consul |
| 5️⃣ | إعداد **Nomad** كسيرفر أو كلاينت حسب الدور |
| 6️⃣ | تشغيل جميع الخدمات وتفعيل التشغيل التلقائي عند الإقلاع |
| 7️⃣ | تنفيذ **فحوصات التحقق** للتأكد أن كل شيء يعمل |

---

## 🏗️ هيكل الكلاستر

```
┌───────────────────────────────────────────────────┐
│              كلاستر NOMAD & CONSUL                │
├───────────────────────────────────────────────────┤
│                                                   │
│   ┌──────────────┐         ┌──────────────┐       │
│   │   السيرفر     │         │   كلاينت 1   │       │
│   │ ────────────  │         │ ────────────  │       │
│   │ Nomad Server │◄───────►│ Nomad Client │       │
│   │ Consul Server│◄───────►│ Consul Agent │       │
│   │ Docker       │         │ Docker       │       │
│   └──────┬───────┘         └──────┬───────┘       │
│          │                        │               │
│          │    ┌──────────────┐    │               │
│          └───►│   كلاينت 2   │◄───┘               │
│               │ ────────────  │                    │
│               │ Nomad Client │                    │
│               │ Consul Agent │                    │
│               │ Docker       │                    │
│               └──────────────┘                    │
│                                                   │
│   🌐 واجهة Consul: http://<SERVER_IP>:8500        │
│   🌐 واجهة Nomad:  http://<SERVER_IP>:4646        │
└───────────────────────────────────────────────────┘
```

---

## 📦 المتطلبات

- **نظام التشغيل:** Ubuntu 24.04 LTS
- **الصلاحيات:** وصول root / sudo
- **الشبكة:** يجب أن تكون السيرفرات قادرة على التواصل مع بعضها
- **الحد الأدنى:** 2 أنوية CPU، 2 جيجا رام لكل نود (موصى به)

### المنافذ المطلوبة

| المنفذ | البروتوكول | الخدمة | الوصف |
|--------|-----------|--------|-------|
| `4646` | TCP | Nomad HTTP | واجهة الويب و API |
| `4647` | TCP | Nomad RPC | الاتصال الداخلي |
| `4648` | TCP/UDP | Nomad Serf | بروتوكول الـ gossip |
| `8300` | TCP | Consul Server | اتصال RPC |
| `8301` | TCP/UDP | Consul Serf LAN | بروتوكول gossip المحلي |
| `8500` | TCP | Consul HTTP | واجهة الويب و API |
| `8600` | TCP/UDP | Consul DNS | واجهة DNS |

---

## ⚡ البدء السريع (السكربت الآلي)

### الخطوة 1 — إعداد نود السيرفر

```bash
# حمّل السكربت على السيرفر
wget https://raw.githubusercontent.com/<YOUR_USERNAME>/nomad/main/setup-cluster.sh

# اعطه صلاحية التنفيذ
chmod +x setup-cluster.sh

# شغّله على نود السيرفر
sudo bash setup-cluster.sh server <عنوان_IP_السيرفر>
```

**مثال:**

```bash
sudo bash setup-cluster.sh server 192.168.1.10
```

> [!IMPORTANT]
> بعد اكتمال إعداد السيرفر، سيظهر **مفتاح تشفير Consul** في نهاية السكربت.
> **احفظ هذا المفتاح!** ستحتاجه لإضافة نودات الكلاينت إلى الكلاستر.

سيكون الخرج كالتالي:
```
=======================================================
  CONSUL KEY (احفظه لاستخدامه على الكلاينت):
  RBgDvT73wRJQ8PbgG...  ← احفظ هذا المفتاح
=======================================================
```

### الخطوة 2 — إعداد نودات الكلاينت

```bash
# شغّل على كل نود كلاينت
sudo bash setup-cluster.sh client <عنوان_IP_السيرفر> <مفتاح_CONSUL>
```

**مثال:**

```bash
sudo bash setup-cluster.sh client 192.168.1.10 RBgDvT73wRJQ8PbgG...
```

> [!TIP]
> يمكنك إضافة أي عدد من نودات الكلاينت بتكرار هذا الأمر على كل جهاز.

---

## 🔧 التثبيت اليدوي (للشبكات المقيدة)

> [!WARNING]
> إذا فشل السكربت في تحميل Nomad أو Consul (بسبب قيود الشبكة أو حظر الوصول لسيرفرات HashiCorp)، يمكنك التثبيت **يدوياً** باتباع الطريقة التالية.

### لماذا التثبيت اليدوي؟

بعض السيرفرات لديها وصول محدود للإنترنت ولا تستطيع الوصول لـ `releases.hashicorp.com`. في هذه الحالة:
1. **حمّل** الملفات على جهاز لديه إنترنت (مثل جهازك الويندوز باستخدام VPN)
2. **انقل** الملفات إلى السيرفرات يدوياً عبر `scp` أو أي أداة نقل
3. **شغّل** السكربت — سيكتشف الملفات تلقائياً ويتخطى التحميل

### الخطوات بالتفصيل

#### 1. التحميل على ويندوز (مع VPN إذا لزم الأمر)

حمّل الملفات التالية من المتصفح:

| الأداة | رابط التحميل |
|--------|-------------|
| **Nomad** | [nomad_1.9.7_linux_amd64.zip](https://releases.hashicorp.com/nomad/1.9.7/nomad_1.9.7_linux_amd64.zip) |
| **Consul** | [consul_1.22.5_linux_amd64.zip](https://releases.hashicorp.com/consul/1.22.5/consul_1.22.5_linux_amd64.zip) |

> [!NOTE]
> إذا كان موقع HashiCorp محظوراً في منطقتك، فعّل **VPN** قبل التحميل.

#### 2. نقل الملفات إلى السيرفر عبر SCP

```bash
# من جهازك المحلي (Git Bash أو PowerShell أو Terminal)
scp nomad_1.9.7_linux_amd64.zip  user@<عنوان_IP_السيرفر>:~/nomad.zip
scp consul_1.22.5_linux_amd64.zip user@<عنوان_IP_السيرفر>:~/consul.zip
```

**مثال من PowerShell:**
```powershell
scp C:\Users\YourUser\Downloads\nomad_1.9.7_linux_amd64.zip  user@192.168.1.10:~/nomad.zip
scp C:\Users\YourUser\Downloads\consul_1.22.5_linux_amd64.zip user@192.168.1.10:~/consul.zip
```

> [!IMPORTANT]
> يجب وضع الملفات في المجلد الرئيسي (`~/`) وتسميتها بالضبط:
> - `~/nomad.zip`
> - `~/consul.zip`
>
> السكربت يتحقق من وجود هذه الملفات قبل محاولة التحميل.

#### 3. تشغيل السكربت

بعد نقل الملفات، شغّل السكربت بشكل طبيعي:

```bash
# نود السيرفر
sudo bash setup-cluster.sh server <عنوان_IP_السيرفر>

# نودات الكلاينت
sudo bash setup-cluster.sh client <عنوان_IP_السيرفر> <مفتاح_CONSUL>
```

السكربت **سيكتشف تلقائياً** ملفات `~/nomad.zip` و `~/consul.zip` ويستخدمها بدلاً من التحميل.

#### 4. بديل: التثبيت اليدوي الكامل (بدون السكربت)

إذا كنت تفضل التثبيت اليدوي الكامل بدون السكربت:

```bash
# 1. تثبيت Docker
sudo apt-get update -y
sudo apt-get install -y docker.io unzip
sudo systemctl enable docker && sudo systemctl start docker

# 2. تثبيت Nomad
cd /tmp
sudo cp ~/nomad.zip /tmp/nomad.zip    # إذا نقلت الملف مسبقاً
sudo unzip -o nomad.zip
sudo mv nomad /usr/local/bin/
sudo chmod +x /usr/local/bin/nomad
nomad version   # تحقق

# 3. تثبيت Consul
sudo cp ~/consul.zip /tmp/consul.zip  # إذا نقلت الملف مسبقاً
sudo unzip -o consul.zip
sudo mv consul /usr/local/bin/
sudo chmod +x /usr/local/bin/consul
consul version  # تحقق

# 4. توليد مفتاح تشفير Consul (على السيرفر فقط)
consul keygen
# احفظ المفتاح الناتج لإعداد الكلاينت

# 5. إنشاء المجلدات
sudo mkdir -p /etc/consul.d /opt/consul /etc/nomad.d /opt/nomad

# 6. إعداد Consul و Nomad يدوياً
# راجع ملف السكربت للاطلاع على أمثلة الإعدادات
```

---

## ✅ التحقق من التشغيل

بعد الإعداد، تحقق أن كل شيء يعمل:

```bash
# التحقق من حالة الخدمات
sudo systemctl status consul
sudo systemctl status nomad

# التحقق من أعضاء الكلاستر (على السيرفر)
consul members
nomad server members
nomad node status

# التحقق من الإصدارات
docker --version
nomad version
consul version
```

**الخرج المتوقع لكلاستر سليم:**

```
$ consul members
Node        Address             Status  Type    Build   Protocol  DC
server-01   192.168.1.10:8301   alive   server  1.22.5  2         dc1
client-01   192.168.1.11:8301   alive   client  1.22.5  2         dc1
client-02   192.168.1.12:8301   alive   client  1.22.5  2         dc1
```

---

## 🌐 واجهات الويب

بعد إعداد السيرفر، يمكنك الوصول للوحات التحكم:

| الخدمة | الرابط | الوصف |
|--------|--------|-------|
| **Consul** | `http://<عنوان_IP_السيرفر>:8500` | اكتشاف الخدمات، فحوصات الصحة، مخزن KV |
| **Nomad** | `http://<عنوان_IP_السيرفر>:4646` | إدارة المهام، مراقبة الكلاستر |

---

## 🛠️ حل المشاكل

<details>
<summary><b>❌ فشل التحميل — لا يمكن الوصول لـ releases.hashicorp.com</b></summary>

**الحل:** استخدم طريقة [التثبيت اليدوي](#-التثبيت-اليدوي-للشبكات-المقيدة). حمّل الملفات على جهاز لديه إنترنت (استخدم VPN إذا لزم الأمر)، ثم انقلها عبر `scp`.

</details>

<details>
<summary><b>❌ خدمة Consul أو Nomad لا تعمل</b></summary>

```bash
# تحقق من السجلات لمعرفة الأخطاء
sudo journalctl -u consul -f
sudo journalctl -u nomad -f

# حل شائع: تأكد أن عنوان الربط صحيح
hostname -I   # تحقق من عنوان IP
```

</details>

<details>
<summary><b>❌ الكلاينت لا يستطيع الانضمام للكلاستر</b></summary>

1. تأكد أن **مفتاح تشفير Consul** مطابق للسيرفر
2. تأكد أن **المنافذ المطلوبة** مفتوحة بين السيرفر والكلاينت
3. تأكد أن **عنوان IP السيرفر** يمكن الوصول إليه من الكلاينت:
   ```bash
   ping <عنوان_IP_السيرفر>
   telnet <عنوان_IP_السيرفر> 8301
   ```

</details>

<details>
<summary><b>❌ رفض صلاحية Docker</b></summary>

```bash
# أضف المستخدم لمجموعة docker
sudo usermod -aG docker $USER
# ثم سجّل خروج ودخول مرة أخرى، أو شغّل:
newgrp docker
```

</details>

---

## 📌 أوامر مفيدة

```bash
# ─── إدارة الخدمات ───
sudo systemctl restart consul nomad
sudo systemctl stop consul nomad
sudo systemctl status consul nomad

# ─── السجلات ───
sudo journalctl -u consul -f --no-pager
sudo journalctl -u nomad -f --no-pager

# ─── Consul ───
consul members              # عرض أعضاء الكلاستر
consul catalog services     # عرض الخدمات المسجلة
consul kv get <key>         # جلب قيمة من مخزن KV

# ─── Nomad ───
nomad server members        # عرض أعضاء السيرفر
nomad node status           # عرض نودات الكلاينت
nomad job status            # عرض المهام الجارية
nomad job run <file.nomad>  # نشر مهمة
```

---

<div align="center">

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p>
  <sub>Built with ❤️ for the DevOps community</sub>
  <br/>
  <sub>صُنع بـ ❤️ لمجتمع DevOps</sub>
</p>

</div>
