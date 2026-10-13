# Install notes

How the cluster was installed on 2026-10-13, in the order it happened. Written so I can repeat it on a rebuild.

## What was used

| Item | Details |
| --- | --- |
| Node | Beelink EQi13: Intel Core i5-13420H (8 cores / 12 threads), 16 GB DDR4, 500 GB NVMe, dual 2.5 GbE |
| Admin machine | MacBook Air (Apple Silicon) with `oc`, Git and Ansible from Homebrew |
| Installer | Assisted Installer in the Red Hat Hybrid Cloud Console |
| Subscription | Red Hat Developer Subscription for Individuals (personal account) |
| Boot media | 16 GB USB stick, written with `dd` |
| Temporary | TV and USB keyboard for the BIOS and booting from USB |

The node meets Red Hat's single-node minimum (4 vCPUs, 16 GB RAM, 120 GB disk) as shipped, with no hardware changes.

## 1. Prepare the Mac

```bash
brew install openshift-cli ansible git
ssh-keygen -t ed25519 -C "sno homelab"     # passphrase saved in password manager
```

## 2. Prepare the node

1. Connected the Beelink to the router by Ethernet, plus a TV and keyboard.
2. BIOS (Delete at startup): confirmed 16384 MB of memory and the NVMe drive, and that Intel VT-x and VT-d were enabled. Left graphics memory at its default.

## 3. Network and DNS

See [network.md](network.md) for the values. In short:

1. Reserved `192.168.1.82` for the Beelink's wired port in the My Spectrum app (no port forwarding).
2. Created three A records in Cloudflare for `adelledonne-lab.com` (`api.sno`, `api-int.sno`, `*.apps.sno`), all pointing to `192.168.1.82`, proxy off.
3. Verified with [`scripts/check-dns.sh`](../scripts/check-dns.sh).

## 4. Create the cluster

In the Hybrid Cloud Console: **Create cluster → Datacenter → Assisted Installer**.

| Setting | Value |
| --- | --- |
| Cluster name | `sno` |
| Base domain | `adelledonne-lab.com` |
| Version | OpenShift 4.22 (installed 4.22.17) |
| CPU architecture | x86_64 |
| Control plane nodes | 1 |
| Host network configuration | DHCP only |
| Operators | None |

## 5. Discovery ISO and boot

1. **Add host** → Full image file → pasted the Mac's SSH public key → downloaded the ISO.
2. Wrote it to the USB stick from Terminal (balenaEtcher failed, see [troubleshooting](troubleshooting.md)):

   ```bash
   diskutil list                                   # find the external, physical disk
   diskutil unmountDisk /dev/diskN
   sudo dd if=$HOME/Downloads/discovery.iso of=/dev/rdiskN bs=4m
   diskutil eject /dev/diskN
   ```

3. Booted the Beelink from the USB stick (F7 boot menu → `VendorCo` entry).
4. The host appeared in the console. Renamed it to `sno-node` (hostnames must be lowercase).

## 6. Install

1. Storage: installation disk = the 500 GB NVMe drive.
2. Networking: machine network `192.168.1.0/24`.
3. **Install cluster.** Removed the USB stick when the host reached **Rebooting**.
4. Total time from clicking install to "Installation successful": about 40 minutes.

## 7. After install

```bash
mkdir -p ~/.kube
mv ~/Downloads/kubeconfig ~/.kube/config
chmod 600 ~/.kube/config
oc get nodes
oc get clusteroperators
oc adm top nodes
```

- kubeadmin password and a backup copy of the kubeconfig stored in a password manager.
- Web console reached at `https://console-openshift-console.apps.sno.adelledonne-lab.com` (self-signed certificate warning expected).

Baseline right after install:

| CPU | Memory |
| --- | --- |
| 446m (3%) | 10,554 Mi (72%) |

## Still to do

- [ ] Switch the cluster from the 60-day evaluation to the Developer subscription (waiting for the cluster to report in to the Hybrid Cloud Console)
- [ ] Weekend 2: OpenShift GitOps
