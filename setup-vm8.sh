#!/bin/bash

# Script to set up and run a VM using custom libvirt and QEMU in session mode
# Assumes Ubuntu 22.04 host, custom QEMU in ~/local/qemu, custom libvirt in ~/local/libvirt
# Uses Ubuntu 22.04.5 live-server ISO and QCOW2 disk
# Requires p7zip-full (install once: sudo apt install p7zip-full)
# Tries bridge network with sudo; falls back to slirp (no sudo) if fails

set -e

# Configuration
VM_NAME="test-vm"
ISO_PATH="/home/sagar/Documents/ubuntu-22.04.5-live-server-amd64.iso"
QCOW2_PATH="/home/sagar/vms/test-vm.qcow2"
KERNEL_PATH="/tmp/vmlinuz"
INITRD_PATH="/tmp/initrd"
NETWORK_NAME="session-default"
#QEMU_BINARY="/home/sagar/local/qemu/bin/qemu-system-x86_64"
QEMU_BINARY="/usr/bin/qemu-system-x86_64"
#LIBVIRT_PREFIX="/home/sagar/local/libvirt"
LIBVIRT_PREFIX="/usr"
VIRSH="$LIBVIRT_PREFIX/bin/virsh"
VMS_DIR="/home/sagar/vms"
NETWORK_XML_DIR="/home/sagar/.local/share/libvirt/networks"
EXTRACT_DIR="/tmp/iso-extract"

# Step 1: Check if running as sudo
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script should not be run with sudo, as it uses qemu:///session"
    echo "Sudo will be used only for network bridge commands if needed"
    exit 1
fi

# Step 2: Check for 7z
if ! command -v 7z &> /dev/null; then
    echo "Error: 7z not found. Install p7zip-full: sudo apt install p7zip-full"
    exit 1
fi

# Step 3: Set up environment
export PATH="$LIBVIRT_PREFIX/bin:$HOME/local/qemu/bin:$PATH"
export LIBVIRT_DEFAULT_URI="qemu:///session"
echo "Current PATH: $PATH"

# Verify tools
echo "Checking custom tools..."
$VIRSH --version || { echo "Error: Custom virsh not found at $VIRSH"; exit 1; }
if [ ! -x "$QEMU_BINARY" ]; then
    echo "Error: Custom QEMU binary not found at $QEMU_BINARY"
    echo "Ensure QEMU is built and installed in ~/local/qemu"
    exit 1
fi
QEMU_VERSION=$($QEMU_BINARY --version | head -n1)
#if echo "$QEMU_VERSION" | grep -qi "debian"; then
#    echo "Error: System QEMU detected ($QEMU_VERSION)"
#    echo "Expected custom QEMU at $QEMU_BINARY"
#    echo "Run: export PATH=\"/home/sagar/local/qemu/bin:\$PATH\" and rebuild QEMU if needed"
#    exit 1
#fi
echo "Custom QEMU: $QEMU_VERSION"

# Step 4: Verify ISO
echo "Verifying ISO..."
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO not found at $ISO_PATH"
    exit 1
fi
if ! file "$ISO_PATH" | grep -q "ISO 9660"; then
    echo "Error: $ISO_PATH is not a valid ISO"
    exit 1
fi

# Step 5: Create QCOW2 disk
echo "Creating QCOW2 disk..."
mkdir -p "$VMS_DIR"
if [ -f "$QCOW2_PATH" ]; then
    echo "QCOW2 disk already exists at $QCOW2_PATH, skipping creation"
else
    qemu-img create -f qcow2 "$QCOW2_PATH" 10G || { echo "Error: Failed to create QCOW2 disk"; exit 1; }
fi

# Step 6: Extract kernel and initrd using 7z (sudo-free)
echo "Extracting kernel and initrd..."
rm -f "$KERNEL_PATH" "$INITRD_PATH" 2>/dev/null || true
mkdir -p "$EXTRACT_DIR"
cd "$EXTRACT_DIR"
7z x "$ISO_PATH" casper/vmlinuz casper/initrd -y > /dev/null 2>&1 || { echo "Error: Failed to extract from ISO"; rm -rf "$EXTRACT_DIR"; exit 1; }
if [ ! -f "casper/vmlinuz" ] || [ ! -f "casper/initrd" ]; then
    echo "Error: Kernel or initrd not found in ISO"
    rm -rf "$EXTRACT_DIR"
    exit 1
fi
cp casper/vmlinuz "$KERNEL_PATH"
cp casper/initrd "$INITRD_PATH"
rm -rf "$EXTRACT_DIR"
echo "Kernel and initrd extracted to $KERNEL_PATH and $INITRD_PATH"

# Step 7: Configure session-specific network (try bridge with sudo, fallback to slirp)
echo "Configuring network..."
: <<'END_COMMENT'
mkdir -p "$NETWORK_XML_DIR"
cat > "$NETWORK_XML_DIR/$NETWORK_NAME.xml" <<EOF
<network>
  <name>$NETWORK_NAME</name>
  <bridge name='virbr1' stp='on' delay='0'/>
  <forward mode='nat'/>
  <ip address='192.168.123.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
    </dhcp>
  </ip>
</network>
EOF
END_COMMENT


# Try bridge-based network with sudo
echo "Attempting bridge-based network with sudo..."
#if $VIRSH --connect qemu:///session net-list --all | grep -q "$NETWORK_NAME"; then
#    sudo $VIRSH --connect qemu:///session net-undefine "$NETWORK_NAME" || { echo "Warning: Failed to undefine existing network"; }
#fi
sudo $VIRSH --connect qemu:///session net-define "$NETWORK_XML_DIR/$NETWORK_NAME.xml" || { echo "Warning: Failed to define bridge network"; }
: <<'END_COMMENT2'
if sudo $VIRSH --connect qemu:///session net-start "$NETWORK_NAME"; then
    sudo $VIRSH --connect qemu:///session net-autostart "$NETWORK_NAME" || { echo "Warning: Failed to set network autostart"; }
    echo "Bridge network ($NETWORK_NAME) started successfully"
else
    echo "Bridge network failed; falling back to slirp..."
    sudo $VIRSH --connect qemu:///session net-undefine "$NETWORK_NAME" || true
    cat > "$NETWORK_XML_DIR/$NETWORK_NAME.xml" <<EOF
<network>
  <name>$NETWORK_NAME</name>
</network>
EOF
    $VIRSH --connect qemu:///session net-define "$NETWORK_XML_DIR/$NETWORK_NAME.xml" || { echo "Error: Failed to define slirp network"; exit 1; }
    $VIRSH --connect qemu:///session net-start "$NETWORK_NAME" || { echo "Error: Failed to start slirp network"; exit 1; }
    $VIRSH --connect qemu:///session net-autostart "$NETWORK_NAME" || { echo "Warning: Failed to set slirp network autostart"; }
    echo "Slirp network ($NETWORK_NAME) started"
fi
END_COMMENT2
# Step 8: Create and start VM
echo "Creating and starting VM..."
if $VIRSH --connect qemu:///session list --all | grep -q "$VM_NAME"; then
    $VIRSH --connect qemu:///session destroy "$VM_NAME" || true
    $VIRSH --connect qemu:///session undefine "$VM_NAME" --remove-all-storage || true
fi
virt-install \
  --connect qemu:///session \
  --name "$VM_NAME" \
  --ram 2048 \
  --vcpus 2 \
  --disk path="$QCOW2_PATH",format=qcow2 \
  --os-variant ubuntu22.04 \
  --boot kernel="$KERNEL_PATH",initrd="$INITRD_PATH",kernel_args="console=ttyS0,115200n8 nomodeset text" \
  --cdrom "$ISO_PATH" \
  --network network="$NETWORK_NAME" \
  --graphics none \
  --console pty,target_type=serial || { echo "Error: virt-install failed"; exit 1; }

# Step 9: Set custom QEMU
echo "Configuring VM to use custom QEMU..."
$VIRSH --connect qemu:///session dumpxml "$VM_NAME" > /tmp/vm.xml
sed -i "s|<emulator>.*</emulator>|<emulator>$QEMU_BINARY</emulator>|" /tmp/vm.xml
$VIRSH --connect qemu:///session define /tmp/vm.xml || { echo "Error: Failed to update VM with custom QEMU"; exit 1; }

# Step 10: Post-install instructions
echo "VM installation started. Follow installer prompts in the console."
echo "To access console: $VIRSH --connect qemu:///session console $VM_NAME (exit with Ctrl+])"
echo "After installation, modify VM to boot from disk:"
echo "  $VIRSH --connect qemu:///session edit $VM_NAME"
echo "  Remove CDROM disk section and ensure <boot dev='hd'/> in <os>"
echo "To manage VM:"
echo "  $VIRSH --connect qemu:///session list --all"
echo "  $VIRSH --connect qemu:///session snapshot-create-as $VM_NAME snap1 --disk-only"
echo "  $VIRSH --connect qemu:///session shutdown $VM_NAME"
echo "  $VIRSH --connect qemu:///session destroy $VM_NAME (force off)"
echo "Check logs: ~/.local/share/libvirt/qemu/$VM_NAME.log"
echo "If needed, start virtlogd: $LIBVIRT_PREFIX/sbin/virtlogd"

exit 0
