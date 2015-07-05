/* Core type aliases for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_TYPES_HH
#define OCTA_TYPES_HH

#include <stdint.h>
#include <stddef.h>

namespace octa {

/* "builtin" types */

using sbyte = signed char;
using byte = unsigned char;
using ushort = unsigned short;
using uint = unsigned int;
using ulong = unsigned long;
using ullong = unsigned long long;
using llong = long long;

using ldouble = long double;

/* keywords in c++, but aliased */

using Wchar = wchar_t;
using Char16 = char16_t;
using Char32 = char32_t;

/* nullptr type */

using Nullptr = decltype(nullptr);

/* max align */

#if defined(__CLANG_MAX_ALIGN_T_DEFINED) || defined(_GCC_MAX_ALIGN_T)
using MaxAlign = ::max_align_t;
#else
using MaxAlign = long double;
#endif

/* stddef */

using Ptrdiff = ptrdiff_t;
using Size = size_t;

/* stdint */

using Intmax = intmax_t;
using Uintmax = uintmax_t;

using Intptr = intptr_t;
using Uintptr = uintptr_t;

using Int8 = int8_t;
using Int16 = int16_t;
using Int32 = int32_t;
using Int64 = int64_t;

using Uint8 = uint8_t;
using Uint16 = uint16_t;
using Uint32 = uint32_t;
using Uint64 = uint64_t;

using IntLeast8 = int_least8_t;
using IntLeast16 = int_least16_t;
using IntLeast32 = int_least32_t;
using IntLeast64 = int_least64_t;

using UintLeast8 = uint_least8_t;
using UintLeast16 = uint_least16_t;
using UintLeast32 = uint_least32_t;
using UintLeast64 = uint_least64_t;

using IntFast8 = int_fast8_t;
using IntFast16 = int_fast16_t;
using IntFast32 = int_fast32_t;
using IntFast64 = int_fast64_t;

using UintFast8 = uint_fast8_t;
using UintFast16 = uint_fast16_t;
using UintFast32 = uint_fast32_t;
using UintFast64 = uint_fast64_t;

}

#endif