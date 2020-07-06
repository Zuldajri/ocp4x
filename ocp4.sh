#!/bin/bash

echo $(date) " - Starting Master Script"

ADMIN_USER=$1
AZURE_CLIENT_ID=$2
AZURE_TENANT_ID=$3
AZURE_SUBSCRIPTION_ID=$4
AZURE_CLIENT_SECRET=$5
DOMAIN_NAME=$6
RG_DOMAIN=$7
CLUSTER_NAME=$8
CLUSTER_ADMIN=$9
CLUSTER_ADMIN_PASSWORD=${10}
LOCATION=${11}
CONTROL_PLANE_REPLICA=${12}
CONTROL_PLANE_VM_SIZE=${13}
CONTROL_PLANE_OS_DISK=${14}
COMPUTE_REPLICA=${15}
COMPUTE_VM_SIZE=${16}
COMPUTE_OS_DISK=${17}
PULL_SECRET=${18}

ssh-keygen -t rsa -b 4096 -N '' -f /var/lib/waagent/custom-script/download/0/openshiftkey
eval "$(ssh-agent -s)"
ssh-add /var/lib/waagent/custom-script/download/0/openshiftkey

SSH_PUBLIC=$(cat /var/lib/waagent/custom-script/download/0/openshiftkey.pub)

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.10/openshift-client-linux-4.4.10.tar.gz
tar xvf openshift-client-linux-4.4.10.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.10/openshift-install-linux-4.4.10.tar.gz 
tar xvf openshift-install-linux-4.4.10.tar.gz

sudo mv oc kubectl openshift-install /usr/local/bin

sudo mkdir .azure
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/osServicePrincipal.json -O /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json

sudo sed -i "s/AZURE_SUBSCRIPTION_ID/$AZURE_SUBSCRIPTION_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_ID/$AZURE_CLIENT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_SECRET/$AZURE_CLIENT_SECRET/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_TENANT_ID/$AZURE_TENANT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json

sudo mkdir openshift

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/install-config.yaml -O /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

sudo sed -i "s/domian/$DOMAIN_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/clusterwill/$CLUSTER_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/RG-domain/$RG_DOMAIN/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/location/$LOCATION/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/pullSercet/$PULL_SECRET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CPREP/$CONTROL_PLANE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CPSIZE/$CONTROL_PLANE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CPOSD/$CONTROL_PLANE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CREP/$COMPUTE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CSIZE/$COMPUTE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COSD/$COMPUTE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

echo sshKey: $SSH_PUBLIC >> /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

openshift-install create cluster --dir=openshift --log-level=info

export KUBECONFIG=./openshift/auth/kubeconfig


