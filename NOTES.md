# How to build
https://libvirt.org/compiling.html
meson setup build  --prefix /home/sagar/groot/kernel/libvert-build --debug
meson setup build --reconfigure --prefix /home/sagar/groot/kernel/libvert-build --debug
ninja -C build
ninja -C build install
