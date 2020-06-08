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
LOCATION=$9
PULL_SECRET=${10}

sudo ssh-keygen -t rsa -b 4096 -N '' -f /home/root/.ssh/openshift
sudo eval "$(ssh-agent -s)"
sudo ssh-add /home/root/.ssh/openshift

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.7/openshift-client-linux-4.4.7.tar.gz
tar xvf openshift-client-linux-4.4.7.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.7/openshift-install-linux-4.4.7.tar.gz
tar xvf openshift-install-linux-4.4.7.tar.gz

sudo mv oc kubectl openshift-install /usr/local/bin

sudo mkdir /root/.azure
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/osServicePrincipal.json -O /root/.azure/osServicePrincipal.json

sudo sed -i "s/AZURE_SUBSCRIPTION_ID/$AZURE_SUBSCRIPTION_ID/g" /root/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_ID/$AZURE_CLIENT_ID/g" /root/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_SECRET/$AZURE_CLIENT_SECRET/g" /root/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_TENANT_ID/$AZURE_TENANT_ID/g" /root/.azure/osServicePrincipal.json

sudo mkdir openshift

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/install-config.yaml -O /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

sudo sed -i "s/domian/$DOMAIN_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/clusterwill/$CLUSTER_NAME/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/RG-domain/$RG_DOMAIN/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/location/$LOCATION/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml
sudo sed -i "s/pullSercet/$PULL_SECRET/g" /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

openshift-install create cluster --dir=openshift --log-level=info
