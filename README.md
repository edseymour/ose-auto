# OpenShift Automation
A set of scripts to simplify deploying OpenShift to one or more remote hosts. 

## Usage
Scripts require a configuration file, the default config is `$(pwd)/.config/ose-auto.config`
`$ <script> -h`

### subscribe-instances.sh
Use this script to register all hosts with RHN, attach a pool and configure the OSE channels

### distribute-keys.sh
Use this script to create ssh keys and distribute between all hosts in cluster

### ose-prereq.sh
Use this script to install OSE prerequisites, requires an additional parameter `--dev=<dev name>` to specify the target device for docker storage. Warning, all contents on this device will be removed. 

### post-install.sh
Use this script to create a registry and router

### pre-load.sh
Use this script to pre-pull all Red Hat openshift images (all tags other than :latest and builds, e.g. 6.4-123). Warning: requires at least 15GB storage. 

## Experimental
The scripts in the are a work in progress and likely to mess things up. There are also better solutions available for doing this kind of thing...

### desktopize.sh
Use this script to turn a specific target (`--target=<host>`) into a desktop, running a VNC server and with a `demo` user pre-configured. 

### reconfig-host.sh
Use this script when the public IP address of the master has changed, requires two additional parameters
```
--old_host=<fqdn>    the fully qualified domain name of the old host
--new_host=<fqdn>    the fully qualified domain name of the new host
```
