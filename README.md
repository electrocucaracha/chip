# Connected Home over IP
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Super-Linter](https://github.com/electrocucaracha/chip/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)

## Summary

Project [Connected Home over IP][1] is a new Working Group within the Zigbee
Alliance. This Working Group plans to develop and promote the adoption of a new
connectivity standard to increase compatibility among smart home products, with
security as a fundamental design tenet.

This project automates the [instructions][2] required for installing and
building the CHIP's source code.

## Setup

This project uses [Vagrant tool][3] for provisioning Virtual Machines
automatically. It's highly recommended to use the  `setup.sh` script
of the [bootstrap-vagrant project][4] for installing Vagrant
dependencies and plugins required for its project. The script
supports two Virtualization providers (Libvirt and VirtualBox).

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to deploy a dev environment
with the following instruction:

    vagrant up

[1]: https://www.connectedhomeip.com/
[2]: https://github.com/project-chip/connectedhomeip/blob/master/docs/BUILDING.md
[3]: https://www.vagrantup.com/
[4]: https://github.com/electrocucaracha/bootstrap-vagrant
