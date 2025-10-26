#!/bin/bash

# Script to set up and run a VM using custom libvirt and QEMU in session mode
# Assumes Ubuntu 22.04 host, custom QEMU in ~/local/qemu, custom libvirt in ~/local/libvirt
# Uses Ubuntu 22.04.5 live-server ISO and QCOW2 disk

set -e

# Configuration
VM_NAME="test-vm"
ISO_PATH="/home/sagar/Documents/ubuntu-22.04.5-live-server-amd64.iso"
QCOW2_PATH="/home/sagar/vms/test-vm.qcow2"
KERNEL_PATH="/tmp/vmlinuz"
INITRD_PATH="/tmp/initrd"
NETWORK_NAME="session-default"
QEMU_BINARY="/home/sagar/local/qemu/bin/qemu-system-x86_64"
LIBVIRT_PREFIX="/home/sagar/local/libvirt"
VMS_DIR="/home/sagar/vms"
NETWORK_XML_DIR="/home/sagar/.local/share/libvirt/networks"

# Step 1: Set up environment
export PATH="$LIBVIRT_PREFIX/bin:$HOME/local/qemu/bin:$PATH"
export LIBVIRT_DEFAULT_URI="qemu:///session"

# Verify tools
echo "Checking custom tools..."
virsh --version || { echo "Error: Custom virsh not found"; exit 1; }
qemu-system-x86_64 --version || { echo "Error: Custom QEMU not found"; exit 1; }

# Step 2: Verify ISO
echo "Verifying ISO..."
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO not found at $ISO_PATH"
    exit 1
fi
if ! file "$ISO_PATH" | grep -q "ISO 9660"; then
    echo "Error: $ISO_PATH is not a valid ISO"
    exit 1
fi

# Step 3: Create QCOW2 disk
echo "Creating QCOW2 disk..."
mkdir -p "$VMS_DIR"
if [ -f "$QCOW2_PATH" ]; then
    echo "QCOW2 disk already exists at $QCOW2_PATH, skipping creation"
else
    qemu-img create -f qcow2 "$QCOW2_PATH" 10G || { echo "Error: Failed to create QCOW2 disk"; exit 1; }
fi

# Step 4: Extract kernel and initrd
echo "Extracting kernel and initrd..."
mkdir -p /tmp/iso
#sudo mount -o loop "$ISO_PATH" /tmp/iso || { echo "Error: Failed to mount ISO"; exit 1; }
if [ ! -f /tmp/iso/casper/vmlinuz ] || [ ! -f /tmp/iso/casper/initrd ]; then
    echo "Error: Kernel or initrd not found in ISO"
    sudo umount /tmp/iso
    exit 1
fi
cp /tmp/iso/casper/vmlinuz "$KERNEL_PATH"
cp /tmp/iso/casper/initrd "$INITRD_PATH"
sudo umount /tmp/iso
rm -rf /tmp/iso
echo "Kernel and initrd extracted to $KERNEL_PATH and $INITRD_PATH"

# Step 5: Configure session-specific network (slirp)
echo "Configuring network..."
mkdir -p "$NETWORK_XML_DIR"
cat > "$NETWORK_XML_DIR/$NETWORK_NAME.xml" <<EOF
<network>
  <name>$NETWORK_NAME</name>
  <forward mode='nat'/>
</network>
EOF
if virsh --connect qemu:///session net-list --all | grep -q "$NETWORK_NAME"; then
    virsh --connect qemu:///session net-undefine "$NETWORK_NAME" || { echo "Warning: Failed to undefine existing network"; }
fi
virsh --connect qemu:///session net-define "$NETWORK_XML_DIR/$NETWORK_NAME.xml" || { echo "Error: Failed to define network"; exit 1; }
virsh --connect qemu:///session net-start "$NETWORK_NAME" || { echo "Error: Failed to start network"; exit 1; }
virsh --connect qemu:///session net-autostart "$NETWORK_NAME" || { echo "Warning: Failed to set network autostart"; }

# Step 6: Create and start VM
echo "Creating and starting VM..."
if virsh --connect qemu:///session list --all | grep -q "$VM_NAME"; then
    virsh --connect qemu:///session destroy "$VM_NAME" || true
    virsh --connect qemu:///session undefine "$VM_NAME" --remove-all-storage || true
fi
virt-install \
  --connect qemu:///session \
  --name "$VM_NAME" \
  --ram 2048 \
  --vcpus 2 \
  --disk path="$QCOW2_PATH",format=qcow2 \
  --os-variant ubuntu22.04 \
  --boot kernel="$KERNEL_PATH",initrd="$INITRD_PATH",kernel_args="console=ttyS0 nomodeset text" \
  --cdrom "$ISO_PATH" \
  --network network="$NETWORK_NAME" \
  --graphics none \
  --console pty,target_type=serial || { echo "Error: virt-install failed"; exit 1; }

# Step 7: Set custom QEMU
echo "Configuring VM to use custom QEMU..."
virsh --connect qemu:///session dumpxml "$VM_NAME" > /tmp/vm.xml
sed -i "s|<emulator>.*</emulator>|<emulator>$QEMU_BINARY</emulator>|" /tmp/vm.xml
virsh --connect qemu:///session define /tmp/vm.xml || { echo "Error: Failed to update VM with custom QEMU"; exit 1; }

# Step 8: Post-install instructions
echo "VM installation started. Follow installer prompts in the console."
echo "To access console: virsh --connect qemu:///session console $VM_NAME (exit with Ctrl+])"
echo "After installation, modify VM to boot from disk:"
echo "  virsh --connect qemu:///session edit $VM_NAME"
echo "  Remove CDROM disk section and ensure <boot dev='hd'/> in <os>"
echo "To manage VM:"
echo "  virsh --connect qemu:///session list --all"
echo "  virsh --connect qemu:///session snapshot-create-as $VM_NAME snap1 --disk-only"
echo "  virsh --connect qemu:///session shutdown $VM_NAME"
echo "  virsh --connect qemu:///session destroy $VM_NAME (force off)"
echo "Check logs: ~/.local/share/libvirt/qemu/$VM_NAME.log"
echo "If needed, start virtlogd: $LIBVIRT_PREFIX/sbin/virtlogd"

exit 0
