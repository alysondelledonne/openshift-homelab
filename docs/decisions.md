# Design decisions

Short records of why the lab is set up the way it is. Each one lists what was chosen, what else was considered, and the trade-off accepted.

## 1. Single-node OpenShift instead of three nodes

- **Chosen:** single-node OpenShift (SNO) on one mini PC.
- **Considered:** a three-node compact cluster.
- **Why:** one box keeps cost, power, noise and setup time low enough to actually finish and keep running. It is still the full OpenShift product installed on bare metal.
- **Trade-off:** no high availability. If the node is down, everything is down, and an SNO cluster can't be converted to HA later. Up to two worker nodes can be added if needed.

## 2. Start on the hardware as shipped

- **Chosen:** install on the Beelink's stock 16 GB RAM and 500 GB drive.
- **Considered:** upgrading to 32–64 GB RAM and adding a 1 TB drive first.
- **Why:** the hardware meets the SNO minimum, and RAM prices were high. Measuring real usage first gives a concrete reason to upgrade (or not).
- **Trade-off:** about 4 GB of memory headroom after install (72% used), and no persistent storage until a second drive is added. Compliance scans and VMs wait for the upgrade.

## 3. Assisted Installer

- **Chosen:** Red Hat's hosted Assisted Installer.
- **Considered:** Agent-based Installer or a manual `openshift-install` single-node ignition.
- **Why:** a web wizard with pre-install validation (hardware, DNS, network) catches problems before anything is written to disk, and it needs nothing installed locally beyond a browser.
- **Trade-off:** depends on Red Hat's hosted service and a connected install. The Agent-based Installer is the better choice later for a fully scripted rebuild.

## 4. Own domain with Cloudflare DNS instead of nip.io or a home DNS server

- **Chosen:** a registered domain, `adelledonne-lab.com`, with three A records in Cloudflare pointing to the private IP.
- **Considered:**
  - `lab.home.arpa` (the reserved home-network domain): the Spectrum router can't host custom DNS records.
  - nip.io: resolves any name to the IP inside it. Failed the installer's check that only `*.apps` is a wildcard.
  - Pi-hole on a Raspberry Pi: works, but means extra hardware, and the Spectrum router can't hand it out as everyone's DNS server.
- **Why:** about $10 a year, no extra hardware, exact records that pass validation, and it makes trusted Let's Encrypt certificates possible later.
- **Trade-off:** the cluster depends on the domain staying registered (auto-renew on) and the records reveal the private IP and cluster name publicly.

## 5. Reserved IP from the router instead of a static IP on the node

- **Chosen:** a DHCP reservation for the node's MAC address.
- **Considered:** a static IP configured in the installer.
- **Why:** keeps the installer on DHCP (simpler), and the router stays the single place that hands out addresses.
- **Trade-off:** the reservation lives on the Spectrum router and has to be recreated on a new router.

## 6. Personal accounts and hardware only

- **Chosen:** personal Red Hat account, personal laptop, personal hardware, nothing from work.
- **Why:** the lab stays mine regardless of employer, and it avoids any overlap with company devices, credentials or client information.
