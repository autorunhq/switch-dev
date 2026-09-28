#!/bin/bash
# Build mesa-switch (Mesa 26 for Horizon: EGL and OpenGL through Gallium nvc0,
# and loaderless NVK Vulkan, over the port's own Horizon backend) from the
# checkout in the current directory, and install it into portlibs. OpenGL and
# Vulkan come from one Meson build, so a program links one copy of Mesa for both.
set -euo pipefail
portlibs=/opt/devkitpro/portlibs/switch

# What mesa-switch's build-switch.sh sets up in its container: the cross
# wrappers for bindgen and rustc, the Nouveau header NAK's bindgen reads, the
# Clang header path mesa_clc uses, and placeholder libdl, librt and libutil
# for Rust std (rust_switch_stubs.c has the symbols). Not the checkout's DRM
# nouveau.h: the Switch OpenGL winsys is written against switch-libdrm_nouveau's
# (its five-argument nouveau_device_new and nouveau_bo_get_syncpoint), though
# nothing links that library.
mkdir -p /usr/local/libexec
cp bindgen-switch-wrapper.sh /usr/local/libexec/bindgen
cp rustc-switch-wrapper.sh /usr/local/libexec/rustc
cp bindgen-atomic-shim.h /usr/local/libexec/bindgen-atomic-shim.h
sed -i 's/\r$//' /usr/local/libexec/bindgen /usr/local/libexec/rustc
chmod +x /usr/local/libexec/bindgen /usr/local/libexec/rustc
cp -p src/nouveau/headers/nv_device_info.h $portlibs/include/
[ -d /usr/lib/llvm-15/lib/clang/15/include ] ||
    ln -sf /usr/lib/llvm-15/lib/clang/15.0.6/include /usr/lib/llvm-15/lib/clang/15/include
echo 'void __mesa_switch_stub_lib(void) {}' > /tmp/stub_posix.c
aarch64-none-elf-gcc -c /tmp/stub_posix.c -o /tmp/stub_posix.o
for l in dl rt util; do
    aarch64-none-elf-ar rcs $portlibs/lib/lib$l.a /tmp/stub_posix.o
done

# The host tools the cross build runs.
tools=/tmp/mesa-native
meson setup $tools \
    -Dvulkan-drivers= -Dgallium-drivers= -Dshader-cache=true -Dplatforms= \
    -Dglx=disabled -Degl=disabled -Dopengl=false -Dgles1=disabled -Dgles2=disabled \
    -Dtools=[] -Dllvm=enabled -Dmesa-clc=enabled -Dprecomp-compiler=enabled -Dinstall-mesa-clc=true
ninja -C $tools src/compiler/clc/mesa_clc src/compiler/spirv/vtn_bindgen2
export PATH="/usr/local/libexec:$tools/src/compiler/clc:$tools/src/compiler/spirv:$PATH"

# build-opengl.sh's EGL/OpenGL options with build-switch.sh's NVK.
meson setup /tmp/mesa-build \
    --cross-file switch_cross_file.txt \
    --default-library=static \
    --prefix=$portlibs \
    --libdir=lib \
    --buildtype=release \
    -Doptimization=2 \
    -Db_lto=false \
    -Db_ndebug=true \
    -Dvulkan-drivers=nouveau \
    -Dgallium-drivers=nouveau \
    -Dgallium-rusticl=false \
    -Dplatforms=switch \
    -Degl-native-platform=switch \
    -Dglx=disabled \
    -Degl=enabled \
    -Dopengl=true \
    -Dgles1=enabled \
    -Dgles2=enabled \
    -Dvideo-codecs= \
    -Dshader-cache=enabled \
    -Dxmlconfig=enabled \
    -Dexpat=enabled \
    -Dtools=[] \
    -Dllvm=disabled \
    -Dshared-glapi=disabled \
    -Dshared-llvm=disabled \
    -Dmesa-clc=system \
    -Dprecomp-compiler=system \
    -Dcpp_rtti=false \
    -Dbuild-tests=false
ninja -C /tmp/mesa-build
meson install -C /tmp/mesa-build --no-rebuild
# nvk_archive_merge.py merges libvulkan.a with Debian's ar, which cannot read
# the Rust std members and leaves their symbols out of the index, so ld then
# misses core and alloc. devkitA64's ranlib indexes every member.
# libvulkan.a is merged at install time, outside Meson's install log, so every
# archive in portlibs is indexed again; that is harmless for the others.
find $portlibs/lib -name '*.a' -exec aarch64-none-elf-ranlib {} \;
aarch64-none-elf-nm --print-armap $portlibs/lib/libvulkan.a > /tmp/vulkan-armap
awk '/^Archive index:/ { index_ = 1; next } /^$/ { if (index_) exit }
     index_ && /4core9panicking9panic_fmt / { found = 1 } END { exit !found }' /tmp/vulkan-armap ||
    { echo 'libvulkan.a has no index for Rust core' >&2; exit 1; }
rm /tmp/vulkan-armap
# A program builds against portlibs alone, Vulkan headers included.
cp -r include/vulkan include/vk_video $portlibs/include/
mkdir -p $portlibs/share/licenses/mesa-switch
cp docs/license.rst $portlibs/share/licenses/mesa-switch/
rm -rf /tmp/mesa-native /tmp/mesa-build /tmp/stub_posix.*
