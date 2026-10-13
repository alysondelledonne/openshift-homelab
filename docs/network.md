# Network

## Settings

| Setting | Value |
| --- | --- |
| Home network | `192.168.1.0/24` |
| Router / gateway | `192.168.1.1` (Spectrum) |
| Node IP | `192.168.1.82`, DHCP reservation on the router |
| Cluster name | `sno` |
| Base domain | `adelledonne-lab.com` |
| DNS provider | Cloudflare (free plan) |

The node's MAC address is deliberately left out of this public repo.

## DNS records

All type A, proxy off ("DNS only"), TTL Auto.

| Purpose | Cloudflare name | Full name | Points to |
| --- | --- | --- | --- |
| Kubernetes API | `api.sno` | `api.sno.adelledonne-lab.com` | `192.168.1.82` |
| Internal API | `api-int.sno` | `api-int.sno.adelledonne-lab.com` | `192.168.1.82` |
| Apps and console | `*.apps.sno` | `*.apps.sno.adelledonne-lab.com` | `192.168.1.82` |

Only `*.apps.sno` is a wildcard. The installer checks that nothing else under `sno.adelledonne-lab.com` resolves, which is why a catch-all service like nip.io didn't work (see [decisions.md](decisions.md)).

## Endpoints

| What | Address |
| --- | --- |
| Web console | `https://console-openshift-console.apps.sno.adelledonne-lab.com` |
| API | `https://api.sno.adelledonne-lab.com:6443` |

## Exposure

- No port forwarding on the router. The cluster is reachable only from inside the home network.
- The DNS records are public, so anyone can see the private IP and cluster name, but a `192.168.x.x` address can't be reached from the internet.

## If the network changes

- **New router or a move:** set the new router's network to `192.168.1.0/24` and reserve `192.168.1.82` for the node's wired port again. Nothing else changes.
- **Node IP has to change:** update the three Cloudflare records. A single-node cluster doesn't handle an IP change well after install, so treat this as a likely reinstall.
- The node has two Ethernet ports, each with its own MAC address. The reservation only applies to the port in use, so the cable stays in the same port.
