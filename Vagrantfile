# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

host = RbConfig::CONFIG['host_os']

no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || '127.0.0.1,localhost'
(1..254).each do |i|
  no_proxy += ",10.0.2.#{i}"
end
debug = ENV['DEBUG']
functional_test_enabled = ENV['FUNCTIONAL_TEST_ENABLED']
chip_ci_script = ENV['CHIP_CI_SCRIPT']
chip_build_image = ENV['CHIP_BUILD_IMAGE']

case host
when /darwin/
  mem = `sysctl -n hw.memsize`.to_i / 1024
when /linux/
  mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i
when /mswin|mingw|cygwin/
  mem = `wmic computersystem Get TotalPhysicalMemory`.split[1].to_i / 1024
end

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = 'generic/ubuntu2004'
  config.vm.box_check_update = false
  config.vm.synced_folder './scripts', '/vagrant', SharedFoldersEnableSymlinksCreate: false
  config.vm.synced_folder './opt', '/opt', create: true
  config.vm.disk :disk, name: "src", size: "15GB"
  config.vm.disk :disk, name: "img", size: "7GB"
  {
    "sdb" => "/opt/",
    "sdc" => "/var/lib/docker/",
  }.each do |device, mount_path|
    config.vm.provision "shell" do |s|
      s.path   = "pre-install.sh"
      s.args   = [device, mount_path]
    end
  end

  config.vm.provision 'shell', privileged: false do |sh|
    sh.env = {
      'DEBUG': debug.to_s,
      'FUNCTIONAL_TEST_ENABLED': functional_test_enabled.to_s,
      'CHIP_CI_SCRIPT': chip_ci_script.to_s,
      'CHIP_BUILD_IMAGE': chip_build_image.to_s
    }
    sh.inline = <<-SHELL
      set -o errexit

      echo "export CHIP_DEV_MODE=true" | sudo tee --append /etc/environment

      cd /vagrant/
      curl -fsSL http://bit.ly/install_pkg | PKG=docker bash
      ./check.sh | tee ~/check.log
    SHELL
  end

  %i[virtualbox libvirt].each do |provider|
    config.vm.provider provider do |p|
      p.cpus = ENV['CPUS'] || 3
      p.memory = ENV['MEMORY'] || mem / 1024 / 4
    end
  end

  config.vm.provider :virtualbox do |v|
    v.gui = false
  end

  config.vm.provider :libvirt do |v, override|
    override.vm.synced_folder './scripts', '/vagrant', type: 'nfs', SharedFoldersEnableSymlinksCreate: false
    override.vm.synced_folder './opt', '/opt', type: 'nfs', create: true
    v.disk_device = "sda"
    v.disk_bus = "sata"
    v.storage :file, bus: "sata", device: "sdb", size: "15G"
    v.storage :file, bus: "sata", device: "sdc", size: "7G"
    v.random_hostname = true
    v.management_network_address = '10.0.2.0/24'
    v.management_network_name = 'administration'
    v.cpu_mode = 'host-passthrough'
  end

  if !ENV['http_proxy'].nil? && !ENV['https_proxy'].nil? && Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.http = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ''
    config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ''
    config.proxy.no_proxy = no_proxy
    config.proxy.enabled = { docker: false }
  end
end
