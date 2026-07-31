# Releasechannel (Public Example)

A minimal, functioning example of a **releasechannel** — a versioned manifest of platform components managed as [OCM (Open Component Model)](https://ocm.software/) descriptors.

Use this as a template for your own platform to declare which versions of infrastructure components are approved for deployment.

## What's in this releasechannel

| Component | Source |
|-----------|--------|
| Crossplane | [charts.crossplane.io](https://charts.crossplane.io/stable) |
| provider-kubernetes | [xpkg.upbound.io](https://marketplace.upbound.io/providers/crossplane-contrib/provider-kubernetes) |
| provider-helm | [xpkg.upbound.io](https://marketplace.upbound.io/providers/crossplane-contrib/provider-helm) |
| function-auto-ready | [xpkg.upbound.io](https://marketplace.upbound.io/functions/upbound/function-auto-ready) |
| function-patch-and-transform | [xpkg.upbound.io](https://marketplace.upbound.io/functions/crossplane-contrib/function-patch-and-transform) |
| function-go-templating | [xpkg.upbound.io](https://marketplace.upbound.io/functions/crossplane-contrib/function-go-templating) |
| External Secrets Operator | [charts.external-secrets.io](https://charts.external-secrets.io) |
| Flux | [fluxcd-community](https://fluxcd-community.github.io/helm-charts) |
| kro | [registry.k8s.io](https://kro.run/) |
| Kyverno | [kyverno.github.io](https://kyverno.github.io/kyverno/) |
| Velero | [vmware-tanzu](https://vmware-tanzu.github.io/helm-charts) |

## Repository structure

```
.
├── VERSION                         # Releasechannel version (semver)
├── Taskfile.yaml                   # Build tasks (requires: task, ocm, yq)
├── components/
│   ├── crossplane.yaml             # Crossplane helm chart + image
│   ├── provider-kubernetes.yaml    # Crossplane provider packages
│   ├── provider-helm.yaml
│   ├── function-auto-ready.yaml    # Crossplane composition functions
│   ├── function-patch-and-transform.yaml
│   ├── function-go-templating.yaml
│   ├── external-secrets-operator.yaml  # ESO helm chart + image
│   ├── flux.yaml                   # Flux helm chart
│   ├── kro.yaml                    # kro OCI helm chart
│   ├── kyverno.yaml                # Kyverno helm chart + image
│   ├── velero.yaml                 # Velero helm chart + image
│   └── releasechannel.yaml         # Top-level component referencing all others
└── README.md
```

## How it works

Each file in `components/` is an OCM component descriptor. The `releasechannel.yaml` is the top-level component that references all others — it acts as the "bill of materials" for your platform at a given version.

The descriptors use variable substitution (`${OCM_COMPONENT_PREFIX}`, `${VERSION}`, etc.) so they can be built for any organization or registry.

## Prerequisites

- [task](https://taskfile.dev/) (task runner)
- [ocm](https://ocm.software/docs/getting-started/installing-the-ocm-cli/) (OCM CLI)
- [yq](https://github.com/mikefarah/yq) (YAML processor)

## Usage

### Configure for your organization

Edit `Taskfile.yaml` and replace the placeholder values:

```yaml
vars:
  OCM_COMPONENT_PREFIX: "github.com/openmcp-project/releasechannel"
  OCM_COMPONENT_PROVIDER: "openmcp-project"
  OCM_TARGET_REPO: "ghcr.io/openmcp-project/ocm"
```

### Build

```bash
task build
```

This merges all component descriptors and builds an OCM Common Transport Format (CTF) archive in `.ctf/`.

### Inspect

```bash
task ocm:inspect
```

### Publish to an OCI registry

```bash
task ocm:publish
```

### Clean

```bash
task clean
```

## Adding a component

1. Create a new YAML file in `components/` following the existing pattern
2. Add a `componentReference` entry in `components/releasechannel.yaml`
3. Bump `VERSION`
4. Run `task build`

### Component types

**Helm Chart** (chart + container image):
```yaml
components:
  - name: ${OCM_COMPONENT_PREFIX}/my-component
    version: v1.0.0
    provider:
      name: ${PROVIDER}
    resources:
      - name: my-component
        version: v1.0.0
        type: helmChart
        access:
          type: helm
          helmChart: my-chart:1.0.0
          helmRepository: https://charts.example.io/stable
      - name: image-my-component
        version: v1.0.0
        type: ociImage
        access:
          type: ociArtifact
          imageReference: registry.example.io/my-component:v1.0.0
```

**OCI Image** (provider/function package):
```yaml
components:
  - name: ${OCM_COMPONENT_PREFIX}/my-provider
    version: v1.0.0
    provider:
      name: ${PROVIDER}
    resources:
      - name: my-provider
        version: v1.0.0
        type: ociImage
        access:
          type: ociArtifact
          imageReference: xpkg.upbound.io/org/my-provider:v1.0.0
```

## Updating versions

Edit the version in the component file directly, update the reference in `releasechannel.yaml`, and bump `VERSION`. No code generation needed — the descriptors are the source of truth.

## License

Apache-2.0
