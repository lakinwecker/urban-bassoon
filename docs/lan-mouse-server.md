# lan-mouse config — trunkie (server)

Trunkie has the keyboard and mouse attached. Place this at `~/.config/lan-mouse/config.toml`.

```toml
port = 4343

# Phoebe (Mac) - leftmost monitor
[left]
hostname = "phoebe.local"
port = 4343
activate_on_startup = true

# Harry (Surface) - below middle monitor
[bottom]
hostname = "harry.local"
port = 4343
activate_on_startup = true
```

## Auto-start (Arch / systemd)

Create `~/.config/systemd/user/lan-mouse.service`:

```ini
[Unit]
Description=lan-mouse KVM
After=graphical-session.target

[Service]
ExecStart=/usr/bin/lan-mouse --daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
```

Then enable:

```bash
systemctl --user daemon-reload
systemctl --user enable --now lan-mouse
```
