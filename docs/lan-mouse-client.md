# lan-mouse config — phoebe & harry (clients)

Place this at `~/.config/lan-mouse/config.toml`. Each client must define the server (trunkie) as a peer using the position trunkie is relative to that client.

## Harry (Surface) — trunkie is above

```toml
port = 4343

[top]
hostname = "trunkie.local"
ips = ["192.168.50.15"]
port = 4343
activate_on_startup = true
```

## Phoebe (Mac) — trunkie is to the right

```toml
port = 4343

[right]
hostname = "trunkie.local"
ips = ["192.168.50.15"]
port = 4343
activate_on_startup = true
```

Note: `ips` is needed because lan-mouse's built-in DNS resolver doesn't support mDNS `.local` resolution ([issue #234](https://github.com/feschber/lan-mouse/issues/234)). Use LAN IPs or add entries to `/etc/hosts`.
