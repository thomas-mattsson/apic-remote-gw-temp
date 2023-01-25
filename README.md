# apic-remote-gw
Gitops config for deploying API Connect gateway and analytics

## Secrets needed
Replace <password> with something hard to guess

`kubectl create secret generic admin-credentials --from-literal=password=<password> -n datapower`
