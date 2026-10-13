# OpenShift Homelab

A bare-metal single-node OpenShift (SNO) cluster running on a mini PC at home, built and operated by Alyson DelleDonne. The goal is a small, real OpenShift environment I can install, configure, break, and rebuild in public, with every change tracked in this repo.

## At a glance

| | |
| --- | --- |
| Platform | Red Hat OpenShift Container Platform 4.22.17, single-node |
| Installer | Assisted Installer (Red Hat Hybrid Cloud Console) |
| Hardware | Beelink EQi13 mini PC: Intel Core i5-13420H (8 cores / 12 threads), 16 GB DDR4, 500 GB NVMe |
| Network | Home LAN, wired 2.5 GbE, reserved IP `192.168.1.82` |
| DNS | Public records in Cloudflare for `adelledonne-lab.com` pointing to the private IP |
| Exposure | Not reachable from the internet; no port forwarding |
| Installed | 2026-10-13 |

## Architecture

```mermaid
flowchart LR
    mac["MacBook Air<br/>oc, browser, Git"] -->|HTTPS 443 / API 6443| node
    subgraph home["Home network 192.168.1.0/24"]
        router["Spectrum router<br/>192.168.1.1<br/>DHCP reservation"]
        node["sno-node (Beelink EQi13)<br/>192.168.1.82<br/>OpenShift 4.22 SNO"]
        router --- node
    end
    mac -. DNS lookup .-> cf["Cloudflare DNS<br/>api / api-int / *.apps<br/>.sno.adelledonne-lab.com"]
    cf -. returns 192.168.1.82 .-> mac
    node -->|images, updates| internet["Red Hat registries<br/>and Hybrid Cloud Console"]
```

Endpoints:

- Web console: `https://console-openshift-console.apps.sno.adelledonne-lab.com`
- API: `https://api.sno.adelledonne-lab.com:6443`

Both resolve to a private address, so they only work from inside my home network.

## Baseline after install

Measured with `oc adm top nodes` right after installation, before adding anything:

| CPU | Memory |
| --- | --- |
| 446m (3%) | 10,554 Mi (72%) |

Memory is the constraint on 16 GB. I add operators one at a time and re-measure; if memory stays above roughly 85%, the plan is to upgrade the RAM.

## Roadmap

- [x] **Weekend 1:** Install single-node OpenShift with the Assisted Installer ([install notes](docs/install-notes.md))
- [ ] **Weekend 2:** OpenShift GitOps (Argo CD), cluster configuration managed from this repo, Ansible for post-install setup
- [ ] **Weekend 3:** Identity provider, remove `kubeadmin`, scoped RBAC roles and groups
- [ ] **Weekend 4:** NetworkPolicies between namespaces, TLS routes, NMState
- [ ] **Upgrade:** More RAM and a second NVMe drive, LVM Storage for persistent volumes
- [ ] **Weekend 5:** Compliance Operator scans; OpenShift Virtualization and VM migration
- [ ] **Weekend 6:** A small app deployed through GitOps with monitoring and alerts; wipe and rebuild from this repo, timed

## Repository layout

```
.
├── README.md            this page
├── docs/
│   ├── install-notes.md     how the cluster was installed, step by step
│   ├── network.md           IP, DNS records and router settings
│   ├── decisions.md         why things are set up the way they are
│   └── troubleshooting.md   problems hit during install and how they were fixed
├── scripts/
│   ├── check-dns.sh         verifies the three DNS names before install or rebuild
│   └── cluster-health.sh    quick health summary of the cluster
├── ansible/             post-install playbooks (weekend 2)
├── clusters/sno/        cluster configuration managed by Argo CD (weekend 2)
├── apps/                sample workloads
└── diagrams/            architecture and network diagrams
```

## Quick checks

```bash
./scripts/check-dns.sh        # before an install or rebuild
./scripts/cluster-health.sh   # any time, needs a working kubeconfig
```

## Security basics

- The cluster is not exposed to the internet. There is no port forwarding on the router.
- No credentials live in this repo. `.gitignore` excludes kubeconfigs, pull secrets and password files, and GitHub push protection is turned on.
- Cluster credentials are stored in a password manager on a FileVault-encrypted laptop.
- Cluster updates are applied every month or two.

## Lessons learned

The install took one afternoon and hit seven separate problems, from an uppercase hostname to a DNS service that answered too many names. Each one is written up with its cause and fix in [docs/troubleshooting.md](docs/troubleshooting.md).
