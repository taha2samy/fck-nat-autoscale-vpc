# General Settings
set shell := ["bash", "-c"]

# Variables from Terraform Outputs
key_path := `terraform output -raw private_key_path 2>/dev/null || echo "private_key.pem"`
app_ip   := `terraform output -raw private_app_ip 2>/dev/null`

# Extract the first Public IP from the JSON list output
nat_ip   := `terraform output -json nat_public_ips 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1`

# Default Users
nat_user := "ec2-user"
app_user := "ubuntu"

# Local tunnel port
local_port := "2222"

# File to store tunnel PID
tunnel_pid_file := "./.ssh_tunnel_pid"

# Default command
default:
    @just --list
    @echo "Available SSH tasks:"
    @echo "  just ssh-nat        # Connect to NAT instance"
    @echo "  just ssh-tunnel     # Open SSH tunnel"
    @echo "  just ssh-app        # Connect to private app"
    @echo "  just ssh-tunnel-close # Close SSH tunnel"
    @echo "  just ssh-clear      # Clear SSH key for localhost:2222"


# ---------------------------------------------------------
# Terraform Commands
# ---------------------------------------------------------

init:
    terraform init

plan:
    terraform plan

apply:
    terraform apply -auto-approve
    @just fix-perms

destroy:
    terraform destroy -auto-approve

refresh:
    terraform refresh

# ---------------------------------------------------------
# SSH & Connectivity
# ---------------------------------------------------------

# Fix Key Permissions
fix-perms:
    @if [ -f "{{key_path}}" ]; then \
        chmod 400 "{{key_path}}"; \
        echo "✅ Key permissions fixed (400)."; \
    else \
        echo "⚠️ Key file not found. Run 'just apply' first."; \
    fi

# SSH into NAT Instance (Public)
ssh-nat:
    @if [ -z "{{nat_ip}}" ]; then echo "❌ NAT IP not found. Run 'just refresh' and try again."; exit 1; fi
    @echo "🚀 Connecting to NAT Instance ({{nat_ip}})..."
    ssh -i "{{key_path}}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {{nat_user}}@{{nat_ip}}

# Open SSH Tunnel in background
ssh-tunnel:
    @if [ -z "{{nat_ip}}" ]; then echo "❌ NAT IP not found. Run 'just refresh' and try again."; exit 1; fi
    @echo "🚀 Opening SSH Tunnel to Private App ({{app_ip}}) via NAT ({{nat_ip}}) on localhost:{{local_port}}..."
    @ssh -i "{{key_path}}" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -L {{local_port}}:{{app_ip}}:22 {{nat_user}}@{{nat_ip}} -N -f \
        && echo $! > {{tunnel_pid_file}} \
        && echo "✅ Tunnel opened in background. PID saved in {{tunnel_pid_file}}"

# SSH into Private App via local tunnel
ssh-app:
    @echo "🚀 Connecting to Private App via tunnel on localhost:{{local_port}}..."
    sudo ssh -i "{{key_path}}" -p {{local_port}} {{app_user}}@localhost

# Close SSH Tunnel
ssh-tunnel-close:
    @if [ -f "{{tunnel_pid_file}}" ]; then \
        kill $(cat {{tunnel_pid_file}}) && rm -f {{tunnel_pid_file}} && echo "✅ Tunnel closed."; \
    else \
        echo "⚠️ No tunnel PID file found. Is the tunnel running?"; \
    fi

ssh-clear:
    sudo ssh-keygen -R "[localhost]:2222"

# Display Information
info:
    @echo "========================================"
    @echo "🔑 Key Path:    {{key_path}}"
    @echo "🌐 NAT Public:  {{nat_ip}}"
    @echo "🔒 App Private: {{app_ip}}"
    @echo "========================================"
