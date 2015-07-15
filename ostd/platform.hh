/* Platform specific definitions for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_PLATFORM_HH
#define OSTD_PLATFORM_HH

#include <stdint.h>

#if defined(WIN32) || defined(_WIN32) || (defined(__WIN32) && !defined(__CYGWIN__))
#  define OSTD_PLATFORM_WIN32 1
#  if defined(WIN64) || defined(_WIN64)
#    define OSTD_PLATFORM_WIN64 1
#  endif
#else
#  define OSTD_PLATFORM_POSIX 1
#  if defined(__linux__)
#    define OSTD_PLATFORM_LINUX 1
#  endif
#  if defined(__APPLE__)
#    define OSTD_PLATFORM_OSX 1
#  endif
#  if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
#    define OSTD_PLATFORM_FREEBSD 1
#    define OSTD_PLATFORM_BSD 1
#  endif
#  if defined(__NetBSD__)
#    define OSTD_PLATFORM_NETBSD 1
#    define OSTD_PLATFORM_BSD 1
#  endif
#  if defined(__OpenBSD__)
#    define OSTD_PLATFORM_OPENBSD 1
#    define OSTD_PLATFORM_BSD 1
#  endif
#  if defined(__DragonFly__)
#    define OSTD_PLATFORM_DRAGONFLYBSD 1
#    define OSTD_PLATFORM_BSD 1
#  endif
#  if defined(sun) || defined(__sun)
#    define OSTD_PLATFORM_SOLARIS 1
#  endif
#endif

#if defined(__clang__)
#  define OSTD_TOOLCHAIN_CLANG 1
#endif

#if defined(__GNUC__)
#  define OSTD_TOOLCHAIN_GNU 1
#endif

#if defined(_MSC_VER)
#  define OSTD_TOOLCHAIN_MSVC 1
#endif

#define OSTD_ENDIAN_LIL 1234
#define OSTD_ENDIAN_BIG 4321

#ifdef OSTD_PLATFORM_LINUX
#  include <endian.h>
#  define OSTD_BYTE_ORDER __BYTE_ORDER
#else
#  if defined(__BIG_ENDIAN__) || defined(__ARMEB__) || defined(__THUMBEB__) || \
      defined(__AARCH64EB__)  || defined(__MIPSEB__) || defined(__MIPSEB) || \
      defined(_MIPSEB) || defined(__ppc__) || defined(__POWERPC__) || \
      defined(_M_PPC) || defined(__sparc__)
#    define OSTD_BYTE_ORDER OSTD_ENDIAN_BIG
#  else
#    define OSTD_BYTE_ORDER OSTD_ENDIAN_LIL
#  endif
#endif

namespace ostd {

#if defined(OSTD_TOOLCHAIN_GNU)

/* using gcc/clang builtins */
inline uint16_t endian_swap16(uint16_t x) {
    return __builtin_bswap16(x);
}
inline uint32_t endian_swap32(uint32_t x) {
    return __builtin_bswap32(x);
}
inline uint64_t endian_swap64(uint64_t x) {
    return __builtin_bswap64(x);
}

#elif defined(OSTD_TOOLCHAIN_MSVC)

/* using msvc builtins */
inline uint16_t endian_swap16(uint16_t x) {
    return _byteswap_ushort(x);
}
inline uint32_t endian_swap32(uint32_t x) {
    /* win64 is llp64 */
    return _byteswap_ulong(x);
}
inline uint64_t endian_swap64(uint64_t x) {
    return _byteswap_uint64(x);
}

#else

/* fallback */
inline uint16_t endian_swap16(uint16_t x) {
    return (x << 8) | (x >> 8);
}
inline uint32_t endian_swap32(uint32_t x) {
    return (x << 24) | (x >> 24) | ((x >> 8) & 0xFF00) | ((x << 8) & 0xFF0000);
}
inline uint64_t endian_swap64(uint64_t x) {
    return endian_swap32(uint32_t(x >> 32)) | (uint64_t(endian_swap32(uint32_t(x))) << 32);
}

#endif

}

#endif