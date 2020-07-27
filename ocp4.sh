#!/bin/bash

echo $(date) " - ############## Starting Script ####################"

set-e

AZURE_TENANT_ID=$1
AZURE_SUBSCRIPTION_ID=$2
ADMIN_USER=$3
SSH_KEY=$4
OPENSHIFT_USER=$5
OPENSHIFT_PASSWORD=$6
AZURE_CLIENT_ID=$7
AZURE_CLIENT_SECRET=$8
KEYVAULT_NAME=$9
KEYVAULT_RG=${10}
KEYVAULT_LOCATION=${11}
DOMAIN_NAME=${12}
RG_DOMAIN=${13}
CLUSTER_NAME=${14}
CLUSTER_VERSION=${15}
CLUSTER_LOCATION=${16}
PULL_SECRET=${17}
CONTROL_PLANE_REPLICA=${18}
COMPUTE_REPLICA=${19}
CONTROL_PLANE_VM_SIZE=${20}
COMPUTE_VM_SIZE=${21}
CONTROL_PLANE_OS_DISK=${22}
COMPUTE_OS_DISK=${23}
FIPS=${24}
PUBLISH=${25}

#Var
export INSTALLERHOME=/home/$ADMIN_USER/.openshift



echo $(date) " - Install Podman"
yum install -y podman
echo $(date) " - Install Podman Complete"

echo $(date) " - Install httpd-tools"
yum install -y httpd-tools
echo $(date) " - Install httpd-tools Complete"

echo $(date) " - Install Azure CLI"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli -y
echo $(date) " - Install Azure CLI Complete"

echo $(date) " - Download Binaries"
runuser -l $ADMIN_USER -c "mkdir -p /home/$ADMIN_USER/.openshift"

runuser -l $ADMIN_USER -c "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$CLUSTER_VERSION/openshift-install-linux-$CLUSTER_VERSION.tar.gz"
runuser -l $ADMIN_USER -c "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$CLUSTER_VERSION/openshift-client-linux-$CLUSTER_VERSION.tar.gz"
runuser -l $ADMIN_USER -c "tar -xvf openshift-install-linux-$CLUSTER_VERSION.tar.gz -C $INSTALLERHOME"
runuser -l $ADMIN_USER -c "sudo tar -xvf openshift-client-linux-$CLUSTER_VERSION.tar.gz -C /usr/bin"

chmod +x /usr/bin/kubectl
chmod +x /usr/bin/oc
chmod +x $INSTALLERHOME/openshift-install
echo $(date) " - Download Binaries Done."

echo $(date) " - Setup Azure Credentials for OCP"
runuser -l $ADMIN_USER -c "mkdir -p /home/$ADMIN_USER/.azure"
runuser -l $ADMIN_USER -c "touch /home/$ADMIN_USER/.azure/osServicePrincipal.json"
cat > /home/$ADMIN_USER/.azure/osServicePrincipal.json <<EOF
{"subscriptionId":"AZURE_SUBSCRIPTION_ID","clientId":"AZURE_CLIENT_ID","clientSecret":"AZURE_CLIENT_SECRET","tenantId":"AZURE_TENANT_ID"}
EOF
echo $(date) " - Setup Azure Credentials for OCP - Complete"

echo $(date) " - Setup Install config"
runuser -l $ADMIN_USER -c "mkdir -p $INSTALLERHOME/openshiftfourx"
runuser -l $ADMIN_USER -c "touch $INSTALLERHOME/openshiftfourx/install-config.yaml"
cat > $INSTALLERHOME/openshiftfourx/install-config.yaml <<EOF
apiVersion: v1
baseDomain: $DOMAIN_NAME
controlPlane:
  hyperthreading: Enabled
  name: master
  platform: 
    azure:
      osDisk:
        diskSizeGB: CONTROL_PLANE_OS_DISK
      type: $CONTROL_PLANE_VM_SIZE
  replicas: $CONTROL_PLANE_REPLICA
compute:
- hyperthreading: Enabled
  name: worker
  platform: 
    azure:
      type: $COMPUTE_VM_SIZE
      osDisk:
        diskSizeGB: $COMPUTE_OS_DISK 
      zones: 
      - "1"
      - "2"
      - "3"
  replicas: $COMPUTE_REPLICA
metadata:
  name: $CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  azure:
    baseDomainResourceGroupName: $RG_DOMAIN
    region: $LOCATION
pullSecret: '$PULL_SECRET'
fips: $FIPS
publish: $PUBLISH
sshKey: |
  $SSH_KEY
EOF
echo $(date) " - Setup Install config - Complete"

echo $(date) " - Install OCP"
runuser -l $ADMIN_USER -c "$INSTALLERHOME/openshift-install create cluster --dir=$INSTALLERHOME/openshiftfourx --log-level=debug"
runuser -l $ADMIN_USER -c "sleep 120"
echo $(date) " - OCP Install Complete"

echo $(date) " - Kube Config setup"
runuser -l $ADMIN_USER -c "mkdir -p /home/$ADMIN_USER/.kube"
runuser -l $ADMIN_USER -c "cp $INSTALLERHOME/openshiftfourx/auth/kubeconfig /home/$ADMIN_USER/.kube/config"
echo $(date) "Kube Config setup done"
















az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
az group create -n $KEYVAULT_RG -l $KEYVAULT_LOCATION
az keyvault create -n $KEYVAULT_NAME -g $KEYVAULT_RG -l $KEYVAULT_LOCATION --enabled-for-template-deployment true
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeadmin-password --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeadmin-password
az keyvault secret set --vault-name $KEYVAULT_NAME -n kubeconfig --file /var/lib/waagent/custom-script/download/0/openshift/auth/kubeconfig
az keyvault secret set --vault-name $KEYVAULT_NAME -n clusterPrivateKey --file /var/lib/waagent/custom-script/download/0/openshiftkey
az keyvault secret set --vault-name $KEYVAULT_NAME -n clusterPublicKey --file /var/lib/waagent/custom-script/download/0/openshiftkey.pub

