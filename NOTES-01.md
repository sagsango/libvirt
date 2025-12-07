# libvirt ❱❱❱ tree -d
.
├── daemon
├── docs
│   ├── api_extension
│   ├── devhelp
│   ├── html
│   ├── internals
│   └── schemas
├── examples
│   ├── apparmor
│   ├── domain-events
│   │   ├── events-c
│   │   └── events-python
│   ├── dominfo
│   ├── domsuspend
│   ├── hellolibvirt
│   ├── openauth
│   ├── python
│   ├── systemtap
│   └── xml
│       ├── nwfilter
│       ├── storage
│       └── test
├── include
│   └── libvirt
├── m4
├── po
├── python
│   └── tests
├── src
│   ├── conf
│   ├── cpu
│   ├── esx
│   ├── interface
│   ├── libxl
│   ├── lxc
│   ├── network
│   ├── node_device
│   ├── nwfilter
│   ├── openvz
│   ├── phyp
│   ├── qemu
│   ├── remote
│   ├── secret
│   ├── security
│   ├── storage
│   ├── test
│   ├── uml
│   ├── util
│   ├── vbox
│   ├── vmware
│   ├── vmx
│   ├── xen
│   ├── xenapi
│   └── xenxs
├── tests
│   ├── capabilityschemadata
│   ├── commanddata
│   ├── confdata
│   ├── cputestdata
│   ├── domainschemadata
│   ├── domainsnapshotxml2xmlin
│   ├── domainsnapshotxml2xmlout
│   ├── interfaceschemadata
│   ├── networkxml2xmlin
│   ├── networkxml2xmlout
│   ├── nodedevschemadata
│   ├── nodeinfodata
│   ├── nwfilterxml2xmlin
│   ├── nwfilterxml2xmlout
│   ├── qemuhelpdata
│   ├── qemuxml2argvdata
│   ├── qemuxml2xmloutdata
│   ├── sexpr2xmldata
│   ├── storagepoolxml2xmlin
│   ├── storagepoolxml2xmlout
│   ├── storagevolxml2xmlin
│   ├── storagevolxml2xmlout
│   ├── vmx2xmldata
│   ├── xencapsdata
│   ├── xmconfigdata
│   ├── xml2sexprdata
│   └── xml2vmxdata
└── tools

84 directories


# Overview 
Client (virsh/libvirt API/Python bindings)
        │
        ▼
 ┌───────────────────────────┐
 │       libvirtd (daemon)   │   ← runs on host, communicates via RPC
 └───────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────┐
 │                    libvirt drivers                     │
 │  qemu/   xen/   lxc/   uml/   openvz/   test/   esx/   │
 └────────────────────────────────────────────────────────┘
        │
        ▼
 [Hypervisor process, e.g. QEMU/KVM, Xen, LXC container]

# libvirt ❱❱❱ tree daemon
daemon
├── dispatch.c
├── dispatch.h
├── libvirtd.aug
├── libvirtd.c
├── libvirtd.conf
├── libvirtd.h
├── libvirtd.init.in
├── libvirtd.logrotate.in
├── libvirtd.lxc.logrotate.in
├── libvirtd.pod.in
├── libvirtd.policy-0
├── libvirtd.policy-1
├── libvirtd.qemu.logrotate.in
├── libvirtd.sasl
├── libvirtd.stp
├── libvirtd.sysconf
├── libvirtd.uml.logrotate.in
├── Makefile.am
├── mdns.c
├── mdns.h
├── probes.d
├── qemu_dispatch_args.h
├── qemu_dispatch_prototypes.h
├── qemu_dispatch_ret.h
├── qemu_dispatch_table.h
├── remote_dispatch_args.h
├── remote_dispatch_prototypes.h
├── remote_dispatch_ret.h
├── remote_dispatch_table.h
├── remote_generate_stubs.pl
├── remote.c
├── remote.h
├── stream.c
├── stream.h
├── test_libvirtd.aug
└── THREADING.txt

1 directory, 36 files

# libvirt ❱❱❱ tree src/qemu
src/qemu
├── libvirtd_qemu.aug
├── qemu_audit.c
├── qemu_audit.h
├── qemu_bridge_filter.c
├── qemu_bridge_filter.h
├── qemu_capabilities.c
├── qemu_capabilities.h
├── qemu_cgroup.c
├── qemu_cgroup.h
├── qemu_command.c
├── qemu_command.h
├── qemu_conf.c
├── qemu_conf.h
├── qemu_domain.c
├── qemu_domain.h
├── qemu_driver.c
├── qemu_driver.h
├── qemu_hostdev.c
├── qemu_hostdev.h
├── qemu_hotplug.c
├── qemu_hotplug.h
├── qemu_migration.c
├── qemu_migration.h
├── qemu_monitor_json.c
├── qemu_monitor_json.h
├── qemu_monitor_text.c
├── qemu_monitor_text.h
├── qemu_monitor.c
├── qemu_monitor.h
├── qemu_process.c
├── qemu_process.h
├── qemu.conf
├── test_libvirtd_qemu.aug
└── THREADS.txt

1 directory, 34 files

# libvirt ❱❱❱ tree tools
tools
├── console.c
├── console.h
├── libvirt_win_icon_16x16.ico
├── libvirt_win_icon_32x32.ico
├── libvirt_win_icon_48x48.ico
├── libvirt_win_icon_64x64.ico
├── libvirt-guests.init.sh
├── libvirt-guests.sysconf
├── Makefile.am
├── virsh_win_icon.rc
├── virsh.c
├── virsh.pod
├── virt-pki-validate.in
└── virt-xml-validate.in

1 directory, 14 files
libvirt ❱❱❱

# libvirt ❱❱❱ tree src/remote
src/remote
├── qemu_protocol.c
├── qemu_protocol.h
├── qemu_protocol.x
├── remote_driver.c
├── remote_driver.h
├── remote_protocol.c
├── remote_protocol.h
├── remote_protocol.x
└── rpcgen_fix.pl

1 directory, 9 files
libvirt ❱❱❱


# detailed flow
┌──────────────────────────────────────────────────────────┐
│ virsh (CLI)                                              │
│ └─ cmdStart()                                            │
│     └─ virDomainCreate()  ─┐                             │
└────────────────────────────┘                             │
                         │ libvirt public API (src/libvirt.c)
                         ▼
┌──────────────────────────────────────────────────────────┐
│ libvirt.so (client lib)                                  │
│ └─ remote_driver.c:remoteDomainCreate()                  │
│     ├─ fill remote_domain_create_args                    │
│     ├─ XDR encode via remote_protocol.c                  │
│     ├─ send RPC to libvirtd (UNIX socket)                │
│     └─ wait for reply                                    │
└──────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│ libvirtd daemon                                          │
│ ├─ daemon/dispatch.c:remoteDispatchDomainCreate()        │
│ │     (auto-generated from remote_protocol.x)            │
│ └─ calls virDriver->domainCreate()                       │
│         │                                                │
│         ▼                                                │
│     qemu_driver.c:qemuDomainCreate()                     │
│         ├─ parse XML (domain_conf.c)                     │
│         ├─ build QEMU cmdline (qemu_command.c)           │
│         ├─ setup cgroups/network/storage                 │
│         ├─ fork + exec qemu                              │
│         └─ attach monitor (qemu_monitor.c)               │
└──────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│ QEMU process (child)                                     │
│ ├─ Executes via execve("qemu-system-x86_64", argv, envp) │
│ ├─ Uses /dev/kvm, tap/bridge, disk image, etc.           │
│ └─ Communicates via monitor socket back to libvirtd       │
└──────────────────────────────────────────────────────────┘

