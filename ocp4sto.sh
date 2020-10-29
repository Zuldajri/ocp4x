#!/bin/bash

echo $(date) " - ### Starting Script ###"

AZURE_TENANT_ID=$1
AZURE_SUBSCRIPTION_ID=$2
ADMIN_USER=$3
OPENSHIFT_USER=$4
OPENSHIFT_PASSWORD=$5
AZURE_CLIENT_ID=$6
AZURE_CLIENT_SECRET=$7
DOMAIN_NAME=$8
RG_DOMAIN=$9
CLUSTER_NAME=${10}
CLUSTER_VERSION=${11}
CLUSTER_LOCATION=${12}
PULL_SECRET=${13}
CONTROL_PLANE_REPLICA=${14}
COMPUTE_REPLICA=${15}
CONTROL_PLANE_VM_SIZE=${16}
COMPUTE_VM_SIZE=${17}
CONTROL_PLANE_OS_DISK=${18}
COMPUTE_OS_DISK=${19}
ENABLE_FIPS=${20}
PORT_PUBLISH=${21}
NETWORK_RG=${22}
SINGLEORMULTI=${23}
VNET_NAME=${24}
CLUSTER_CIDR=${25}
VNET_CIDR=${26}
CONTROL_PLANE_SUBNET=${27}
COMPUTE_SUBNET=${28}
STORAGE_ACCOUNT_NAME=${29}
FILE_SHARE_NAME=${30}
FILE_SHARE_QUOTA=${31}




SSH_PUBLIC=$(cat /home/$ADMIN_USER/.ssh/authorized_keys)

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.$CLUSTER_VERSION/openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.$CLUSTER_VERSION/openshift-install-linux.tar.gz
tar xvf openshift-install-linux.tar.gz
sudo mv oc kubectl openshift-install /usr/local/bin


sudo mkdir .azure
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/osServicePrincipal.json -O /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_SUBSCRIPTION_ID/$AZURE_SUBSCRIPTION_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_ID/$AZURE_CLIENT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_CLIENT_SECRET/$AZURE_CLIENT_SECRET/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json
sudo sed -i "s/AZURE_TENANT_ID/$AZURE_TENANT_ID/g" /var/lib/waagent/custom-script/download/0/.azure/osServicePrincipal.json

zones=""
if [[ $SINGLEORMULTI == "az" ]]; then
zones="zones:
      - '1'
      - '2'
      - '3'"
fi

sudo mkdir openshift
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/install-config.yaml -O /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

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

sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/cluster_cidr.py -O /var/lib/waagent/custom-script/download/0/cluster_cidr.py
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/vnet_cidr.py -O /var/lib/waagent/custom-script/download/0/vnet_cidr.py
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/av_zones.py -O /var/lib/waagent/custom-script/download/0/av_zones.py
sudo python /var/lib/waagent/custom-script/download/0/cluster_cidr.py /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml $CLUSTER_CIDR
sudo python /var/lib/waagent/custom-script/download/0/vnet_cidr.py /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml $VNET_CIDR
sudo python /var/lib/waagent/custom-script/download/0/av_zones.py /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml $zones

echo sshKey: $SSH_PUBLIC >> /var/lib/waagent/custom-script/download/0/openshift/install-config.yaml

openshift-install create cluster --dir=openshift --log-level=info

export KUBECONFIG=./openshift/auth/kubeconfig
CLUSTER_ID=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.labels.machine\.openshift\.io/cluster-api-cluster}')
KEYVAULT_NAME=$CLUSTER_ID


sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/oauth.yaml
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/cr.yaml

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
STORAGE_ACCOUNT_KEY=$(az storage account keys list -g $NETWORK_RG -n $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)
az storage share create --account-name $STORAGE_ACCOUNT_NAME --name $FILE_SHARE_NAME --account-key $STORAGE_ACCOUNT_KEY --quota $FILE_SHARE_QUOTA
sleep 60
oc create secret generic file-share-secret --from-literal=azurestorageaccountname=$STORAGE_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$STORAGE_ACCOUNT_KEY
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/pv.yaml
sudo sed -i "s/QUOTA/$FILE_SHARE_QUOTA/g" /var/lib/waagent/custom-script/download/0/pv.yaml
sudo sed -i "s/SHARENAME/$FILE_SHARE_NAME/g" /var/lib/waagent/custom-script/download/0/pv.yaml
oc apply -f pv.yaml
sleep 60
sudo wget https://raw.githubusercontent.com/Zuldajri/ocp4x/master/pvc.yaml
sudo sed -i "s/QUOTA/$FILE_SHARE_QUOTA/g" /var/lib/waagent/custom-script/download/0/pvc.yaml
oc apply -f pvc.yaml





