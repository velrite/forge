# Lessons Learned

- **Wrapped cloud error messages are frequently misleading.** More than
  one incident in this project was only correctly diagnosed after
  bypassing the high-level error text and inspecting the raw HTTP
  request/response underneath it (`--log-http` on `gcloud`, or
  Prometheus's own generated scrape config rather than the
  `ServiceMonitor` spec that produced it). The stated error and the
  actual cause were not always the same thing.

- **IAM roles that sound related are not interchangeable.**
  `storage.objectAdmin`, `storage.objectViewer`, and `storage.admin`
  differ specifically in whether they include bucket-level (as opposed
  to object-level) permissions — a distinction that cost real debugging
  time before it was understood, not before it was looked up.

- **`kubectl`'s client-side and server-side apply are not
  interchangeable for large objects.** This is a hard platform limit
  (a fixed annotation-size ceiling), not a configuration mistake, and
  the correct response is to change the apply mechanism, not to keep
  retrying the same command.

- **Two independent identity states must both be checked, always.**
  `gcloud`'s active project and `kubectl`'s active cluster context are
  separate pieces of state that do not imply each other. Verifying one
  says nothing about the other, and this was the direct cause of at
  least one incident where commands were run against the wrong cluster
  entirely.

- **Scheduling is about requested resources, not actual usage.** A
  cluster can report low CPU/memory utilization via `kubectl top nodes`
  while still being unable to schedule a new pod, because Kubernetes
  reasons about requested capacity, not live usage. This is standard
  Kubernetes behavior, not specific to this project, but it is easy to
  misdiagnose the first time it's encountered.

- **A local, minimal reproduction is faster than iterating against a
  full CI pipeline.** Once IAM debugging moved to using
  `--impersonate-service-account` locally instead of triggering a full
  GitLab pipeline run per attempt, iteration speed improved
  substantially — this became the standard approach for the remainder
  of the build.
