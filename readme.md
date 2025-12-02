

# Terraform FCK-NAT High Availability

This project deploys a cost-effective, self-healing NAT solution on AWS using `fck-nat` instances within an Auto Scaling Group. It includes a `Justfile` to automate deployment and simplify SSH connections to private resources.

## Features

*   **Cost Effective:** Uses `t4g.nano` or `t3.micro` instances instead of expensive AWS NAT Gateways.
*   **Self-Healing:** If the NAT instance fails, the Auto Scaling Group launches a new one, and the route table is automatically updated.
*   **Automation:** Includes a `Justfile` for one-command deployment and SSH tunneling.
*   **VS Code Support:** Pre-configured tasks for easy execution from the editor.

## Prerequisites

1.  **Terraform** installed.
2.  **AWS CLI** configured with credentials.
3.  **Just** installed (command runner).

## Quick Start

The project uses `just` to handle Terraform commands and key permissions automatically.

### 1. Initialize and Deploy
```bash
just init
just apply
```

### 2. View Info
Displays the generated keys and IP addresses.
```bash
just info
```

## Connecting to Instances

This setup includes helper commands to handle SSH keys and tunneling automatically.

### Connect to the NAT Instance (Public)
Connects directly to the bastion/NAT host.
```bash
just ssh-nat
```

### Connect to the Private App
Since the application server is in a private subnet, we use SSH tunneling.

1.  **Open the tunnel in the background:**
    ```bash
    just ssh-tunnel
    ```

2.  **Connect to the app:**
    ```bash
    just ssh-app
    ```

3.  **Close the tunnel when finished:**
    ```bash
    just ssh-tunnel-close
    ```

## VS Code Integration

A `.vscode/tasks.json` file is included. You can run all the above commands directly from Visual Studio Code:
1.  Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac).
2.  Type `Run Task`.
3.  Select any task (e.g., `⚡ Terraform Apply`, `💻 SSH to Private App`).

## Clean Up

To destroy all resources:
```bash
just destroy
```

## Troubleshooting

*   **Key Permission Error:** Run `just fix-perms`.
*   **Host Key Verification Failed:** Run `just ssh-clear` to remove old localhost entries from your known_hosts file.
*   **Tunnel Issues:** Run `just ssh-tunnel-close` to clear old processes, then try opening the tunnel again.