#!/bin/bash

echo $(date) " - ### Starting Script ###"

AZURE_TENANT_ID=$1
AZURE_SUBSCRIPTION_ID=$2
ADMIN_USER=$3
OPENSHIFT_USER=$4
OPENSHIFT_PASSWORD=$5
AZURE_CLIENT_ID=$6
AZURE_CLIENT_SECRET=$7
KEYVAULT_NAME=$8
KEYVAULT_RG=$9
KEYVAULT_LOCATION=${10}
DOMAIN_NAME=${11}
RG_DOMAIN=${12}
CLUSTER_NAME=${13}
CLUSTER_VERSION=${14}
CLUSTER_LOCATION=${15}
PULL_SECRET=${16}
CONTROL_PLANE_REPLICA=${17}
COMPUTE_REPLICA=${18}
CONTROL_PLANE_VM_SIZE=${19}
COMPUTE_VM_SIZE=${20}
CONTROL_PLANE_OS_DISK=${21}
COMPUTE_OS_DISK=${22}
ENABLE_FIPS=${23}
PORT_PUBLISH=${24}
NETWORK_RG=${25}
VNET_NAME=${26}
CLUSTER_CIDR=${27}
VNET_CIDR=${28}
CONTROL_PLANE_SUBNET=${29}
COMPUTE_SUBNET=${30}




SSH_PUBLIC=$(cat /home/$ADMIN_USER/.ssh/authorized_keys)

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.$CLUSTER_VERSION/openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.$CLUSTER_VERSION/openshift-install-linux.tar.gz
tar xvf openshift-install-linux.tar.gz
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
sudo sed -i "s/CLUSTER_LOCATION/$CLUSTER_LOCATION/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/PULL_SECRET/$PULL_SECRET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_REPLICA/$CONTROL_PLANE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_VM_SIZE/$CONTROL_PLANE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_OS_DISK/$CONTROL_PLANE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_REPLICA/$COMPUTE_REPLICA/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_VM_SIZE/$COMPUTE_VM_SIZE/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_OS_DISK/$COMPUTE_OS_DISK/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/ENABLE_FIPS/$ENABLE_FIPS/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/PORT_PUBLISH/$PORT_PUBLISH/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/NETWORK_RG/$NETWORK_RG/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/VNET_NAME/$VNET_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/CONTROL_PLANE_SUBNET/$CONTROL_PLANE_SUBNET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/COMPUTE_SUBNET/$COMPUTE_SUBNET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/cluster_cidr.py -O /var/lib/waagent/custom-script/download/0/cluster_cidr.py
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/vnet_cidr.py -O /var/lib/waagent/custom-script/download/0/vnet_cidr.py
sudo python /var/lib/waagent/custom-script/download/0/cluster_cidr.py /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml $CLUSTER_CIDR
sudo python /var/lib/waagent/custom-script/download/0/vnet_cidr.py /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml $VNET_CIDR

echo sshKey: $SSH_PUBLIC >> /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

openshift-install create cluster --dir=openshift --log-level=info

export KUBECONFIG=./openshift/auth/kubeconfig

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/oauth.yaml
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/cr.yaml

oc apply -f oauth.yaml

yum install httpd-tools -y

htpasswd -c -B -b ocppass $OPENSHIFT_USER $OPENSHIFT_PASSWORD
oc create secret generic htpass-secret --from-file=htpasswd=ocppass -n openshift-config
oc apply -f cr.yaml

oc adm policy add-cluster-role-to-user cluster-admin $OPENSHIFT_USER

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli -y

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
az group create -n $KEYVAULT_RG -l $KEYVAULT_LOCATION
az keyvault create -n $KEYVAULT_NAME -g $KEYVAULT_RG -l $KEYVAULT_LOCATION --enabled-for-template-deployment true
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeadmin-password --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeadmin-password
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeconfig --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeconfig



