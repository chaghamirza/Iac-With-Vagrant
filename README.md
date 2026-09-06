# Vagrant VMware Cluster Provisioner

This project provides an automated, dynamic infrastructure provisioning solution using **Vagrant**, **VMware Workstation**, and a centralized YAML configuration file. It is specifically designed for **Linux** environments to quickly deploy, configure, and manage multi-node test labs or clusters.

---

## Prerequisites

Before running the project, make sure the following requirements are met:

1. **Operating System**: A compatible Linux distribution (Ubuntu, Debian, Fedora, CentOS, RHEL, etc.).
2. **VMware Workstation**: VMware Workstation must be installed and fully operational on your host machine.
3. **Bypass Sanctions / Network Proxy**: Because HashiCorp restricts access from certain regions due to international sanctions, you **must** use an active VPN, proxy, or sanction-bypass tool on your host system before executing installation or download commands.

---

## Project Structure

* `setup.sh`: Automated installation script for Vagrant, the VMware utility service, and the required Vagrant VMware desktop plugin.
* `config.yml`: Centralized YAML configuration file where nodes, hardware resources, network modes, and disk controllers are defined.
* `Vagrantfile`: Ruby provisioning script that reads `config.yml` dynamically and builds the virtual machines via the VMware provider.

---

## Installation & Setup Guide

### Step 1: Clone and Run the Setup Script

Open your terminal inside the project directory and execute the setup script with root privileges. This script automatically configures the official HashiCorp repositories, installs Vagrant and the VMware utility, starts the background service, and installs the VMware desktop plugin:

```bash
sudo ./setup.sh

```

### Step 2: Configure Your Infrastructure (`config.yml`)

After the setup is complete, open and edit the `config.yml` file to define your virtual machines, resources, and networking parameters:

```yaml
nodes:
  master:
    ip: "192.168.1.100"
    cpu: 2
    mem: 2048
    disk_size: "60GB"
    disk_controller: "scsi"
    network_type: "public_network"
    ip_mode: "static"

```

* **Hostname**: The key name under the `nodes` section (e.g., `master`, `worker1`) acts as the hostname for each virtual machine.

### Step 3: Start the Virtual Machines

Once your configuration is saved, bring up the cluster using Vagrant:

```bash
vagrant up

```

---

## Detailed Configuration Reference (`config.yml`)

### 1. Naming Convention

* The **first key name** defined under each node block in `config.yml` (e.g., `master`, `worker1`, `worker2`) is automatically assigned as the **hostname** and identifier for that virtual machine.



### 2. Networking and IP Assignment Logic

The project supports three core network types with flexible assignment modes:

* **Network Types (`network_type`)**:
* `nat`: Creates a NAT network. Vagrant handles this automatically using the default primary adapter.
* `private_network`: Creates a host-only private network.
* `public_network`: Creates a bridged network (`bridge`) connected directly to your physical network interface.


* **IP Modes (`ip_mode`)**:
* `static`: Uses a fixed IP address.
* `dhcp`: Dynamically assigns an IP address.


* **Priority & Fallback Rules**:
* If both an IP address and `dhcp` mode are specified, **DHCP takes priority**.
* If `ip_mode` is set to `static`, but the `ip` field is left empty or omitted, the system automatically falls back to **DHCP**.
* If the network type is set to `private_network` and the IP field is left blank, a NAT interface is created instead.



### 3. Disk Controllers (`disk_controller`)

You can define the storage controller for each node explicitly in `config.yml`:

* `scsi`: Configures an LSI Logic SCSI controller via VMX injection (`scsi0.present` and `scsi0.virtualDev`).
* `sata`: Configures a SATA controller (`sata0.present`).

---

## Important Technical Limitations (VMware Provider)

* **No Native LAN Segments**: The VMware provider for Vagrant does not support creating native VMware LAN segments directly through configuration scripts.
* **Undeletable Management Networks**: The default Vagrant management network interfaces created by the VMware provider cannot be automatically deleted.
* **Default Credentials & Access**:
* **Username**: `vagrant`
* **Password**: `vagrant`
* **SSH Port**: `22`
* *Note: If you plan to manage or provision these machines using Ansible or remote scripts, use these default credentials and port.*



---

## Teardown and Cleanup

To properly tear down and delete the virtual machines, execute the following commands in order:

1. **Destroy the VMs via Vagrant**:
```bash
vagrant destroy -f

```


2. **Remove the Local Vagrant Metadata Folder**:
```bash
rm -rf .vagrant

```



---

## Troubleshooting: Service Errors

If you encounter unexpected errors, permission issues, or provider communication failures while running commands like `vagrant up` or `vagrant destroy`, restart the background VMware utility service using the following command:

```bash
sudo systemctl restart vagrant-vmware-utility

```