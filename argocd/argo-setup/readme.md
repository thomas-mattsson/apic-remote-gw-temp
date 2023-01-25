Settings needed for the ArgoCD operator and ArgoCD instance needed for managing the Datapower operators.

## Operator

ArgoCD needs to be installed cluster-wide so the following part is needed in the subscription object for the ArgoCD operator:

```yaml
spec:
  channel: alpha
  config:
    env:
      - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
        value: argocd
```

## Operand (ArgoCD)

The application instance label needs to be changed as it conflicts with the datapower operator:

```yaml
applicationInstanceLabelKey: argocd.argoproj.io/instance
```

To correctly show the DatapowerService CRD object as healthy when running, the following resource customization needs to be added:

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
```

Optional: To allow ingress through a load balancer (assuming cloud vendor infrastructure provides automatic provisioning):

```yaml
server:      
  service:
    type: LoadBalancer
```
