# libusbhsfs with UASP: the pinned revision with the patches here applied, and
# usbhsfs_uasp.c built into it. FAT and exFAT through FatFs only; NTFS and ext4
# would link GPL libraries. FatFs's get_fattime is renamed so it cannot meet
# another FatFs in the same program. Installs libusbhsfs.a and usbhsfs.h.
cmake_minimum_required(VERSION 3.20)
project(libusbhsfs-uasp C)
set(USBHSFS_SOURCE "" CACHE PATH "libusbhsfs checkout with the UASP patches applied")
set(USBHSFS_GPL OFF CACHE BOOL "" FORCE)
set(USBHSFS_NTFS OFF CACHE BOOL "" FORCE)
set(USBHSFS_EXT4 OFF CACHE BOOL "" FORCE)
set(USBHSFS_SXOS_DISABLE ON CACHE BOOL "" FORCE)
set(USBHSFS_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory("${USBHSFS_SOURCE}" libusbhsfs)
target_sources(libusbhsfs PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/usbhsfs_uasp.c")
target_include_directories(libusbhsfs PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${USBHSFS_SOURCE}/source")
target_compile_definitions(libusbhsfs PRIVATE get_fattime=usbhsfs_get_fattime)
set_target_properties(libusbhsfs PROPERTIES OUTPUT_NAME usbhsfs PREFIX lib)
install(TARGETS libusbhsfs ARCHIVE DESTINATION lib)
install(FILES "${USBHSFS_SOURCE}/include/usbhsfs.h" DESTINATION include)
install(FILES "${USBHSFS_SOURCE}/LICENSE_ISC.md" DESTINATION share/licenses/libusbhsfs)
