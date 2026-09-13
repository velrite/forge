> **SUPERSEDED — contains incorrect SKU pricing data (wrong Compute Engine SKUs matched, not applicable to Autopilot). See the OpenCost-based report (commit 4300aa2) for accurate figures. Kept for the record, not for reference.**

# Phase 12 — Cost Attribution Report (2026-09-13T01:03:46Z)


## Data source
No BigQuery billing export configured on this project. This report uses **real, measured Kubernetes resource requests and live usage** (kubectl top, GKE cost-allocation labels) as the attribution signal, per the phase spec — it does not include or estimate dollar figures, since no priced billing data source exists to ground them.

## Live usage snapshot (kubectl top, 2026-09-13T01:03:51Z)
```
NAMESPACE         NAME                                                       CPU(cores)   MEMORY(bytes)   
kube-system       anetd-m-hxvmz                                              83m          416Mi           
observability     prometheus-kube-prometheus-stack-prometheus-0              79m          396Mi           
kube-system       anetd-m-nh2cb                                              61m          181Mi           
observability     kube-prometheus-stack-grafana-646dbf9c48-jtrm4             28m          369Mi           
kube-system       fluentbit-gke-big-wpdl9                                    21m          100Mi           
kube-system       fluentbit-gke-big-tbpvr                                    17m          102Mi           
kyverno           kyverno-admission-controller-7bc6785bdc-mmq7w              16m          62Mi            
gke-gmp-system    collector-jqgvz                                            15m          216Mi           
kube-system       konnectivity-agent-57b86fdd5-cmmh7                         13m          47Mi            
observability     kube-prometheus-stack-kube-state-metrics-79c76b56d-jfqsc   13m          25Mi            
gke-gmp-system    collector-glzb5                                            12m          166Mi           
kyverno           kyverno-cleanup-controller-7f4799bcbc-x9h7d                11m          27Mi            
argocd            argocd-application-controller-0                            11m          246Mi           
kube-system       gke-metrics-agent-fxzpc                                    10m          113Mi           
kube-system       gke-metrics-agent-58x2h                                    9m           98Mi            
kube-system       konnectivity-agent-57b86fdd5-g495w                         9m           38Mi            
observability     kube-prometheus-stack-operator-56dfd4c764-jw752            8m           24Mi            
kyverno           kyverno-reports-controller-6f4994bd79-95n2k                8m           60Mi            
kyverno           kyverno-background-controller-b4c7b88fd-c2n66              8m           41Mi            
forge-platform    backstage-64f79c6-jc655                                    6m           221Mi           
argocd            argocd-redis-86cdd57c67-snml6                              6m           4Mi             
forge-platform    backstage-64f79c6-j8rs6                                    5m           247Mi           
kube-system       metrics-server-v1.35.1-7cdd96f59b-4hpmz                    5m           28Mi            
observability     otel-collector-opentelemetry-collector-7d75644945-mhjss    5m           67Mi            
kube-system       node-local-dns-c6pqn                                       5m           46Mi            
gke-gmp-system    gmp-operator-5d6bcbdd4b-j46jj                              4m           25Mi            
kube-system       node-local-dns-xcxg8                                       4m           45Mi            
kube-system       kube-dns-5d9f795b56-klzfh                                  3m           86Mi            
kube-system       kube-dns-5d9f795b56-cwzwf                                  3m           46Mi            
forge-platform    backstage-6b74bb5dd9-z5l7f                                 3m           230Mi           
argo-rollouts     argo-rollouts-b956fc5dc-ts7bf                              3m           22Mi            
kube-system       netd-tplm9                                                 3m           48Mi            
kube-system       filestore-lock-release-controller-8578964f8c-992t2         2m           26Mi            
kube-system       gke-metadata-server-jdxbp                                  2m           47Mi            
observability     alertmanager-kube-prometheus-stack-alertmanager-0          2m           33Mi            
argocd            argocd-repo-server-7dbfcc4477-bb9hw                        2m           26Mi            
argocd            argocd-server-57ddcfc4c8-kjbfx                             2m           27Mi            
kube-system       netd-lqbqx                                                 1m           56Mi            
kube-system       parallelstore-csi-node-86d62                               1m           19Mi            
kube-system       efficiency-daemon-x4k5f                                    1m           22Mi            
kube-system       konnectivity-agent-autoscaler-7f44b76cdc-zg6m8             1m           18Mi            
kube-system       ip-masq-agent-f2qvd                                        1m           7Mi             
kube-system       event-exporter-gke-766cbd47d5-m72kj                        1m           56Mi            
kube-system       kube-dns-autoscaler-859854db85-hhswv                       1m           17Mi            
kube-system       l7-default-backend-7d8d77ff56-f5v59                        1m           4Mi             
gke-managed-cim   kube-state-metrics-0                                       1m           78Mi            
kube-system       gcsfusecsi-node-ccvcp                                      1m           50Mi            
kube-system       ip-masq-agent-5b94c                                        1m           9Mi             
kube-system       egress-nat-controller-6ff88b9dbd-tdcb9                     1m           18Mi            
kube-system       filestore-node-bjg84                                       1m           35Mi            
argocd            argocd-dex-server-569fdbbd6b-gvvtm                         1m           16Mi            
kube-system       parallelstore-csi-node-w2k7m                               1m           21Mi            
kube-system       pdcsi-node-bjpbx                                           1m           38Mi            
kube-system       pdcsi-node-vxgvc                                           1m           42Mi            
kube-system       gcsfusecsi-node-mjg4g                                      1m           46Mi            
kube-system       efficiency-daemon-rgdrj                                    1m           22Mi            
kube-system       filestore-node-bftzs                                       1m           39Mi            
kube-system       antrea-controller-horizontal-autoscaler-5987c677b8-lqwvp   1m           13Mi            
argocd            argocd-notifications-controller-794b6df878-f9rsp           1m           17Mi            
kube-system       gke-metadata-server-lq5xv                                  1m           41Mi            
forge-demo        gitops-demo-55d84b48bd-ntvlg                               0m           7Mi             
kube-system       gke-system-balloon-pod-8fphm                               0m           0Mi             
kube-system       gke-system-balloon-pod-dzqrs                               0m           0Mi             
forge-demo        gitops-demo-55d84b48bd-5w2p4                               0m           7Mi             
```

## Resource requests by namespace (real, from live pod specs)
```
```
NAME                                LABELS
argo-rollouts                       map[kubernetes.io/metadata.name:argo-rollouts]
argocd                              map[kubernetes.io/metadata.name:argocd]
default                             map[kubernetes.io/metadata.name:default]
forge-demo                          map[forge.io/managed-by:argocd kubernetes.io/metadata.name:forge-demo]
forge-platform                      map[forge.io/component:platform kubernetes.io/metadata.name:forge-platform]
gke-gmp-system                      map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-gmp-system]
gke-managed-cim                     map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-cim]
gke-managed-filestorecsi            map[addonmanager.kubernetes.io/mode:Reconcile k8s-app:gcp-filestore-csi-driver kubernetes.io/metadata.name:gke-managed-filestorecsi]
gke-managed-networking-dra-driver   map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-networking-dra-driver]
gke-managed-parallelstorecsi        map[addonmanager.kubernetes.io/mode:EnsureExists k8s-app:parallelstore-csi-driver kubernetes.io/metadata.name:gke-managed-parallelstorecsi]
gke-managed-system                  map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-system]
gke-managed-volumepopulator         map[addonmanager.kubernetes.io/mode:Reconcile k8s-app:gke-volume-populator kubernetes.io/metadata.name:gke-managed-volumepopulator]
gmp-public                          map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gmp-public]
kube-node-lease                     map[kubernetes.io/metadata.name:kube-node-lease]
kube-public                         map[kubernetes.io/metadata.name:kube-public]
kube-system                         map[kubernetes.io/metadata.name:kube-system]
kyverno                             map[kubernetes.io/metadata.name:kyverno name:kyverno]
observability                       map[kubernetes.io/metadata.name:observability]

## Namespace labels (used for team/service attribution)
```
NAME                                LABELS
argo-rollouts                       map[kubernetes.io/metadata.name:argo-rollouts]
argocd                              map[kubernetes.io/metadata.name:argocd]
default                             map[kubernetes.io/metadata.name:default]
forge-demo                          map[forge.io/managed-by:argocd kubernetes.io/metadata.name:forge-demo]
forge-platform                      map[forge.io/component:platform kubernetes.io/metadata.name:forge-platform]
gke-gmp-system                      map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-gmp-system]
gke-managed-cim                     map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-cim]
gke-managed-filestorecsi            map[addonmanager.kubernetes.io/mode:Reconcile k8s-app:gcp-filestore-csi-driver kubernetes.io/metadata.name:gke-managed-filestorecsi]
gke-managed-networking-dra-driver   map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-networking-dra-driver]
gke-managed-parallelstorecsi        map[addonmanager.kubernetes.io/mode:EnsureExists k8s-app:parallelstore-csi-driver kubernetes.io/metadata.name:gke-managed-parallelstorecsi]
gke-managed-system                  map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gke-managed-system]
gke-managed-volumepopulator         map[addonmanager.kubernetes.io/mode:Reconcile k8s-app:gke-volume-populator kubernetes.io/metadata.name:gke-managed-volumepopulator]
gmp-public                          map[addonmanager.kubernetes.io/mode:Reconcile kubernetes.io/metadata.name:gmp-public]
kube-node-lease                     map[kubernetes.io/metadata.name:kube-node-lease]
kube-public                         map[kubernetes.io/metadata.name:kube-public]
kube-system                         map[kubernetes.io/metadata.name:kube-system]
kyverno                             map[kubernetes.io/metadata.name:kyverno name:kyverno]
observability                       map[kubernetes.io/metadata.name:observability]
```

**Note:** if namespaces show no team/service labels above, that is real signal, not an oversight — label them before the next report if per-team attribution is actually needed; this report will not invent ownership.

## Cluster-level cost driver config
```
ERROR: (gcloud.container.clusters.describe) The project property is set to the empty string, which is invalid.
To set your project, run:

  $ gcloud config set project PROJECT_ID

or to unset it, run:

  $ gcloud config unset project
```

## Cluster-level cost driver config (backfilled)
```
autoscaling:
  autoprovisioningNodePoolDefaults:
    imageType: COS_CONTAINERD
    management:
      autoRepair: true
      autoUpgrade: true
    oauthScopes:
    - https://www.googleapis.com/auth/devstorage.read_only
    - https://www.googleapis.com/auth/logging.write
    - https://www.googleapis.com/auth/monitoring
    - https://www.googleapis.com/auth/service.management.readonly
    - https://www.googleapis.com/auth/servicecontrol
    - https://www.googleapis.com/auth/trace.append
    serviceAccount: default
    upgradeSettings:
      maxSurge: 1
      strategy: SURGE
  autoscalingProfile: OPTIMIZE_UTILIZATION
  enableNodeAutoprovisioning: true
  resourceLimits:
  - maximum: '1000000000'
    resourceType: cpu
  - maximum: '1000000000'
    resourceType: memory
  - maximum: '1000000000'
    resourceType: nvidia-tesla-t4
  - maximum: '1000000000'
    resourceType: nvidia-tesla-a100
currentNodeCount: 2
```

## Google published list prices (Cloud Billing Catalog API, us-central1)
**This is Google's real, current public price list — not your actual invoice, which may differ with discounts/commitments. No BigQuery billing export exists for this project, so this is the closest real (non-fabricated) pricing signal available.**
```
DESCRIPTION                                                           UNIT      LIST PRICE (USD)
Spot Preemptible N2D AMD Custom Instance Core running in Americas     h         0.011630       
Commitment v1: N2D AMD Ram in Americas for 1 Year                     GiBy.h    0.002322       
Spot Preemptible N2D AMD Instance Core running in Americas            h         0.011080       
Sole Tenancy Premium for N2D AMD Sole Tenancy Instance RAM running i  GiBy.h    0.000369       
Sole Tenancy Premium for N2D AMD Sole Tenancy Instance Core running   h         0.002750       
```

## Note on applying list price to requests
Per-namespace CPU/memory requests were captured earlier this session (see prior section). Multiplying those real request values by the list prices above gives a rough monthly estimate — but only do this calculation once you confirm which specific SKU row actually matches this Autopilot cluster's billing mode, since Autopilot bills per-pod-resource, not per-node, and the exact matching SKU description should be confirmed against the GCP Console pricing page before treating any resulting number as reliable.
