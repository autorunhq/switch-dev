# switch-dev

A Docker image for building Horizon (Nintendo Switch) homebrew: devkitA64 with
everything [Autorun](https://github.com/autorunhq/autorun) builds against,
each from a pinned revision, and the tools to build more.

| In portlibs | Revision | |
|---|---|---|
| [libnx](https://github.com/switchbrew/libnx) | `146c3d14` | newer than devkitPro's 4.12.0 release |
| [mesa-switch](https://github.com/danfromtico/mesa-switch) | `0d9d4f08` | Mesa 26: EGL, OpenGL and GLES through nvc0, and loaderless NVK Vulkan, over a Horizon backend written against libnx. Replaces devkitPro's Mesa 20.1; its OpenGL winsys still compiles against switch-libdrm_nouveau's headers, which stay. |
| [lsfg-vk](https://git.lsfg-vk.dev/lsfg-vk-archive.git) | `8b0da266` | the last GPL archive revision, with the Horizon port in `lsfg/`: `liblsfg-vk.a` |
| [libusbhsfs](https://github.com/ITotalJustice/libusbhsfs) | `625269b7` | with the UASP transport in `libusbhsfs/`, FAT and exFAT only: `libusbhsfs.a` |

Tools: CMake, Ninja, Meson 1.12, glslang, SPIRV-Tools 1.3.290, LLVM/Clang 15,
Rust `nightly-2026-09-08` with rust-src, bindgen and cbindgen, and hactool
1.4.0.

`/opt/devkitpro/cmake/switch-dev.cmake` is the CMake toolchain lsfg-vk and
libusbhsfs are built with. It leaves x18 alone, as Wine on Horizon needs.
`/opt/devkitpro/portlibs/switch/share/switch-dev.json` lists the revisions,
and so do the image's labels.

## Use

```sh
docker run --rm -v "$PWD:/work" ghcr.io/autorunhq/switch-dev make
```

The image is built for `linux/arm64`.

## Build

```sh
docker build --platform linux/arm64 -t ghcr.io/autorunhq/switch-dev .
```

To change a revision, edit its `ARG` in the `Dockerfile`.

Pushing a tag such as `2026.09` builds the image on GitHub's arm64 runner and
publishes it as `ghcr.io/autorunhq/switch-dev:2026.09` and `:latest`
(`.github/workflows/publish.yml`).

## Licenses

The Dockerfile and build scripts are MIT. What the image builds keeps its own
license, installed under `portlibs/switch/share/licenses`:
- mesa-switch is MIT.
- lsfg-vk and the port in `lsfg/` are GPL-3.0-or-later.
- libusbhsfs is ISC as built here (no NTFS or ext4).
