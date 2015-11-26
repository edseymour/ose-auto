#!/bin/bash

config_file=.config/ose-auto.config

function parse_value {

  param=$1
  value=$2

  case $param in

      -c | --config)
         config_file=$value
         echo "using configuration: $value"
         ;;

      -t | --target)
         target=$value
         echo "using specific target: $target"
         ;;

      *)
         if [[ ! "$value" == "" ]] && [[ "$param" == "--"* ]] ; then
            eval "${param#-*-}=$value"
            echo "setting ${param#-*-}=$value"          
         else
            echo "unknown command $param"
            show_help
         fi
      ;;
      esac

}

function show_help {

echo "Usage: $0 [options]

 -c, --config <file>  path to configuration file
 -h, --help           this message
 -t, --target <fqdn>  fully qualified domain name for a specific target server
 --master <host>      hostname of an OpenShift master, can be short name if --domain is also specified
 --domain <zone>      common public domain name of hosts
 --hosts \"host1...\"   list of OpenShift hostnames, can be short names if --domain is also specified 

Default configuration file is $config_file

Configuration file format:
# --------------------------------
ident=<path to aws certificate>
rhnu=<rhn user id>
rhnp=<rhn password>
pool=<subscription pool id>
ssh_user=<user name, e.g. ec2-user>
domain=<EC2 domain>
master=\"<master>\"
hosts=\"<host1> <host2> ... <hostn>\"
# --------------------------------"
}

function validate_config
{
   param=$1
   eval value=\$$param
   [ "$value" == "" ] && echo "No value for $param provided, pass value --$param=<value> " && exit 1
}

function optional_config
{
   echo "Note: optional configuration option --$1 - $2"
}

function validate_config_rhn()
{
   [ "$rhnu" == "" ] && echo "No RHN user id provided" && show_help && exit 1
   [ "$rhnp" == "" ] && echo "No RHN password provided" && show_help && exit 1
   [ "$pool" == "" ] && echo "No RHN pool provided" && show_help && exit 1
} 

function validate_config_default()
{
   [ "$ssh_user" == "" ] && echo "No ssh user id provided" && show_help && exit 1
   [ "$domain" == "" ] && echo "Warning: no domain provided, expect hosts with FQDN" 
   [ "$hosts" == "" ] && echo "No hosts provided" && show_help && exit 1
}

function validate_config_master()
{
   [ "$master" == "" ] && echo "No master host provided" && show_help && exit 1
}

function scmd {
   ssh -i $ident -o IPQoS=throughput -tt -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=QUIET "$@"
}

function gen_fqdn {

   if [ "${domain}" == "" ]
      then
         fqdn=$1
   else
      fqdn="$1.$domain"
   fi

   echo $fqdn

}

for var in "$@"
do
    
   if [[ $var == -* ]]; then

      if [[ "$var" == *"="* ]]; then
         arr=$(echo $var | tr "=" "\n")
        
         parse_value ${arr[0]} ${arr[1]}    

      else
      
         case $var in

            -h | --help) show_help
            ;;
            *) last=$var
         esac
      fi

   else
      
      if [ "$last" == "" ] ; then
        echo "unknown command: $var"
        show_help
      else
        parse_value $last $var
      fi

      last=

   fi

done

[ ! -f $config_file ] && echo "No configuration found $config_file" && show_help && exit 1 

source "$config_file"

validate_config_default

echo "***********************************************************************
Starting process "$(date)"

"

