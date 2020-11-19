#!/bin/bash

set -e

if [ ! -e id_rsa_k2012 ]
then
  ssh-keygen -t rsa -f id_rsa_k2012 -q -N ""
fi

if [ "x" = "${VULTR_API_KEY}x" ]
then
  echo "Please set VULTR_API_KEY variable"
  exit 1
fi

terraform apply

MASTER_IP=$(terraform output server_ip)
echo "Server IP is $MASTER_IP"
echo "Create SSH config"

echo "Host k8smaster
  HostName $MASTER_IP
  User root
  IdentityFile `pwd`/id_rsa_k2012
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
" > ~/.ssh/config.d/k2012.conf