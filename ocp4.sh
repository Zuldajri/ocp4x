#!/bin/bash

echo $(date) " - Starting Master Script"

ADMIN_USER=$1
AZURE_CLIENT_ID=$2
AZURE_TENANT_ID=$3
AZURE_SUBSCRIPTION_ID=$4
AZURE_CLIENT_SECRET=$5
KEYVAULT_NAME=$6
KEYVAULT_RG=$7
KEYVAULT_LOCATION=$8
DOMAIN_NAME=$9
RG_DOMAIN=${10}
CLUSTER_NAME=${11}
CLUSTER_VERSION=${12}
LOCATION=${13}
CONTROL_PLANE_REPLICA=${14}
CONTROL_PLANE_VM_SIZE=${15}
CONTROL_PLANE_OS_DISK=${16}
COMPUTE_REPLICA=${17}
COMPUTE_VM_SIZE=${18}
COMPUTE_OS_DISK=${19}
PULL_SECRET=${20}

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

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli -y

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
az group create -n $KEYVAULT_RG -l '$KEYVAULT_LOCATION'
az keyvault create -n $KEYVAULT_NAME -g $KEYVAULT_RG -l '$KEYVAULT_LOCATION' --enabled-for-template-deployment true
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeadmin-password --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeadmin-password
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeconfig --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeconfig
az keyvault secret set --vault-name $KEYVAULT_NAME -n clusterPrivateKey --file /var/lib/waagent/custom-script/download/0/openshiftkey
az keyvault secret set --vault-name $KEYVAULT_NAME -n clusterPublicKey --file /var/lib/waagent/custom-script/download/0/openshiftkey.pub

