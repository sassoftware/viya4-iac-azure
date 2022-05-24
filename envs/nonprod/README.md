# Setting up SAS Infrastructure


## Export environment variables (TF_VAR_...)

    $ export TF_VAR_tenant_id=
    $ export TF_VAR_client_id=
    $ export TF_VAR_client_secret=
    $ export TF_VAR_subscription_id=


## Apply the Terraform

    $ terraform init    -var-file ./envs/nonprod/input.tfvars
    $ terraform plan    -var-file ./envs/nonprod/input.tfvars -no-color > plan
    $ terraform apply   -var-file ./envs/nonprod/input.tfvars

## Install cert-manager

    $ kubectl create namespace cert-manager
    $ helm repo add jetstack https://charts.jetstack.io
    $ helm repo update
    $ helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --version v1.1.0  \
        --set installCRDs=true \
        --set extraArgs={"--enable-certificate-owner-ref"="true"}

## Configure cert-manager

    $ cd envs/nonprod/cert-manager
    $ kubectl apply -f secret.yaml
    $ kubectl apply -f clusterissuer-hvault.yaml
    
    $ kubectl get issuers vault-issuer -n cert-manager -o wide # Check

## Install nginx ingress controller
    $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    $ helm repo update
<!-- ingress-nginx-3.39.0 -->
<!-- kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.49.3/deploy/static/provider/cloud/deploy.yaml -->
    $ export VIP_STATIC_IP=
    $ helm install nginx-ingress ingress-nginx/ingress-nginx \
        --version 3.39.0 \
        --namespace ingress-basic --create-namespace \
        --set controller.replicaCount=2 \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.loadBalancerIP=$VIP_STATIC_IP \
        --set controller.service.targetPorts.http=80 \
        --set controller.service.targetPorts.https=443 \
        --set controller.service.externalTrafficPolicy=Local \
        --set controller.service.nodePorts.http=31671 \
        --set controller.service.nodePorts.https=31231 \
        --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
        --set controller.extraArgs.enable-ssl-passthrough=true \
        --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux 

## Destroy the infrastructure

    $ terraform destroy -var-file ./envs/nonprod/input.tfvars
