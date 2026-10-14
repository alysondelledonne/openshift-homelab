# Troubleshooting log

Problems hit during the first install on 2026-10-13, with the cause and fix for each.

## 1. Base domain rejected as invalid

- **Symptom:** the Assisted Installer refused the base domain `192.168.1.82.nip.io`: *"domain name is not valid … and not be in dotted decimal format"*.
- **Cause:** the installer rejects domains that look like an IP address.
- **Fix:** nip.io also accepts dashes (`192-168-1-82.nip.io`), which passed this check. (It later failed a different one; see #6.)

## 2. balenaEtcher couldn't open the ISO

- **Symptom:** *"Error: (0, h.requestMetadata) is not a function"* when selecting the discovery ISO.
- **Cause:** a known balenaEtcher bug on macOS.
- **Fix:** wrote the ISO with `dd` instead:

  ```bash
  diskutil list
  diskutil unmountDisk /dev/diskN
  sudo dd if=$HOME/Downloads/discovery.iso of=/dev/rdiskN bs=4m
  diskutil eject /dev/diskN
  ```

  macOS then says the disk is "not readable". That's expected for a Linux installer; click **Ignore**.

## 3. USB stick not obviously named in the boot menu

- **Symptom:** the F7 boot menu listed Windows Boot Manager, PXE entries, an EFI shell and "VendorCo".
- **Cause:** cheap USB sticks report a placeholder vendor name.
- **Fix:** "VendorCo" was the USB stick. PXE entries are network boot.

## 4. Illegal hostname

- **Symptom:** host warning *"Hostname Beelink-1.lan is forbidden"*.
- **Cause:** the hostname came from the router with a capital letter. OpenShift allows only lowercase letters, numbers, dashes and dots.
- **Fix:** renamed the host to `sno-node` in the console. No reboot needed.

## 5. "Must have exactly 3 dedicated control plane nodes"

- **Symptom:** the cluster wouldn't proceed with one host.
- **Cause:** the cluster had been created as a standard three-node cluster.
- **Fix:** created a new cluster with **control plane nodes = 1**, generated a new ISO (an ISO only reports to the cluster it came from), re-flashed and rebooted. Lesson: set this first; it can't be changed later.

## 6. DNS wildcard detected

- **Symptom:** *"DNS wildcard configuration was detected for domain \*.adsno.192-168-1-82.nip.io … Please remove it to proceed."*
- **Cause:** the installer checks that a made-up name like `validateNoWildcardDNS.<cluster>.<domain>` does **not** resolve. nip.io answers every name, so the check fails. Any catch-all DNS service has the same problem.
- **Fix:** registered `adelledonne-lab.com`, created only the three required A records in Cloudflare, and changed the base domain in the cluster settings. No new ISO needed; the host re-ran its checks. Verify with:

  ```bash
  dig +short validateNoWildcardDNS.sno.adelledonne-lab.com   # must return nothing
  ```

## 7. New DNS records not resolving

- **Symptom:** `dig` returned nothing for the new names.
- **Cause:** the records hadn't been saved in Cloudflare yet.
- **Diagnosis:** `dig +short NS adelledonne-lab.com` showed the domain was live on Cloudflare; `dig … @1.1.1.1` (asking Cloudflare directly) also returned nothing, which pointed at the records themselves rather than caching.
- **Fix:** added the three A records (name only, e.g. `api.sno`, proxy off).

## 8. Not sure the USB was pulled in time

- **Symptom:** removed the USB stick around the reboot without seeing the exact moment.
- **Check:** the TV showed `sno-node login:` with the new hostname, which means it booted from the internal drive. If it shows the old installer prompt instead, remove the stick and power-cycle.

## 9. "Cluster unreachable" and the console wouldn't load in Chrome

- **Symptom:** the Hybrid Cloud Console showed the cluster as unreachable, and Chrome couldn't open the web console.
- **Diagnosis:**
  - `dig` resolved the console name to `192.168.1.82`.
  - `oc get clusteroperators console ingress authentication` showed all three Available (the console had only finished starting minutes before).
  - `curl -kI https://console-openshift-console.apps.sno.adelledonne-lab.com` returned `HTTP/1.1 200 OK`, so the cluster was serving it.
  - Safari opened it fine.
- **Cause:** Chrome had cached a failed lookup from before the console was ready. The "unreachable" status in the Hybrid Cloud Console is the cluster not having reported in to Red Hat yet, which takes a few hours after install.
- **Fix:** fully quit Chrome (Cmd+Q) and reopened it. Other things to check if that doesn't work: macOS **Local Network** permission for the browser, `chrome://net-internals/#dns` → Clear host cache, and VPNs.

## 10. Pod network broke after the Ethernet cable was unplugged

- **Symptom:** the day after install, `console` and `insights` operators were Degraded, and machine-approver had restarted 119 times. Errors included `dial tcp 172.30.0.1:443: i/o timeout` and a timeout on the console route health check.
- **Cause:** the node's Ethernet cable was unplugged for about 3 hours. OVN-Kubernetes builds its bridge (`br-ex`) on that interface, and it didn't fully recover when the cable came back, so some pod-to-service traffic timed out.
- **Ruled out:** DNS. The node resolved names fine, and the cluster DNS logs showed only normal `NXDOMAIN` replies for the router's `.lan` search suffix. Certificates: all CSRs were Approved,Issued.
- **Fix:** a clean reboot of the node (`ssh core@192.168.1.82 sudo systemctl reboot`). All operators were Available about 10 minutes later.
- **Lesson:** keep the node's network cable permanently connected. If it is ever disconnected, reboot the node afterward.

## Open

- **Edit subscription settings greyed out** in the Hybrid Cloud Console. Expected until the cluster reports in. Rechecking 2026-10-14.
