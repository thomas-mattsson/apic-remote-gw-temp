# apic-remote-gw
Gitops config for deploying API Connect gateway and analytics

## ArgoCD

If Argo CD is used see details in
[argocd/argo-setup/README.md](argocd/argo-setup/README.md)

## Secrets needed
Replace <password> with something hard to guess

`kubectl create secret generic admin-credentials --from-literal=password=<password> -n datapower`

Add the API manager CA following these instructions:

1. Extract the CA from the API manager endpoint and rename it to api-manager.crt
2. Add the CA into a secret using the following command

`kubectl create secret generic apimanager-ca --from-file=./api-manager.crt -n datapower`
