# Settings needed for the ArgoCD operator and ArgoCD instance needed for managing the Datapower operators

## Operator

Apply the catalog source to the `olm` namespace as follows:

`kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/catalog_source.yaml -n olm`

Create the argocd namespace and add the operator group object to it as follows:

```bash
kubectl create namespace argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/operator_group.yaml -n argocd
```

ArgoCD needs to be installed cluster-wide so the following part is needed in the subscription object for the ArgoCD operator:

```yaml
spec:
  channel: alpha
  config:
    env:
      - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
        value: argocd
```

Apply the subscription with the change above as follows:

`kubectl apply -f https://raw.githubusercontent.com/Nordic-MVP-GitOps-Repos/apic-remote-gw/main/argocd/argo-setup/subscription.yaml -n operators`

## Operand (ArgoCD)

The application instance label needs to be changed as it conflicts with the datapower operator:

```yaml
applicationInstanceLabelKey: argocd.argoproj.io/instance
```

To correctly show the CRD types used in this project as healthy when running, the following resource customization needs to be added:

```yaml
  resourceCustomizations: |
    datapower.ibm.com/DataPowerService:
      health.lua: |
        hs = {}
        if obj.status ~= nil then
          if obj.status.phase ~= nil then
            hs.message = obj.status.phase
            if obj.status.phase == "Running" then
              hs.status = "Healthy"
            else
              hs.status = "Progressing"
            end
            return hs
          end
        end
    cert-manager.io/Certificate: |
      hs = {}
      if obj.status ~= nil then
        if obj.status.conditions ~= nil then
          for i, condition in ipairs(obj.status.conditions) do
            if condition.type == "Ready" and condition.status == "False" then
              hs.status = "Degraded"
              hs.message = condition.message
              return hs
            end
            if condition.type == "Ready" and condition.status == "True" then
              hs.status = "Healthy"
              hs.message = condition.message
              return hs
            end
          end
        end
      end

      hs.status = "Progressing"
      hs.message = "Waiting for certificate"
      return hs
```

There are two yaml files provided in this repo with the above changes applied. One exposing argocd through ingress and the other through a load balancer service.

To apply the above instance and exposing using ingress run the following command:

`kubectl apply -f https://raw.githubusercontent.com/Nordic-MVP-GitOps-Repos/apic-remote-gw/main/argocd/argo-setup/argocd-ingress.yaml -n argocd`

or by exposing it with a load balancer service run the following command:

`kubectl apply -f https://raw.githubusercontent.com/Nordic-MVP-GitOps-Repos/apic-remote-gw/main/argocd/argo-setup/argocd-lb.yaml -n argocd`
