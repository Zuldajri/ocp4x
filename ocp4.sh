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
CLUSTER_VERSION=$9
LOCATION=${10}
CONTROL_PLANE_REPLICA=${11}
CONTROL_PLANE_VM_SIZE=${12}
CONTROL_PLANE_OS_DISK=${13}
COMPUTE_REPLICA=${14}
COMPUTE_VM_SIZE=${15}
COMPUTE_OS_DISK=${16}
PULL_SECRET=${17}

ssh-keygen -t rsa -b 4096 -N '' -f /var/lib/waagent/custom-script/download/0/openshiftkey
eval "$(ssh-agent -s)"
ssh-add /var/lib/waagent/custom-script/download/0/openshiftkey

SSH_PUBLIC=$(cat /var/lib/waagent/custom-script/download/0/openshiftkey.pub)

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$CLUSTER_VERSION/openshift-client-linux-$CLUSTER_VERSION.tar.gz
tar xvf openshift-client-linux-$CLUSTER_VERSION.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$CLUSTER_VERSION/openshift-install-linux-$CLUSTER_VERSION.tar.gz 
tar xvf openshift-install-linux-$CLUSTER_VERSION.tar.gz

sudo mv oc kubectl openshift-install /usr/local/bin

sudo mkdir .azure
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/osServicePrincipal.json -O /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json

sudo sed -i "s/AZURE_SUBSCRIPTION_ID/$AZURE_SUBSCRIPTION_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_ID/$AZURE_CLIENT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_SECRET/$AZURE_CLIENT_SECRET/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_TENANT_ID/$AZURE_TENANT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json

sudo mkdir openshift

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/install-config.yaml -O /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

sudo sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CLUSTER_NAME/$CLUSTER_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/RG_DOMAIN/$RG_DOMAIN/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/LOCATION/$LOCATION/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/PULL_SECRET/$PULL_SECRET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_REPLICA/$CONTROL_PLANE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_VM_SIZE/$CONTROL_PLANE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_OS_DISK/$CONTROL_PLANE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_REPLICA/$COMPUTE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_VM_SIZE/$COMPUTE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_OS_DISK/$COMPUTE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

echo sshKey: $SSH_PUBLIC >> /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

openshift-install create cluster --dir=openshift --log-level=info

