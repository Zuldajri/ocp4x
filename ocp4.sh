#!/bin/bash

echo $(date) " - Starting Master Script"

ADMIN_USER=$1
AZURE_CLIENT_ID=$2
AZURE_TENANT_ID=$3
AZURE_SUBSCRIPTION_ID=$4
AZURE_CLIENT_SECRET=$5
DOMAIN_NAME=$6
CLUSTER_NAME=$7
RG_DOMAIN=$8
LOCATION=$9
PULL_SECRET=${10}

sudo ssh-keygen -t rsa -b 4096 -N '' -f /home/root/.ssh/openshift
sudo eval "$(ssh-agent -s)"
sudo ssh-add /home/root/.ssh/openshift

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.7/openshift-client-linux-4.4.7.tar.gz
tar xvf openshift-client-linux-4.4.6.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.7/openshift-install-linux-4.4.7.tar.gz
tar xvf openshift-install-linux-4.4.6.tar.gz

sudo mv oc kubectl openshift-install /usr/local/bin

sudo mkdir /root/.azure
sudo touch /root/.azure/osServicePrincipal.json
sudo echo {"subscriptionId":"$AZURE_SUBSCRIPTION_ID","clientId":"$AZURE_CLIENT_ID","clientSecret":"$AZURE_CLIENT_SECRET","tenantId":"$AZURE_TENANT_ID"} > /root/.azure/osServicePrincipal.json

sudo mkdir /root/openshift

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4/master/install-config.yml -O /root/openshift/install-config.yml

sudo -i "s/domian/$DOMAIN_NAME/g" /root/openshift/install-config.yml
sudo -i "s/clusterwill/$CLUSTER_NAME/g" /root/openshift/install-config.yml
sudo -i "s/RG-domain/$RG_DOMAIN/g" /root/openshift/install-config.yml
sudo -i "s/location/$LOCATION/g" /root/openshift/install-config.yml
sudo -i "s/pullSercet/$PULL_SECRET/g" /root/openshift/install-config.yml

openshift-install create cluster --dir=/root/openshift --log-level=info
