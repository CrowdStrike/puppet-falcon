# Vagrant for puppet-falcon

Vagrant enables users to create and configure lightweight, reproducible, and portable development
environments. This directory allows us to spin up a dev Windows 10 machine to test our current
module.

## Installation

Use your OS's package manager to install (Vagrant, VirtualBox, and RDP). The following examples
are based on Mac OSX. *NOTE: If you can't install VirtualBox, then install VMware Fusion.

VirtualBox Setup:
```bash
brew install vagrant
brew install --cask virtualbox
brew install --cask microsoft-remote-desktop
```

VMware Fusion Setup:
```bash
brew install vagrant
brew install --cask vmware-fusion
brew install --cask microsoft-remote-desktop
vagrant plugin install vagrant-vmware-desktop
```

Tool Refs:
* [Vagrant](https://www.vagrantup.com/docs)

> **NOTE** that I'm using Virtualbox because I found it to be the quickest method for me to easily use
> vagrant. I tried with the parallels plugin, but found it very spotty. I have NOT tested this with
> VMware Fusion, however I do believe it will work, with some minor tweaks.

The heart of this test environment is handled by the [Vagrantfile](./Vagrantfile).

## Usage

All subsequent commands should be ran from the this directory.

```bash
vagrant up
```
> **NOTE** The first time this is ran, it might awhile to download the image and start up

RDP into the test instance
> Default username/pw are set to 'vagrant'
```bash
vagrant rdp
```

## Useful Commands

```bash
# If you have multiple virtualization providers installed, you may have to specify
# virtualbox when bringing your boxes up
vagrant up --provider=virtualbox

# To destroy your environment
vagrant destroy -f

# To re-provision any provisioners
vagrant provision

# To rebuild/restart a box (aka - something got hosed)
vagrant destroy -f
vagrant up
```
