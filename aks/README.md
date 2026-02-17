### Steps
#### 1. Set env variabels
```bash
$ RG="rg-secure-dev-platform"
LOCATION="centralindia"

VNET_NAME="aks-secure-vnet"
NODE_SUBNET="aks-node-subnet"

CLUSTER_NAME="private-aks-cluster"
```

#### 2. Create Resource Group
```bash
az group create \
  --name $RG \
  --location $LOCATION
```

#### 3 — Create VNet + Node Subnet
```bash
az network vnet create \
  --resource-group $RG \
  --name $VNET_NAME \
  --address-prefix 10.40.0.0/16 \
  --subnet-name $NODE_SUBNET \
  --subnet-prefix 10.40.1.0/24
```
Get subnet ID:
```bash
SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $NODE_SUBNET \
  --query id -o tsv)
```

#### 4 - Role Assignment
```bash
$ az role assignment create \
  --role "Azure Kubernetes Service RBAC Admin" \
  --assignee "c4b64e63-e75a-46f9-8fcc-3d46b7e35146" \
  --scope "//subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f"
{
  "condition": null,
  "conditionVersion": null,
  "createdBy": null,
  "createdOn": "2026-02-17T07:35:45.129229+00:00",
  "delegatedManagedIdentityResourceId": null,
  "description": null,
  "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/providers/Microsoft.Authorization/roleAssignments/bce3c152-fba2-4f03-8e3e-234ff362e8a9",
  "name": "bce3c152-fba2-4f03-8e3e-234ff362e8a9",
  "principalId": "c4b64e63-e75a-46f9-8fcc-3d46b7e35146",
  "principalType": "Group",
  "roleDefinitionId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/providers/Microsoft.Authorization/roleDefinitions/3498e952-d568-435e-9b2c-8d77e338d7f7",
  "scope": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f",
  "type": "Microsoft.Authorization/roleAssignments",
  "updatedBy": "8507ed11-d79b-4641-974b-8655c027e27f",
  "updatedOn": "2026-02-17T07:35:45.438672+00:00"
}
``` 

#### 5 — Create PRIVATE Secure AKS Cluster
This command mirrors everything you enabled earlier but avoids heavy observability initially:
```bash
az aks create -g $RG --name $CLUSTER_NAME --location $LOCATION \
  --enable-private-cluster \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-policy azure \
  --vnet-subnet-id $SUBNET_ID \
  --service-cidr 172.16.0.0/16 \
  --dns-service-ip 172.16.0.10 \
  --node-count 2 \
  --node-vm-size Standard_D2s_v5 \
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --enable-image-cleaner \
  --enable-addons azure-policy \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5 \
  --disable-local-accounts \
  --generate-ssh-keys
```

***ERROR: (MissingSubscriptionRegistration) The subscription is not registered to use namespace 'Microsoft.ContainerService'. See https://aka.ms/rps-not-found for how to register subscriptions.
Code: MissingSubscriptionRegistration
Message: The subscription is not registered to use namespace 'Microsoft.ContainerService'. See https://aka.ms/rps-not-found for how to register subscriptions.
Exception Details:      (MissingSubscriptionRegistration) The subscription is not registered to use namespace 'Microsoft.ContainerService'. See https://aka.ms/rps-not-found for how to register subscriptions.
Code: MissingSubscriptionRegistration
Message: The subscription is not registered to use namespace 'Microsoft.ContainerService'. See https://aka.ms/rps-not-found for how to register subscriptions.
Target: Microsoft.ContainerService***

- **Why did this happen?**
Azure doesn't enable every service by default to keep subscriptions "clean" and avoid accidental resource creation in large organizations. Usually, when you create a resource in the Portal UI, Azure silently registers the provider for you. However, when using the Azure CLI, you have to handle this manual "handshake" yourself.


#### FIX:
1. CLI:
```bash

# Register AKS (The one from your error)
az provider register --namespace Microsoft.ContainerService --wait

# Register these too (You'll need them for your demo)
az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az provider register --namespace Microsoft.OperationsManagement --wait
```


2. UI
```bash
Go to Subscriptions in the top search bar.

Select your subscription (cc076e9a...).

On the left sidebar, under Settings, click Resource providers.

Search for ContainerService.

Click Microsoft.ContainerService and hit Register at the top.
```

**Verification**
```bash
$ az provider show --namespace Microsoft.ContainerService --query "registrationState"
"Registered"
```

*Windows GitBash AKS installation command*
```bash
$ MSYS_NO_PATHCONV=1 az aks create   --resource-group "rg-secure-dev-platform"   --name "private-aks-cluster"   --location "centralindia"   --enable-private-cluster   --node-vm-size Standard_D2s_v3   --node-count 2   --enable-cluster-autoscaler   --min-count 2   --max-count 4   --network-plugin azure   --network-plugin-mode overlay   --vnet-subnet-id /subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet   --enable-managed-identity   --generate-ssh-keys
docker_bridge_cidr is not a known attribute of class <class 'azure.mgmt.containerservice.models._models_py3.ContainerServiceNetworkProfile'> and will be ignored
{
  "aadProfile": null,
  "addonProfiles": null,
  "agentPoolProfiles": [
    {
      "availabilityZones": null,
      "capacityReservationGroupId": null,
      "count": 2,
      "creationData": null,
      "currentOrchestratorVersion": "1.33.6",
      "eTag": "5bc0dd6d-cee5-48f5-a84b-5b7f4fff3c77",
      "enableAutoScaling": true,
      "enableEncryptionAtHost": false,
      "enableFips": false,
      "enableNodePublicIp": false,
      "enableUltraSsd": false,
      "gatewayProfile": null,
      "gpuInstanceProfile": null,
      "gpuProfile": null,
      "hostGroupId": null,
      "kubeletConfig": null,
      "kubeletDiskType": "OS",
      "linuxOsConfig": null,
      "localDnsProfile": null,
      "maxCount": 4,
      "maxPods": 250,
      "messageOfTheDay": null,
      "minCount": 2,
      "mode": "System",
      "name": "nodepool1",
      "networkProfile": null,
      "nodeImageVersion": "AKSUbuntu-2204gen2containerd-202601.27.0",
      "nodeLabels": null,
      "nodePublicIpPrefixId": null,
      "nodeTaints": null,
      "orchestratorVersion": "1.33",
      "osDiskSizeGb": 128,
      "osDiskType": "Managed",
      "osSku": "Ubuntu",
      "osType": "Linux",
      "podIpAllocationMode": null,
      "podSubnetId": null,
      "powerState": {
        "code": "Running"
      },
      "provisioningState": "Succeeded",
      "proximityPlacementGroupId": null,
      "scaleDownMode": "Delete",
      "scaleSetEvictionPolicy": null,
      "scaleSetPriority": null,
      "securityProfile": {
        "enableSecureBoot": false,
        "enableVtpm": false,
        "sshAccess": null
      },
      "spotMaxPrice": null,
      "status": null,
      "tags": null,
      "type": "VirtualMachineScaleSets",
      "upgradeSettings": {
        "drainTimeoutInMinutes": null,
        "maxSurge": "10%",
        "maxUnavailable": "0",
        "nodeSoakDurationInMinutes": null,
        "undrainableNodeBehavior": null
      },
      "virtualMachineNodesStatus": null,
      "virtualMachinesProfile": null,
      "vmSize": "Standard_D2s_v3",
      "vnetSubnetId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet",
      "windowsProfile": null,
      "workloadRuntime": null
    }
  ],
  "aiToolchainOperatorProfile": null,
  "apiServerAccessProfile": {
    "authorizedIpRanges": null,
    "disableRunCommand": null,
    "enablePrivateCluster": true,
    "enablePrivateClusterPublicFqdn": true,
    "enableVnetIntegration": null,
    "privateDnsZone": "system",
    "subnetId": null
  },
  "autoScalerProfile": {
    "balanceSimilarNodeGroups": "false",
    "daemonsetEvictionForEmptyNodes": false,
    "daemonsetEvictionForOccupiedNodes": true,
    "expander": "random",
    "ignoreDaemonsetsUtilization": false,
    "maxEmptyBulkDelete": "10",
    "maxGracefulTerminationSec": "600",
    "maxNodeProvisionTime": "15m",
    "maxTotalUnreadyPercentage": "45",
    "newPodScaleUpDelay": "0s",
    "okTotalUnreadyCount": "3",
    "scaleDownDelayAfterAdd": "10m",
    "scaleDownDelayAfterDelete": "10s",
    "scaleDownDelayAfterFailure": "3m",
    "scaleDownUnneededTime": "10m",
    "scaleDownUnreadyTime": "20m",
    "scaleDownUtilizationThreshold": "0.5",
    "scanInterval": "10s",
    "skipNodesWithLocalStorage": "false",
    "skipNodesWithSystemPods": "true"
  },
  "autoUpgradeProfile": {
    "nodeOsUpgradeChannel": "NodeImage",
    "upgradeChannel": null
  },
  "azureMonitorProfile": null,
  "azurePortalFqdn": "61cc2dc26ccfebb4311a273b02f738bd-priv.portal.hcp.centralindia.azmk8s.io",
  "bootstrapProfile": {
    "artifactSource": "Direct",
    "containerRegistryId": null
  },
  "currentKubernetesVersion": "1.33.6",
  "disableLocalAccounts": false,
  "diskEncryptionSetId": null,
  "dnsPrefix": "private-ak-rg-secure-dev-pl-0de459",
  "eTag": "f8eed3f9-76b8-4006-bdde-e4bd08117111",
  "enableRbac": true,
  "extendedLocation": null,
  "fqdn": "private-ak-rg-secure-dev-pl-0de459-156u8rlq.hcp.centralindia.azmk8s.io",
  "fqdnSubdomain": null,
  "httpProxyConfig": null,
  "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourcegroups/rg-secure-dev-platform/providers/Microsoft.ContainerService/managedClusters/private-aks-cluster",
  "identity": {
    "delegatedResources": null,
    "principalId": "412443c4-b386-40b7-a09a-7f4e78c7be81",
    "tenantId": "5ae15ec1-57ad-4b32-9b52-6929573dfbf0",
    "type": "SystemAssigned",
    "userAssignedIdentities": null
  },
  "identityProfile": {
    "kubeletidentity": {
      "clientId": "bef71225-9b42-4753-9c8f-c7265f18a806",
      "objectId": "f8c50a4f-82f9-49e0-b996-bf771a42d4ba",
      "resourceId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourcegroups/MC_rg-secure-dev-platform_private-aks-cluster_centralindia/providers/Microsoft.ManagedIdentity/userAssignedIdentities/private-aks-cluster-agentpool"
    }
  },
  "ingressProfile": null,
  "kind": "Base",
  "kubernetesVersion": "1.33",
  "linuxProfile": {
    "adminUsername": "azureuser",
    "ssh": {
      "publicKeys": [
        {
          "keyData": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaOoQaHsR8y94caS8LGY2X5ku2KWw2Pd5e9DuiF4I/k1KuQGO2LYTNojDsXb4XyGd7JslsW+HUP7rhuixzx1B0CXYmttvTqFAZaUsC3qMci6zInlc+VsS0uEEs5SWW+XKqPs31DqznA96lHAmNGym1HQyUtXcnJCeWVGnW3/qOA5KxISQk1Os41DUlBu3s8YnweC6rHhFQzzKyX6u7b0SGyO+hY4k1l+jJxZA4xl/gVlsOyMj6I8yxXEfgLT/RgNuKIy/XepirBoNtpm6lGFKWEOKMG3qIw2ltywJeLyBYON3G1U7WsYsw/IaDmOtq0NkGnXA3b/sQScif5J9v4Y5OvgQOpsrPqNzjVPoHTMnegABYnRuU7NaCQ3wpC9IwJsudR2HLyKpCTl3GH5rT1m3vnUTj8SY+ltVecXGbn8/Joa5xUQGgd1Wat5chcDRH9JOizjYpdKMdWu+/5WBcy2FebdUA3lUg71l39+NLN6gREVsm098AoZQsrxgTwvRk308= ANUROOP P S@ANU\n"
        }
      ]
    }
  },
  "location": "centralindia",
  "maxAgentPools": 100,
  "metricsProfile": {
    "costAnalysis": {
      "enabled": false
    }
  },
  "name": "private-aks-cluster",
  "networkProfile": {
    "advancedNetworking": null,
    "dnsServiceIp": "10.0.0.10",
    "ipFamilies": [
      "IPv4"
    ],
    "loadBalancerProfile": {
      "allocatedOutboundPorts": null,
      "backendPoolType": "nodeIPConfiguration",
      "effectiveOutboundIPs": [
        {
          "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/MC_rg-secure-dev-platform_private-aks-cluster_centralindia/providers/Microsoft.Network/publicIPAddresses/e11e2c53-17c5-44be-b6ee-227cffa489b2",
          "resourceGroup": "MC_rg-secure-dev-platform_private-aks-cluster_centralindia"
        }
      ],
      "enableMultipleStandardLoadBalancers": null,
      "idleTimeoutInMinutes": null,
      "managedOutboundIPs": {
        "count": 1,
        "countIpv6": null
      },
      "outboundIPs": null,
      "outboundIpPrefixes": null
    },
    "loadBalancerSku": "standard",
    "natGatewayProfile": null,
    "networkDataplane": "azure",
    "networkMode": null,
    "networkPlugin": "azure",
    "networkPluginMode": "overlay",
    "networkPolicy": "none",
    "outboundType": "loadBalancer",
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
      "10.244.0.0/16"
    ],
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
      "10.0.0.0/16"
    ],
    "staticEgressGatewayProfile": null
  },
  "nodeProvisioningProfile": {
    "defaultNodePools": "Auto",
    "mode": "Manual"
  },
  "nodeResourceGroup": "MC_rg-secure-dev-platform_private-aks-cluster_centralindia",
  "nodeResourceGroupProfile": null,
  "oidcIssuerProfile": {
    "enabled": false,
    "issuerUrl": null
  },
  "podIdentityProfile": null,
  "powerState": {
    "code": "Running"
  },
  "privateFqdn": "private-ak-rg-secure-dev-pl-0de459-f9yh714l.b22017b4-8452-40aa-918c-2aede279ae4b.privatelink.centralindia.azmk8s.io",
  "privateLinkResources": [
    {
      "groupId": "management",
      "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourcegroups/rg-secure-dev-platform/providers/Microsoft.ContainerService/managedClusters/private-aks-cluster/privateLinkResources/management",
      "name": "management",
      "privateLinkServiceId": null,
      "requiredMembers": [
        "management"
      ],
      "resourceGroup": "rg-secure-dev-platform",
      "type": "Microsoft.ContainerService/managedClusters/privateLinkResources"
    }
  ],
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "rg-secure-dev-platform",
  "resourceUid": "6994240b708db30001e2ae2f",
  "securityProfile": {
    "azureKeyVaultKms": null,
    "customCaTrustCertificates": null,
    "defender": null,
    "imageCleaner": null,
    "workloadIdentity": null
  },
  "serviceMeshProfile": null,
  "servicePrincipalProfile": {
    "clientId": "msi",
    "secret": null
  },
  "sku": {
    "name": "Base",
    "tier": "Free"
  },
  "status": null,
  "storageProfile": {
    "blobCsiDriver": null,
    "diskCsiDriver": {
      "enabled": true
    },
    "fileCsiDriver": {
      "enabled": true
    },
    "snapshotController": {
      "enabled": true
    }
  },
  "supportPlan": "KubernetesOfficial",
  "systemData": null,
  "tags": null,
  "type": "Microsoft.ContainerService/ManagedClusters",
  "upgradeSettings": null,
  "windowsProfile": {
    "adminPassword": null,
    "adminUsername": "azureuser",
    "enableCsiProxy": true,
    "gmsaProfile": null,
    "licenseType": null
  },
  "workloadAutoScalerProfile": {
    "keda": null,
    "verticalPodAutoscaler": null
  }
}
```
#### Listing Kubectl nodes
```bash
anuroop [ ~ ]$ az aks command invoke   -g rg-secure-dev-platform   -n private-aks-cluster   --command "kubectl get nodes -o wide"
command started at 2026-02-17 08:29:56+00:00, finished at 2026-02-17 08:29:56+00:00 with exitcode=0
NAME                                STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-26280851-vmss000000   Ready    <none>   5m50s   v1.33.6   10.40.1.5     <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-1
aks-nodepool1-26280851-vmss000001   Ready    <none>   5m53s   v1.33.6   10.40.1.6     <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-1

anuroop [ ~ ]$
```

#### Check for systempool nodes based on `kubernetes.azure.com/mode=system` label
```bash
anuroop [ ~ ]$ az aks command invoke   -g rg-secure-dev-platform   -n private-aks-cluster   --command "kubectl get nodes --show-labels" | grep -i 'kubernetes.azure.com/mode=system'
aks-nodepool1-26280851-vmss000000   Ready    <none>   19m   v1.33.6   agentpool=nodepool1,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=nodepool1,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=1254a542-0bd9-11f1-a68e-da560e449a7a,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=system,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-nodepool1-26280851-vmss000000,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
aks-nodepool1-26280851-vmss000001   Ready    <none>   19m   v1.33.6   agentpool=nodepool1,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=nodepool1,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=1254a542-0bd9-11f1-a68e-da560e449a7a,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=system,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-nodepool1-26280851-vmss000001,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
anuroop [ ~ ]$
```
#### 6. Creating userpool apart for Application workload
```bash
$ az aks nodepool add \
  --resource-group rg-secure-dev-platform \
  --cluster-name private-aks-cluster \
  --name userpool \
  --mode User \
  --node-count 1 \
  --node-vm-size Standard_D2s_v3
{
  "availabilityZones": null,
  "capacityReservationGroupId": null,
  "count": 1,
  "creationData": null,
  "currentOrchestratorVersion": "1.33.6",
  "eTag": "1c195000-20ca-465a-a1c6-5efa92845f5c",
  "enableAutoScaling": false,
  "enableEncryptionAtHost": false,
  "enableFips": false,
  "enableNodePublicIp": false,
  "enableUltraSsd": false,
  "gatewayProfile": null,
  "gpuInstanceProfile": null,
  "gpuProfile": null,
  "hostGroupId": null,
  "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourcegroups/rg-secure-dev-platform/providers/Microsoft.ContainerService/managedClusters/private-aks-cluster/agentPools/userpool",
  "kubeletConfig": null,
  "kubeletDiskType": "OS",
  "linuxOsConfig": null,
  "localDnsProfile": null,
  "maxCount": null,
  "maxPods": 250,
  "messageOfTheDay": null,
  "minCount": null,
  "mode": "User",
  "name": "userpool",
  "networkProfile": null,
  "nodeImageVersion": "AKSUbuntu-2204gen2containerd-202601.27.0",
  "nodeLabels": null,
  "nodePublicIpPrefixId": null,
  "nodeTaints": null,
  "orchestratorVersion": "1.33",
  "osDiskSizeGb": 128,
  "osDiskType": "Managed",
  "osSku": "Ubuntu",
  "osType": "Linux",
  "podIpAllocationMode": null,
  "podSubnetId": null,
  "powerState": {
    "code": "Running"
  },
  "provisioningState": "Succeeded",
  "proximityPlacementGroupId": null,
  "resourceGroup": "rg-secure-dev-platform",
  "scaleDownMode": "Delete",
  "scaleSetEvictionPolicy": null,
  "scaleSetPriority": null,
  "securityProfile": {
    "enableSecureBoot": false,
    "enableVtpm": false,
    "sshAccess": null
  },
  "spotMaxPrice": null,
  "status": null,
  "tags": null,
  "type": "Microsoft.ContainerService/managedClusters/agentPools",
  "typePropertiesType": "VirtualMachineScaleSets",
  "upgradeSettings": {
    "drainTimeoutInMinutes": null,
    "maxSurge": "10%",
    "maxUnavailable": "0",
    "nodeSoakDurationInMinutes": null,
    "undrainableNodeBehavior": "Schedule"
  },
  "virtualMachineNodesStatus": null,
  "virtualMachinesProfile": null,
  "vmSize": "Standard_D2s_v3",
  "vnetSubnetId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet",
  "windowsProfile": null,
  "workloadRuntime": null
}
```
```bash
anuroop [ ~ ]$ az aks command invoke   -g rg-secure-dev-platform   -n private-aks-cluster   --command "kubectl get nodes -owide"
command started at 2026-02-17 08:50:30+00:00, finished at 2026-02-17 08:50:30+00:00 with exitcode=0
NAME                                STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-26280851-vmss000000   Ready    <none>   26m     v1.33.6   10.40.1.5     <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-1
aks-nodepool1-26280851-vmss000001   Ready    <none>   26m     v1.33.6   10.40.1.6     <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-1
aks-userpool-88913394-vmss000000    Ready    <none>   2m41s   v1.33.6   10.40.1.7     <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-1

anuroop [ ~ ]$
```

#### Check for userpool nodes based on `kubernetes.azure.com/mode=user` label
```bash
anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get nodes --show-labels" | grep "kubernetes.azure.com/mode=user"
aks-userpool-88913394-vmss000000    Ready    <none>   5m41s   v1.33.6   agentpool=userpool,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=userpool,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=0830aa64-0bdd-11f1-862c-fab9cdba7a42,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=user,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-userpool-88913394-vmss000000,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
anuroop [ ~ ]
```

#### Add taint to SYSTEM nodepool
**To dedicate Azure Kubernetes Service (AKS) nodes specifically for system workloads, apply the taint CriticalAddonsOnly=true:NoSchedule to the node pool. This key-value pair prevents non-system application pods from scheduling on these nodes, ensuring resource availability for critical system components like CoreDNS and metrics-server.**
```bash
az aks nodepool update \
  --resource-group rg-secure-dev-platform \
  --cluster-name private-aks-cluster \
  --name nodepool1 \
  --node-taints CriticalAddonsOnly=true:NoSchedule
```
This tells Kubernetes:
```bash
Only critical system pods allowed here.
```

#### Verify taints applied
```bash
anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl describe node | grep -i Taints"
command started at 2026-02-17 08:57:23+00:00, finished at 2026-02-17 08:57:24+00:00 with exitcode=0
Taints:             CriticalAddonsOnly=true:NoSchedule
Taints:             CriticalAddonsOnly=true:NoSchedule
Taints:             <none>

anuroop [ ~ ]
```

See, systempool nodes are added with `CriticalAddonsOnly` taint.

#### 🤖 Why system pods still run there automatically
AKS core components like:
```bash
coredns
azure-cni
policy agents
metrics agents
```

already include tolerations like:
```bash
tolerations:
- key: CriticalAddonsOnly
  operator: Exists
```
#### Deploy a test workload
Check that, application workload related pods are deployed only into userpool nodes.
```bash
anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl create deployment nginx-test --image=nginx"
command started at 2026-02-17 08:58:43+00:00, finished at 2026-02-17 08:58:43+00:00 with exitcode=0
deployment.apps/nginx-test created

anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get pods -owide"
command started at 2026-02-17 08:59:23+00:00, finished at 2026-02-17 08:59:23+00:00 with exitcode=0
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE                               NOMINATED NODE   READINESS GATES
nginx-test-b548755db-tmfbw   1/1     Running   0          40s   10.244.2.50   aks-userpool-88913394-vmss000000   <none>           <none>

anuroop [ ~ ]$
```

#### Deploy Application workload only into userpool nodes through nodeAffinity/nodeSelectors
Check for nodes with labels assigned with their respective nodePool names:
```bash
anuroop [ ~ ]$ az aks command invoke   -g rg-secure-dev-platform   -n private-aks-cluster   --command "kubectl get nodes --show-labels" | grep -E "kubernetes.azure.com/agentpool=nodepool1|kubernetes.azure.com/agentpool=userpool"

aks-nodepool1-26280851-vmss000000   Ready    <none>   45m   v1.33.6   agentpool=nodepool1,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=nodepool1,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=1254a542-0bd9-11f1-a68e-da560e449a7a,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=system,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-nodepool1-26280851-vmss000000,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
aks-nodepool1-26280851-vmss000001   Ready    <none>   45m   v1.33.6   agentpool=nodepool1,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=nodepool1,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=1254a542-0bd9-11f1-a68e-da560e449a7a,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=system,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-nodepool1-26280851-vmss000001,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
aks-userpool-88913394-vmss000000    Ready    <none>   21m   v1.33.6   agentpool=userpool,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_D2s_v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=centralindia,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=userpool,kubernetes.azure.com/azure-cni-overlay=true,kubernetes.azure.com/cluster=MC_rg-secure-dev-platform_private-aks-cluster_centralindia,kubernetes.azure.com/consolidated-additional-properties=0830aa64-0bdd-11f1-862c-fab9cdba7a42,kubernetes.azure.com/kubelet-identity-client-id=bef71225-9b42-4753-9c8f-c7265f18a806,kubernetes.azure.com/kubelet-serving-ca=cluster,kubernetes.azure.com/localdns-state=disabled,kubernetes.azure.com/mode=user,kubernetes.azure.com/network-name=aks-secure-vnet,kubernetes.azure.com/network-resourcegroup=rg-secure-dev-platform,kubernetes.azure.com/network-stateless-cni=false,kubernetes.azure.com/network-subnet=aks-node-subnet,kubernetes.azure.com/network-subscription=0de45914-fbf7-47ae-825b-0412d64bfa4f,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202601.27.0,kubernetes.azure.com/nodenetwork-vnetguid=3291920f-5dd1-4748-9b7b-251de96222c2,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku-effective=Ubuntu2204,kubernetes.azure.com/os-sku-requested=Ubuntu,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/podnetwork-type=overlay,kubernetes.azure.com/role=agent,kubernetes.azure.com/sku-cpu=2,kubernetes.azure.com/sku-memory=8192,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-userpool-88913394-vmss000000,kubernetes.io/os=linux,node.kubernetes.io/instance-type=Standard_D2s_v3,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=centralindia,topology.kubernetes.io/zone=0
anuroop [ ~ ]$
```

#### Create a workload that targets USERPOOL
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-userpool
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-userpool
  template:
    metadata:
      labels:
        app: nginx-userpool
    spec:
      nodeSelector:
        kubernetes.azure.com/agentpool: userpool  # using nodeSelector to deploy into userPool
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF"
```
#### Verify scheduling
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get pods -o wide"
```

#### AKS Networking
```bash
Outbound type: Load Balancer
Pod CIDR: 10.244.0.0/16
Service CIDR: 10.0.0.0/16
DNS service IP: 10.0.0.10
AKS Vnet CIDR: 10.40.0.0/16
AKS nodesPool CIDR: 10.40.1.0/24
```

```bash
anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get pods -o wide"
command started at 2026-02-17 09:12:06+00:00, finished at 2026-02-17 09:12:07+00:00 with exitcode=0
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                               NOMINATED NODE   READINESS GATES
nginx-test-b548755db-tmfbw        1/1     Running   0          13m   10.244.2.50    aks-userpool-88913394-vmss000000   <none>           <none>
nginx-userpool-867c75b8d6-slwf4   1/1     Running   0          19s   10.244.2.134   aks-userpool-88913394-vmss000000   <none>           <none>

anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl expose deployment nginx-userpool --port=80 --target-port=80 --type=ClusterIP"
command started at 2026-02-17 09:30:59+00:00, finished at 2026-02-17 09:30:59+00:00 with exitcode=0
service/nginx-userpool exposed

anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get svc"
command started at 2026-02-17 09:31:24+00:00, finished at 2026-02-17 09:31:25+00:00 with exitcode=0
NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes       ClusterIP   10.0.0.1      <none>        443/TCP   71m
nginx-userpool   ClusterIP   10.0.62.229   <none>        80/TCP    26s

anuroop [ ~ ]$
```
**Notice how podIP, serviceIP and nodeIP ranges are completely different and these serviceIP ranges are coming from azure overlay CNI, which are different from out vnet subents CIDR ranges.**

*Note: Right now, the service is only Internal to AKS*

#### expose service INSIDE your VNet
Instead of making it public, we’ll create:
```bash
Internal LoadBalancer
```

This gives:
```bash
Private IP inside your VNet
```

#### Convert service of type ClusterIP to INTERNAL LoadBalancer
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl annotate svc nginx-userpool service.beta.kubernetes.io/azure-load-balancer-internal=true"
```

Then patch service type:
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl patch svc nginx-userpool -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
```

#### Watch for private IP allocation
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get svc -w"
```

#### Assign AKS `Network contributor` role to create a Loadbalancer inside vnet under specific subnet
```bash
anuroop [ ~ ]$ az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl describe svc nginx-userpool"
command started at 2026-02-17 09:46:33+00:00, finished at 2026-02-17 09:46:33+00:00 with exitcode=0
Name:                     nginx-userpool
Namespace:                default
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=nginx-userpool
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.62.229
IPs:                      10.0.62.229
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30228/TCP
Endpoints:                10.244.2.134:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:
  Type     Reason                  Age                From                Message
  ----     ------                  ----               ----                -------
  Normal   EnsuringLoadBalancer    43s (x8 over 11m)  service-controller  Ensuring load balancer
  Warning  SyncLoadBalancerFailed  41s (x8 over 11m)  service-controller  Error syncing load balancer: failed to ensure load balancer: GET http://localhost:7788/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet
--------------------------------------------------------------------------------
RESPONSE 403: 403 Forbidden
ERROR CODE: AuthorizationFailed
--------------------------------------------------------------------------------
{
  "error": {
    "code": "AuthorizationFailed",
    "message": "The client '8ae65eee-c2a2-4402-8945-6b2bb874361a' with object id '412443c4-b386-40b7-a09a-7f4e78c7be81' does not have authorization to perform action 'Microsoft.Network/virtualNetworks/subnets/read' over scope '/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet' or the scope is invalid. If access was recently granted, please refresh your credentials."
  }
}
--------------------------------------------------------------------------------

anuroop [ ~ ]$ AKS_MI=$(az aks show \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --query identity.principalId -o tsv)

echo $AKS_MI
412443c4-b386-40b7-a09a-7f4e78c7be81
anuroop [ ~ ]$ SUBNET_ID=$(az network vnet subnet show \
  -g rg-secure-dev-platform \
  --vnet-name aks-secure-vnet \
  -n aks-node-subnet \
  --query id -o tsv)

echo $SUBNET_ID
/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet
anuroop [ ~ ]$ az role assignment create \
  --assignee $AKS_MI \
  --role "Network Contributor" \
  --scope $SUBNET_ID
{
  "condition": null,
  "conditionVersion": null,
  "createdBy": null,
  "createdOn": "2026-02-17T09:49:40.568654+00:00",
  "delegatedManagedIdentityResourceId": null,
  "description": null,
  "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet/providers/Microsoft.Authorization/roleAssignments/71255f55-2ff4-4b9b-8d0f-bab9ea5f7f2a",
  "name": "71255f55-2ff4-4b9b-8d0f-bab9ea5f7f2a",
  "principalId": "412443c4-b386-40b7-a09a-7f4e78c7be81",
  "principalType": "ServicePrincipal",
  "resourceGroup": "rg-secure-dev-platform",
  "roleDefinitionId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7",
  "scope": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet",
  "type": "Microsoft.Authorization/roleAssignments",
  "updatedBy": "8507ed11-d79b-4641-974b-8655c027e27f",
  "updatedOn": "2026-02-17T09:49:40.909654+00:00"
}
anuroop [ ~ ]$
```
AKS created LB:
```bash
anuroop [ ~ ]$ az network lb list -g MC_rg-secure-dev-platform_private-aks-cluster_centralindia -o table
Location      Name                 ProvisioningState    ResourceGroup                                               ResourceGuid
------------  -------------------  -------------------  ----------------------------------------------------------  ------------------------------------
centralindia  kubernetes           Succeeded            MC_rg-secure-dev-platform_private-aks-cluster_centralindia  91c07f6f-cfb2-4f6a-a5d2-1daee887f261
centralindia  kubernetes-internal  Succeeded            mc_rg-secure-dev-platform_private-aks-cluster_centralindia  296d0263-7d26-4706-a66a-4a0185025514
anuroop [ ~ ]$
```
**MC_rg-secure-dev-platform_private-aks-cluster_centralindia is an resourceGroup created to keep the AKS networking and Infrastructure related components separate from resoruceGroup where actually AKS is created**


#### Now, Allow AKS to make changes at subnet level
```bash
anuroop [ ~ ]$ PRINCIPAL_ID=$(az aks show \
    --resource-group "rg-secure-dev-platform" \
    --name "private-aks-cluster" \
    --query "identity.principalId" -o tsv)
anuroop [ ~ ]$ VNET_ID=$(az network vnet subnet show \
    --resource-group "rg-secure-dev-platform" \
    --vnet-name "aks-secure-vnet" \
    --name "aks-node-subnet" \
    --query id -o tsv)
anuroop [ ~ ]$ az aks show \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --query identity.principalId -o tsv
412443c4-b386-40b7-a09a-7f4e78c7be81
anuroop [ ~ ]$ az network vnet subnet show \
  -g rg-secure-dev-platform \
  --vnet-name aks-secure-vnet \
  -n aks-node-subnet \
  --query id -o tsv
/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet
anuroop [ ~ ]$ az role assignment create \
  --assignee-object-id 412443c4-b386-40b7-a09a-7f4e78c7be81 \
  --assignee-principal-type ServicePrincipal \
  --role "Network Contributor" \
  --scope "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet"
{
  "condition": null,
  "conditionVersion": null,
  "createdBy": "8507ed11-d79b-4641-974b-8655c027e27f",
  "createdOn": "2026-02-17T09:49:40.909654+00:00",
  "delegatedManagedIdentityResourceId": null,
  "description": null,
  "id": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet/providers/Microsoft.Authorization/roleAssignments/71255f55-2ff4-4b9b-8d0f-bab9ea5f7f2a",
  "name": "71255f55-2ff4-4b9b-8d0f-bab9ea5f7f2a",
  "principalId": "412443c4-b386-40b7-a09a-7f4e78c7be81",
  "principalName": "8ae65eee-c2a2-4402-8945-6b2bb874361a",
  "principalType": "ServicePrincipal",
  "resourceGroup": "rg-secure-dev-platform",
  "roleDefinitionId": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7",
  "roleDefinitionName": "Network Contributor",
  "scope": "/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet",
  "type": "Microsoft.Authorization/roleAssignments",
  "updatedBy": "8507ed11-d79b-4641-974b-8655c027e27f",
  "updatedOn": "2026-02-17T09:49:40.909654+00:00"
}
anuroop [ ~ ]$ az network vnet subnet show   -g rg-secure-dev-platform   --vnet-name aks-secure-vnet   -n aks-node-subnet   --query id -o tsv
/subscriptions/0de45914-fbf7-47ae-825b-0412d64bfa4f/resourceGroups/rg-secure-dev-platform/providers/Microsoft.Network/virtualNetworks/aks-secure-vnet/subnets/aks-node-subnet
anuroop [ ~ ]$ az aks command invoke   -g rg-secure-dev-platform   -n private-aks-cluster   --command "kubectl get svc"
command started at 2026-02-17 10:06:12+00:00, finished at 2026-02-17 10:06:12+00:00 with exitcode=0
NAME             TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
kubernetes       ClusterIP      10.0.0.1      <none>        443/TCP        106m
nginx-userpool   LoadBalancer   10.0.62.229   10.40.1.8     80:30228/TCP   35m

anuroop [ ~ ]$
```

*Notice, that now service Got an ExternalIP from our subnet range*

#### 🧱 Full traffic flow now
```bash
Client inside VNet
      ↓
Internal LB (10.40.1.x)
      ↓
Service (ClusterIP)
      ↓
nginx pod (overlay network)
```


**If we create externalIP for each service, the architecture becomes messy and we have to pay for each loadBalancer we create for each of our application services inside AKS. So That;s why we make use ApplicationGateway(L7)**


#### Application Gateway which as IngressController
```bash
  Public HTTPS
      ↓
Application Gateway (L7)
      ↓
Internal LoadBalancer (L4)  ← keep this
      ↓
nginx service
      ↓
pods


```
* Create Public IP for Gateway
```bash
az network public-ip create \
  -g rg-secure-dev-platform \
  -n appgw-public-ip \
  --sku Standard \
  --allocation-method Static
```


* Create ingress subnet:
```bash
az network vnet subnet create \
  -g rg-secure-dev-platform \
  --vnet-name aks-secure-vnet \
  -n aks-ingress-subnet \
  --address-prefixes 10.40.2.0/24
```

* Create PRIVATE frontend IP config
```bash
az network application-gateway create \
  -g rg-secure-dev-platform \
  -n secure-appgw \
  --location centralindia \
  --vnet-name aks-secure-vnet \
  --subnet aks-ingress-subnet \
  --capacity 1 \
  --sku Standard_v2 \
  --public-ip-address appgw-public-ip \
  --private-ip-address 10.40.2.10
  --priority 100
```

Choose any free IP inside for assigning to AppGateway:
```bash
10.40.2.0/24
```
* Upload Your PFX Certificate
```bash
az network application-gateway ssl-cert create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n nginx-ssl-cert \
  --cert-file <path-to-your.pfx> \
  --cert-password "<PFX_PASSWORD>"
```

* Create HTTPS frontend port
```bash
az network application-gateway frontend-port create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n https-port \
  --port 443
```
* Create HTTPS Listener (PUBLIC frontend)
```bash
az network application-gateway http-listener create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n https-listener \
  --frontend-ip appGatewayFrontendIP \
  --frontend-port https-port \
  --ssl-cert nginx-ssl-cert

```

* Get nginx Internal LB IP
```bash
az aks command invoke \
  -g rg-secure-dev-platform \
  -n private-aks-cluster \
  --command "kubectl get svc nginx-userpool"

```
Expected sample Output:
```bash
NAME             TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
nginx-userpool   LoadBalancer   10.0.62.229   10.40.1.8     80:30228/TCP   107m
```

* Create Backend Pool pointing to AKS
```bash
az network application-gateway address-pool create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n aks-backend-pool \
  --servers 10.40.1.12
```

* Backend HTTP settings
```bash
az network application-gateway http-settings create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n aks-http-settings \
  --port 80 \
  --protocol Http
```

* Create Routing Rule
```bash
az network application-gateway rule create \
  -g rg-secure-dev-platform \
  --gateway-name secure-appgw \
  -n nginx-rule \
  --http-listener https-listener \
  --rule-type Basic \
  --address-pool aks-backend-pool \
  --http-settings aks-http-settings
  --priority 200
```
* Get public IP:
```bash
az network public-ip show \
  -g rg-secure-dev-platform \
  -n appgw-public-ip \
  --query ipAddress -o tsv
```

* Our App Gateway now has two entry doors:
```bash
Public Frontend IP   → Internet traffic
Private Frontend IP  → VNet-internal traffic
```