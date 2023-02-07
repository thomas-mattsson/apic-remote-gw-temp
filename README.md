# apic-remote-gw

Gitops config for deploying API Connect gateway and analytics

## Preparing a fresh Kubernetes environment

Log into the cluster so you can use `kubectl` against it.

### Install OLM

Datapower and API connect are installed through operators so we need OLM to be installed. First of all `operator-sdk` CLI tool is needed. For MacOS it can be installed with `brew install operator-sdk`, otherwise see here: <https://sdk.operatorframework.io/docs/installation/>

Install OLM by running `operator-sdk olm install`. For details see here: <https://olm.operatorframework.io/docs/getting-started/>

### ArgoCD

We are using ArgoCD to deploy the remote gateway and the necessary components. Optionally everything can be installed using Kustomize instead.

If Argo CD is used see details in [argocd/argo-setup/README.md](argocd/argo-setup/README.md)

## Secrets needed

Replace `<password>` with something hard to guess

`kubectl create secret generic admin-credentials --from-literal=password=<password> -n datapower`

Add the API manager CA following these instructions:

1. Extract the CA from the API manager endpoint and rename it to api-manager.crt
2. Add the CA into a secret using the following command

`kubectl create secret generic apimanager-ca --from-file=./api-manager.crt -n datapower`
