#if defined(__i386) || defined(__i386__) || defined(_M_IX86)
#define OF_TARGET_X86 1
#elif defined(__x86_64__) || defined(__x86_64) || \
      defined(_M_X64) || defined(_M_AMD64)
#define OF_TARGET_X64 1
#endif

#if defined(_WIN32) && !defined(_XBOX_VER)
#define OF_TARGET_WINDOWS 1
#elif defined(__linux__)
#define OF_TARGET_LINUX 1
#elif defined(__MACH__) && defined(__APPLE__)
#define OF_TARGET_OSX 1
#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || \
      defined(__NetBSD__)  || defined(__OpenBSD__)
#define OF_TARGET_BSD 1
#elif (defined(__sun__) && defined(__svr4__)) || defined(__CYGWIN__)
#define OF_TARGET_POSIX 1
#endif
