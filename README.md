# apic-remote-gw
Gitops config for deploying API Connect gateway and analytics

## ArgoCD

If Argo CD is used see details in
[argocd/setup/README.md](argocd/setup/README.md)

## Secrets needed
Replace <password> with something hard to guess

`kubectl create secret generic admin-credentials --from-literal=password=<password> -n datapower`
