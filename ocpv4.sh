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
CLUSTER_ADMIN=${10}
CLUSTER_ADMIN_PASSWORD=${11}
LOCATION=${12}
CONTROL_PLANE_REPLICA=${13}
CONTROL_PLANE_VM_SIZE=${14}
CONTROL_PLANE_OS_DISK=${15}
COMPUTE_REPLICA=${16}
COMPUTE_VM_SIZE=${17}
COMPUTE_OS_DISK=${18}
PULL_SECRET=${19}

ssh-keygen -t rsa -b 4096 -N '' -f /var/lib/waagent/custom-script/download/0/openshiftkey
eval "$(ssh-agent -s)"
ssh-add /var/lib/waagent/custom-script/download/0/openshiftkey

SSH_PUBLIC=$(cat /var/lib/waagent/custom-script/download/0/openshiftkey.pub)

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

sudo yum install jq -y

az role assignment create --role "User Access Administrator" --assignee-object-id $(az ad sp list --filter "appId eq '$AZURE_CLIENT_ID'" | jq '.[0].objectId' -r)

az ad app permission add --id $AZURE_CLIENT_ID --api 00000002-0000-0000-c000-000000000000 --api-permissions 824c81eb-e3f8-4ee6-8f6d-de7f50d565b7=Role
az ad app permission grant --id $AZURE_CLIENT_ID --api 00000002-0000-0000-c000-000000000000

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

oc apply -f oauth.yaml

yum install httpd-tools -y

htpasswd -c -B -b ocppass $CLUSTER_ADMIN $CLUSTER_ADMIN_PASSWORD

oc create secret generic htpass-secret --from-file=htpasswd=ocppass -n openshift-config

oc apply -f cr.yaml

oc adm policy add-role-to-user admin $CLUSTER_ADMIN
