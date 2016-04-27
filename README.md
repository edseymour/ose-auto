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

### provision.sh
Provision a set of AWS instances and automatically tag with a common RunName value

### list-instances.sh
Export a CSV of AWS instances given a specific value for a RunName tag (see provision.sh)

## Workshop
Scripts to support creating workshop environments. The workshop environment comprises of three main services: 
 - OpenShift Enterprise - a single OpenShift cluster 
 - Desktops - a set of desktops, one per user per session
 - Gitlab - a gitlab-ce installation with python-gitlab installed to support automation

The design allows for multiple users to be assigned to each desktop, allowing for consecutive sessions to be run overtime and each user receiving their own 'fresh' environment. Each user receives their own dedicated gitlab-hosts source repository.
## configure-proxy 
To user 
./configure-proxy.sh  -c .config/ose-auto.config  --httpProxy=http://bla.com:8080 --httpsProxy=htpp://bla.com:8080 --noProxy=masters.com
Expects that a master is running. picks up the registry ip from the master 
replaces proxy config if there otherwise adds to the following files 
      - /etc/sysconfig/atomic-openshift-master "
      - /etc/sysconfig/atomic-openshift-master-api"
      - /etc/sysconfig/atomic-openshift-master-controllers"
      - /etc/sysconfig/docker"
      
 Warning. Does not do the sudo thing like the other scripts 

## Experimental
The scripts in the are a work in progress and likely to mess things up. There are also better solutions available for doing this kind of thing...

### desktopize.sh
Use this script to turn a specific target (`--target=<host>`) into a desktop, running a VNC server and with a `demo` user pre-configured. 

### install-eclipse.sh
Use this script to add JBoss Developer Studio to the desktop environment, you will need to provide a local path to the standalone installer. 

