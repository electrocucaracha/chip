# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

$no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || "127.0.0.1,localhost"
(1..254).each do |i|
  $no_proxy += ",10.0.2.#{i}"
end
$debug = ENV['DEBUG'] || "true"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu2004"
  config.vm.box_check_update = false
  config.vm.synced_folder './scripts', '/vagrant', SharedFoldersEnableSymlinksCreate: false
  config.vm.synced_folder './opt', '/opt', create: true

  config.vm.provision 'shell', privileged: false do |sh|
    sh.env = {
      'DEBUG': "#{$debug}",
    }
    sh.inline = <<-SHELL
      set -o errexit

      cd /vagrant/
      curl -fsSL http://bit.ly/install_pkg | PKG=docker bash
      ./build.sh | tee ~/build.log
    SHELL
  end

  host = RbConfig::CONFIG['host_os']

  if host =~ /darwin/
    mem = `sysctl -n hw.memsize`.to_i / 1024
  elsif host =~ /linux/
    mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i
  elsif host =~ /mswin|mingw|cygwin/
    mem = `wmic computersystem Get TotalPhysicalMemory`.split[1].to_i / 1024
  end
  [:virtualbox, :libvirt].each do |provider|
  config.vm.provider provider do |p|
      p.cpus = ENV["CPUS"] || 2
      p.memory = ENV['MEMORY'] || mem / 1024 / 4
    end
  end

  config.vm.provider "virtualbox" do |v|
    v.gui = false
  end

  config.vm.provider :libvirt do |v, override|
    override.vm.synced_folder "./scripts", "/vagrant", type: 'nfs', SharedFoldersEnableSymlinksCreate: false
    override.vm.synced_folder "./opt", "/opt", type: 'nfs', create: true
    v.random_hostname = true
    v.management_network_address = "10.0.2.0/24"
    v.management_network_name = "administration"
    v.cpu_mode = 'host-passthrough'
  end

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil
    if Vagrant.has_plugin?('vagrant-proxyconf')
      config.proxy.http     = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ""
      config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ""
      config.proxy.no_proxy = $no_proxy
      config.proxy.enabled = { docker: false }
    end
  end
end
