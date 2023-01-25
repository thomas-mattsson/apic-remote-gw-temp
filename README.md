# apic-remote-gw
Gitops config for deploying API Connect gateway and analytics

## ArgoCD

If Argo CD is used see details in
[argocd/argo-setup/README.md](argocd/argo-setup/README.md)

## Secrets needed
Replace <password> with something hard to guess

`kubectl create secret generic admin-credentials --from-literal=password=<password> -n datapower`
