# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# ==============================================================================
# Vagrantfile: Dynamic VMware Provisioner
# Description: Reads config.yml and provisions the infrastructure.
# ==============================================================================

# 1. Load and Validate Configuration File
CONFIG_FILE = File.join(__dir__, 'config.yml')

unless File.exist?(CONFIG_FILE)
  abort("ERROR: Configuration file 'config.yml' not found. Please create it first.")
end

cluster_config = YAML.load_file(CONFIG_FILE)

Vagrant.configure("2") do |config|
  # Base Box configuration
  config.vm.box = "bento/ubuntu-22.04"

  # 2. Iterate through nodes defined in YAML
  cluster_config['nodes'].each do |hostname, node_settings|
    
    config.vm.define hostname do |node|
      node.vm.hostname = hostname

      # --- [ Network Configuration Logic ] ---
      net_type = node_settings['network_type']
      ip_mode  = node_settings['ip_mode']
      ip_addr  = node_settings['ip']

      case net_type
      when "nat"
        # NAT is handled automatically by Vagrant's default first adapter.
        # No extra network block is needed.
      when "private_network"
        if ip_mode == "static" && !ip_addr.nil? && !ip_addr.empty?
          node.vm.network "private_network", ip: ip_addr
        else
          node.vm.network "private_network", type: "dhcp"
        end
      when "public_network"
        if ip_mode == "static" && !ip_addr.nil? && !ip_addr.empty?
          node.vm.network "public_network", ip: ip_addr
        else
          node.vm.network "public_network", type: "dhcp"
        end
      end

      # --- [ Disk Size Configuration ] ---
      disk_size = node_settings['disk_size']
      if !disk_size.nil? && !disk_size.empty?
        node.vm.disk :disk, size: disk_size, primary: true
      end

      # --- [ VMware Workstation Provider Settings ] ---
      node.vm.provider "vmware_desktop" do |v|
        v.linked_clone = false
        v.gui = false
        v.cpus = node_settings['cpu']
        v.memory = node_settings['mem']

        # --- [ Disk Controller Configuration (VMX Injection) ] ---
        # Fallback to 'scsi' if controller is not explicitly defined
        controller = (node_settings['disk_controller'] || "scsi").downcase

        case controller
        when "scsi"
          v.vmx["scsi0.present"] = "TRUE"
          v.vmx["scsi0.virtualDev"] = "lsilogic"
        when "sata"
          v.vmx["sata0.present"] = "TRUE"
        else
          puts "WARNING: Unknown disk controller '#{controller}' for #{hostname}. Defaulting to SCSI."
          v.vmx["scsi0.present"] = "TRUE"
          v.vmx["scsi0.virtualDev"] = "lsilogic"
        end
      end
      
    end
  end
end
