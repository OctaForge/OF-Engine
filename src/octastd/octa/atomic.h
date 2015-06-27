/* Atomics for OctaSTD. Supports GCC/Clang and possibly MSVC.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_ATOMIC_H
#define OCTA_ATOMIC_H

#include <stdint.h>
#include <stddef.h>

#include "octa/types.h"
#include "octa/type_traits.h"

namespace octa {

enum class MemoryOrder {
    relaxed = 0,
    consume,
    acquire,
    release,
    acq_rel,
    seq_cst
};

namespace detail {
    template<typename T>
    struct AtomicBase {
        AtomicBase() {}
        explicit AtomicBase(T v): p_value(v) {}
        T p_value;
    };

    template<typename T> T atomic_create();

    template<typename T, typename U>
    EnableIf<sizeof(T()->value = atomic_create<U>()), char>
    test_atomic_assignable(int);

    template<typename T, typename U>
    int test_atomic_assignable(...);

    template<typename T, typename U>
    struct CanAtomicAssign {
        static constexpr bool value
            = (sizeof(test_atomic_assignable<T, U>(1)) == sizeof(char));
    };

    template<typename T>
    static inline EnableIf<
        CanAtomicAssign<volatile AtomicBase<T> *, T>::value
    > atomic_init(volatile AtomicBase<T> *a, T v) {
        a->p_value = v;
    }

    template<typename T>
    static inline EnableIf<
        !CanAtomicAssign<volatile AtomicBase<T> *, T>::value &&
         CanAtomicAssign<         AtomicBase<T> *, T>::value
    > atomic_init(volatile AtomicBase<T> *a, T v) {
        volatile char *to  = (volatile char *)(&a->p_value);
        volatile char *end = to + sizeof(T);
        char *from = (char *)(&v);
        while (to != end) *to++ =*from++;
    }

    template<typename T>
    static inline void atomic_init(AtomicBase<T> *a, T v) {
        a->p_value = v;
    }
}

    /* GCC, Clang support
     *
     * libc++ used for reference
     */

#ifdef __GNUC__

#define ATOMIC_BOOL_LOCK_FREE      __GCC_ATOMIC_BOOL_LOCK_FREE
#define ATOMIC_CHAR_LOCK_FREE      __GCC_ATOMIC_CHAR_LOCK_FREE
#define ATOMIC_CHAR16_T_LOCK_FREE  __GCC_ATOMIC_CHAR16_T_LOCK_FREE
#define ATOMIC_CHAR32_T_LOCK_FREE  __GCC_ATOMIC_CHAR32_T_LOCK_FREE
#define ATOMIC_WCHART_LOCK_FREE   __GCC_ATOMIC_WCHART_LOCK_FREE
#define ATOMIC_SHORT_LOCK_FREE     __GCC_ATOMIC_SHORT_LOCK_FREE
#define ATOMIC_INT_LOCK_FREE       __GCC_ATOMIC_INT_LOCK_FREE
#define ATOMIC_LONG_LOCK_FREE      __GCC_ATOMIC_LONG_LOCK_FREE
#define ATOMIC_LLONG_LOCK_FREE     __GCC_ATOMIC_LLONG_LOCK_FREE
#define ATOMIC_POINTER_LOCK_FREE   __GCC_ATOMIC_POINTER_LOCK_FREE

namespace detail {
    static inline constexpr int to_gcc_order(MemoryOrder ord) {
        return ((ord == MemoryOrder::relaxed) ? __ATOMIC_RELAXED :
               ((ord == MemoryOrder::acquire) ? __ATOMIC_ACQUIRE :
               ((ord == MemoryOrder::release) ? __ATOMIC_RELEASE :
               ((ord == MemoryOrder::seq_cst) ? __ATOMIC_SEQ_CST :
               ((ord == MemoryOrder::acq_rel) ? __ATOMIC_ACQ_REL :
                                                __ATOMIC_CONSUME)))));
    }

    static inline constexpr int to_gcc_failure_order(MemoryOrder ord) {
        return ((ord == MemoryOrder::relaxed) ? __ATOMIC_RELAXED :
               ((ord == MemoryOrder::acquire) ? __ATOMIC_ACQUIRE :
               ((ord == MemoryOrder::release) ? __ATOMIC_RELAXED :
               ((ord == MemoryOrder::seq_cst) ? __ATOMIC_SEQ_CST :
               ((ord == MemoryOrder::acq_rel) ? __ATOMIC_ACQUIRE :
                                                __ATOMIC_CONSUME)))));
    }

    static inline void atomic_thread_fence(MemoryOrder ord) {
        __atomic_thread_fence(to_gcc_order(ord));
    }

    static inline void atomic_signal_fence(MemoryOrder ord) {
        __atomic_signal_fence(to_gcc_order(ord));
    }

    static inline bool atomic_is_lock_free(octa::Size size) {
        /* return __atomic_is_lock_free(size, 0); cannot be used on some platforms */
        return size <= sizeof(void *);
    }

    template<typename T>
    static inline void atomic_store(volatile AtomicBase<T> *a,
                                           T v, MemoryOrder ord) {
        __atomic_store(&a->p_value, &v, to_gcc_order(ord));
    }

    template<typename T>
    static inline void atomic_store(AtomicBase<T> *a,
                                           T v, MemoryOrder ord) {
        __atomic_store(&a->p_value, &v, to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_load(volatile AtomicBase<T> *a,
                                       MemoryOrder ord) {
        T r;
        __atomic_load(&a->p_value, &r, to_gcc_order(ord));
        return r;
    }

    template<typename T>
    static inline T atomic_load(AtomicBase<T> *a,
                                       MemoryOrder ord) {
        T r;
        __atomic_load(&a->p_value, &r, to_gcc_order(ord));
        return r;
    }

    template<typename T>
    static inline T atomic_exchange(volatile AtomicBase<T> *a,
                                           T v, MemoryOrder ord) {
        T r;
        __atomic_exchange(&a->p_value, &v, &r, to_gcc_order(ord));
        return r;
    }

    template<typename T>
    static inline T atomic_exchange(AtomicBase<T> *a,
                                           T v, MemoryOrder ord) {
        T r;
        __atomic_exchange(&a->p_value, &v, &r, to_gcc_order(ord));
        return r;
    }

    template<typename T>
    static inline bool atomic_compare_exchange_strong(
        volatile AtomicBase<T> *a, T *expected, T v,
        MemoryOrder success, MemoryOrder failure
    ) {
        return __atomic_compare_exchange(&a->p_value, expected, &v, false,
            to_gcc_order(success), to_gcc_failure_order(failure));
    }

    template<typename T>
    static inline bool atomic_compare_exchange_strong(
        AtomicBase<T> *a, T *expected, T v,
        MemoryOrder success, MemoryOrder failure
    ) {
        return __atomic_compare_exchange(&a->p_value, expected, &v, false,
            to_gcc_order(success), to_gcc_failure_order(failure));
    }

    template<typename T>
    static inline bool atomic_compare_exchange_weak(
        volatile AtomicBase<T> *a, T *expected, T v,
        MemoryOrder success, MemoryOrder failure
    ) {
        return __atomic_compare_exchange(&a->p_value, expected, &v, true,
            to_gcc_order(success), to_gcc_failure_order(failure));
    }

    template<typename T>
    static inline bool atomic_compare_exchange_weak(
        AtomicBase<T> *a, T *expected, T v,
        MemoryOrder success, MemoryOrder failure
    ) {
        return __atomic_compare_exchange(&a->p_value, expected, &v, true,
            to_gcc_order(success), to_gcc_failure_order(failure));
    }

    template<typename T>
    struct SkipAmt { static constexpr octa::Size value = 1; };

    template<typename T>
    struct SkipAmt<T *> { static constexpr octa::Size value = sizeof(T); };

    template<typename T> struct SkipAmt<T[]> {};
    template<typename T, octa::Size N> struct SkipAmt<T[N]> {};

    template<typename T, typename U>
    static inline T atomic_fetch_add(volatile AtomicBase<T> *a,
                                            U d, MemoryOrder ord) {
        return __atomic_fetch_add(&a->p_value, d * SkipAmt<T>::value,
            to_gcc_order(ord));
    }

    template<typename T, typename U>
    static inline T atomic_fetch_add(AtomicBase<T> *a,
                                            U d, MemoryOrder ord) {
        return __atomic_fetch_add(&a->p_value, d * SkipAmt<T>::value,
            to_gcc_order(ord));
    }

    template<typename T, typename U>
    static inline T atomic_fetch_sub(volatile AtomicBase<T> *a,
                                            U d, MemoryOrder ord) {
        return __atomic_fetch_sub(&a->p_value, d * SkipAmt<T>::value,
            to_gcc_order(ord));
    }

    template<typename T, typename U>
    static inline T atomic_fetch_sub(AtomicBase<T> *a,
                                            U d, MemoryOrder ord) {
        return __atomic_fetch_sub(&a->p_value, d * SkipAmt<T>::value,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_and(volatile AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_and(&a->p_value, pattern,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_and(AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_and(&a->p_value, pattern,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_or(volatile AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_or(&a->p_value, pattern,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_or(AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_or(&a->p_value, pattern,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_xor(volatile AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_xor(&a->p_value, pattern,
            to_gcc_order(ord));
    }

    template<typename T>
    static inline T atomic_fetch_xor(AtomicBase<T> *a,
                                            T pattern, MemoryOrder ord) {
        return __atomic_fetch_xor(&a->p_value, pattern,
            to_gcc_order(ord));
    }
} /* namespace detail */
#else
# error Unsupported compiler
#endif

template <typename T> inline T kill_dependency(T v) {
    return v;
}

namespace detail {
    template<typename T, bool = octa::IsIntegral<T>::value &&
                                !octa::IsSame<T, bool>::value>
    struct Atomic {
        mutable AtomicBase<T> p_a;

        Atomic() = default;

        constexpr Atomic(T v): p_a(v) {}

        Atomic(const Atomic &) = delete;

        Atomic &operator=(const Atomic &) = delete;
        Atomic &operator=(const Atomic &) volatile = delete;

        bool is_lock_free() const volatile {
            return atomic_is_lock_free(sizeof(T));
        }

        bool is_lock_free() const {
            return atomic_is_lock_free(sizeof(T));
        }

        void store(T v, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            atomic_store(&p_a, v, ord);
        }

        void store(T v, MemoryOrder ord = MemoryOrder::seq_cst) {
            atomic_store(&p_a, v, ord);
        }

        T load(MemoryOrder ord = MemoryOrder::seq_cst) const volatile {
            return atomic_load(&p_a, ord);
        }

        T load(MemoryOrder ord = MemoryOrder::seq_cst) const {
            return atomic_load(&p_a, ord);
        }

        operator T() const volatile { return load(); }
        operator T() const          { return load(); }

        T exchange(T v, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_exchange(&p_a, v, ord);
        }

        T exchange(T v, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_exchange(&p_a, v, ord);
        }

        bool compare_exchange_weak(T &e, T v, MemoryOrder s,
                                   MemoryOrder f) volatile {
            return atomic_compare_exchange_weak(&p_a, &e, v, s, f);
        }

        bool compare_exchange_weak(T &e, T v, MemoryOrder s,
                                   MemoryOrder f) {
            return atomic_compare_exchange_weak(&p_a, &e, v, s, f);
        }

        bool compare_exchange_strong(T &e, T v, MemoryOrder s,
                                     MemoryOrder f) volatile {
            return atomic_compare_exchange_strong(&p_a, &e, v, s, f);
        }

        bool compare_exchange_strong(T &e, T v, MemoryOrder s,
                                     MemoryOrder f) {
            return atomic_compare_exchange_strong(&p_a, &e, v, s, f);
        }

        bool compare_exchange_weak(T &e, T v, MemoryOrder ord
                                                  = MemoryOrder::seq_cst)
        volatile {
            return atomic_compare_exchange_weak(&p_a, &e, v, ord, ord);
        }

        bool compare_exchange_weak(T &e, T v, MemoryOrder ord
                                                  = MemoryOrder::seq_cst) {
            return atomic_compare_exchange_weak(&p_a, &e, v, ord, ord);
        }

        bool compare_exchange_strong(T &e, T v, MemoryOrder ord
                                                    = MemoryOrder::seq_cst)
        volatile {
            return atomic_compare_exchange_strong(&p_a, &e, v, ord, ord);
        }

        bool compare_exchange_strong(T &e, T v, MemoryOrder ord
                                                    = MemoryOrder::seq_cst) {
            return atomic_compare_exchange_strong(&p_a, &e, v, ord, ord);
        }
    };

    template<typename T>
    struct Atomic<T, true>: Atomic<T, false> {
        using Base = Atomic<T, false>;

        Atomic() = default;

        constexpr Atomic(T v): Base(v) {}

        T fetch_add(T op, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_fetch_add(&this->p_a, op, ord);
        }

        T fetch_add(T op, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_fetch_add(&this->p_a, op, ord);
        }

        T fetch_sub(T op, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_fetch_sub(&this->p_a, op, ord);
        }

        T fetch_sub(T op, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_fetch_sub(&this->p_a, op, ord);
        }

        T fetch_and(T op, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_fetch_and(&this->p_a, op, ord);
        }

        T fetch_and(T op, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_fetch_and(&this->p_a, op, ord);
        }

        T fetch_or(T op, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_fetch_or(&this->p_a, op, ord);
        }

        T fetch_or(T op, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_fetch_or(&this->p_a, op, ord);
        }

        T fetch_xor(T op, MemoryOrder ord = MemoryOrder::seq_cst) volatile {
            return atomic_fetch_xor(&this->p_a, op, ord);
        }

        T fetch_xor(T op, MemoryOrder ord = MemoryOrder::seq_cst) {
            return atomic_fetch_xor(&this->p_a, op, ord);
        }

        T operator++(int) volatile { return fetch_add(T(1));         }
        T operator++(int)          { return fetch_add(T(1));         }
        T operator--(int) volatile { return fetch_sub(T(1));         }
        T operator--(int)          { return fetch_sub(T(1));         }
        T operator++(   ) volatile { return fetch_add(T(1)) + T(1); }
        T operator++(   )          { return fetch_add(T(1)) + T(1); }
        T operator--(   ) volatile { return fetch_sub(T(1)) - T(1); }
        T operator--(   )          { return fetch_sub(T(1)) - T(1); }

        T operator+=(T op) volatile { return fetch_add(op) + op; }
        T operator+=(T op)          { return fetch_add(op) + op; }
        T operator-=(T op) volatile { return fetch_sub(op) - op; }
        T operator-=(T op)          { return fetch_sub(op) - op; }
        T operator&=(T op) volatile { return fetch_and(op) & op; }
        T operator&=(T op)          { return fetch_and(op) & op; }
        T operator|=(T op) volatile { return fetch_or (op) | op; }
        T operator|=(T op)          { return fetch_or (op) | op; }
        T operator^=(T op) volatile { return fetch_xor(op) ^ op; }
        T operator^=(T op)          { return fetch_xor(op) ^ op; }
    };
}

template<typename T>
struct Atomic: octa::detail::Atomic<T> {
    using Base = octa::detail::Atomic<T>;

    Atomic() = default;

    constexpr Atomic(T v): Base(v) {}

    T operator=(T v) volatile {
        Base::store(v); return v;
    }

    T operator=(T v) {
        Base::store(v); return v;
    }
};

template<typename T>
struct Atomic<T *>: octa::detail::Atomic<T *> {
    using Base = octa::detail::Atomic<T *>;

    Atomic() = default;

    constexpr Atomic(T *v): Base(v) {}

    T *operator=(T *v) volatile {
        Base::store(v); return v;
    }

    T *operator=(T *v) {
        Base::store(v); return v;
    }

    T *fetch_add(octa::Ptrdiff op, MemoryOrder ord = MemoryOrder::seq_cst)
    volatile {
        return octa::detail::atomic_fetch_add(&this->p_a, op, ord);
    }

    T *fetch_add(octa::Ptrdiff op, MemoryOrder ord = MemoryOrder::seq_cst) {
        return octa::detail::atomic_fetch_add(&this->p_a, op, ord);
    }

    T *fetch_sub(octa::Ptrdiff op, MemoryOrder ord = MemoryOrder::seq_cst)
    volatile {
        return octa::detail::atomic_fetch_sub(&this->p_a, op, ord);
    }

    T *fetch_sub(octa::Ptrdiff op, MemoryOrder ord = MemoryOrder::seq_cst) {
        return octa::detail::atomic_fetch_sub(&this->p_a, op, ord);
    }


    T *operator++(int) volatile { return fetch_add(1);     }
    T *operator++(int)          { return fetch_add(1);     }
    T *operator--(int) volatile { return fetch_sub(1);     }
    T *operator--(int)          { return fetch_sub(1);     }
    T *operator++(   ) volatile { return fetch_add(1) + 1; }
    T *operator++(   )          { return fetch_add(1) + 1; }
    T *operator--(   ) volatile { return fetch_sub(1) - 1; }
    T *operator--(   )          { return fetch_sub(1) - 1; }

    T *operator+=(octa::Ptrdiff op) volatile { return fetch_add(op) + op; }
    T *operator+=(octa::Ptrdiff op)          { return fetch_add(op) + op; }
    T *operator-=(octa::Ptrdiff op) volatile { return fetch_sub(op) - op; }
    T *operator-=(octa::Ptrdiff op)          { return fetch_sub(op) - op; }
};

template<typename T>
inline bool atomic_is_lock_free(const volatile Atomic<T> *a) {
    return a->is_lock_free();
}

template<typename T>
inline bool atomic_is_lock_free(const Atomic<T> *a) {
    return a->is_lock_free();
}

template<typename T>
inline void atomic_init(volatile Atomic<T> *a, T v) {
    octa::detail::atomic_init(&a->p_a, v);
}

template<typename T>
inline void atomic_init(Atomic<T> *a, T v) {
    octa::detail::atomic_init(&a->p_a, v);
}

template <typename T>
inline void atomic_store(volatile Atomic<T> *a, T v) {
    a->store(v);
}

template <typename T>
inline void atomic_store(Atomic<T> *a, T v) {
    a->store(v);
}

template <typename T>
inline void atomic_store_explicit(volatile Atomic<T> *a, T v,
                                  MemoryOrder ord) {
    a->store(v, ord);
}

template <typename T>
inline void atomic_store_explicit(Atomic<T> *a, T v,
                                  MemoryOrder ord) {
    a->store(v, ord);
}

template <typename T>
inline T atomic_load(const volatile Atomic<T> *a) {
    return a->load();
}

template <typename T>
inline T atomic_load(const Atomic<T> *a) {
    return a->load();
}

template <typename T>
inline T atomic_load_explicit(const volatile Atomic<T> *a,
                               MemoryOrder ord) {
    return a->load(ord);
}

template <typename T>
inline T atomic_load_explicit(const Atomic<T> *a, MemoryOrder ord) {
    return a->load(ord);
}

template <typename T>
inline T atomic_exchange(volatile Atomic<T> *a, T v) {
    return a->exchange(v);
}

template <typename T>
inline T atomic_exchange(Atomic<T> *a, T v) {
    return a->exchange(v);
}

template <typename T>
inline T atomic_exchange_explicit(volatile Atomic<T> *a, T v,
                                  MemoryOrder ord) {
    return a->exchange(v, ord);
}

template <typename T>
inline T atomic_exchange_explicit(Atomic<T> *a, T v,
                                   MemoryOrder ord) {
    return a->exchange(v, ord);
}

template <typename T>
inline bool atomic_compare_exchange_weak(volatile Atomic<T> *a,
                                         T *e, T v) {
    return a->compare_exchange_weak(*e, v);
}

template <typename T>
inline bool atomic_compare_exchange_weak(Atomic<T> *a, T *e, T v) {
    return a->compare_exchange_weak(*e, v);
}

template <typename T>
inline bool atomic_compare_exchange_strong(volatile Atomic<T> *a,
                                           T *e, T v) {
    return a->compare_exchange_strong(*e, v);
}

template <typename T>
inline bool atomic_compare_exchange_strong(Atomic<T> *a, T *e, T v) {
    return a->compare_exchange_strong(*e, v);
}

template <typename T>
inline bool atomic_compare_exchange_weak_explicit(volatile Atomic<T> *a,
                                                  T *e, T v,
                                                  MemoryOrder s,
                                                  MemoryOrder f) {
    return a->compare_exchange_weak(*e, v, s, f);
}

template <typename T>
inline bool atomic_compare_exchange_weak_explicit(Atomic<T> *a, T *e,
                                                  T v,
                                                  MemoryOrder s,
                                                  MemoryOrder f) {
    return a->compare_exchange_weak(*e, v, s, f);
}

template <typename T>
inline bool atomic_compare_exchange_strong_explicit(volatile Atomic<T> *a,
                                                    T *e, T v,
                                                    MemoryOrder s,
                                                    MemoryOrder f) {
    return a->compare_exchange_strong(*e, v, s, f);
}

template <typename T>
inline bool atomic_compare_exchange_strong_explicit(Atomic<T> *a, T *e,
                                                    T v,
                                                    MemoryOrder s,
                                                    MemoryOrder f) {
    return a->compare_exchange_strong(*e, v, s, f);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_add(volatile Atomic<T> *a, T op) {
    return a->fetch_add(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_add(Atomic<T> *a, T op) {
    return a->fetch_add(op);
}

template <typename T>
inline T *atomic_fetch_add(volatile Atomic<T *> *a, octa::Ptrdiff op) {
    return a->fetch_add(op);
}

template <typename T>
inline T *atomic_fetch_add(Atomic<T *> *a, octa::Ptrdiff op) {
    return a->fetch_add(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_add_explicit(volatile Atomic<T> *a, T op,
                          MemoryOrder ord) {
    return a->fetch_add(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_add_explicit(Atomic<T> *a, T op, MemoryOrder ord) {
    return a->fetch_add(op, ord);
}

template <typename T>
inline T *atomic_fetch_add_explicit(volatile Atomic<T *> *a,
                                    octa::Ptrdiff op, MemoryOrder ord) {
    return a->fetch_add(op, ord);
}

template <typename T>
inline T *atomic_fetch_add_explicit(Atomic<T *> *a, octa::Ptrdiff op,
                                    MemoryOrder ord) {
    return a->fetch_add(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_sub(volatile Atomic<T> *a, T op) {
    return a->fetch_sub(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_sub(Atomic<T> *a, T op) {
    return a->fetch_sub(op);
}

template <typename T>
inline T *atomic_fetch_sub(volatile Atomic<T *> *a, octa::Ptrdiff op) {
    return a->fetch_sub(op);
}

template <typename T>
inline T *atomic_fetch_sub(Atomic<T *> *a, octa::Ptrdiff op) {
    return a->fetch_sub(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_sub_explicit(volatile Atomic<T> *a, T op,
                          MemoryOrder ord) {
    return a->fetch_sub(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_sub_explicit(Atomic<T> *a, T op, MemoryOrder ord) {
    return a->fetch_sub(op, ord);
}

template <typename T>
inline T *atomic_fetch_sub_explicit(volatile Atomic<T *> *a,
                                    octa::Ptrdiff op, MemoryOrder ord) {
    return a->fetch_sub(op, ord);
}

template <typename T>
inline T *atomic_fetch_sub_explicit(Atomic<T *> *a, octa::Ptrdiff op,
                                    MemoryOrder ord) {
    return a->fetch_sub(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_and(volatile Atomic<T> *a, T op) {
    return a->fetch_and(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_and(Atomic<T> *a, T op) {
    return a->fetch_and(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_and_explicit(volatile Atomic<T> *a, T op,
                          MemoryOrder ord) {
    return a->fetch_and(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_and_explicit(Atomic<T> *a, T op, MemoryOrder ord) {
    return a->fetch_and(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_or(volatile Atomic<T> *a, T op) {
    return a->fetch_or(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_or(Atomic<T> *a, T op) {
    return a->fetch_or(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_or_explicit(volatile Atomic<T> *a, T op,
                         MemoryOrder ord) {
    return a->fetch_or(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_or_explicit(Atomic<T> *a, T op, MemoryOrder ord) {
    return a->fetch_or(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_xor(volatile Atomic<T> *a, T op) {
    return a->fetch_xor(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_xor(Atomic<T> *a, T op) {
    return a->fetch_xor(op);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_xor_explicit(volatile Atomic<T> *a, T op,
                          MemoryOrder ord) {
    return a->fetch_xor(op, ord);
}

template <typename T>
inline octa::EnableIf<octa::IsIntegral<T>::value &&
                     !octa::IsSame<T, bool>::value, T>
atomic_fetch_xor_explicit(Atomic<T> *a, T op, MemoryOrder ord) {
    return a->fetch_xor(op, ord);
}

struct AtomicFlag {
    octa::detail::AtomicBase<bool> p_a;

    AtomicFlag() = default;

    AtomicFlag(bool b): p_a(b) {}

    AtomicFlag(const AtomicFlag &) = delete;

    AtomicFlag &operator=(const AtomicFlag &) = delete;
    AtomicFlag &operator=(const AtomicFlag &) volatile = delete;

    bool test_and_set(MemoryOrder ord = MemoryOrder::seq_cst) volatile {
        return octa::detail::atomic_exchange(&p_a, true, ord);
    }

    bool test_and_set(MemoryOrder ord = MemoryOrder::seq_cst) {
        return octa::detail::atomic_exchange(&p_a, true, ord);
    }

    void clear(MemoryOrder ord = MemoryOrder::seq_cst) volatile {
        octa::detail::atomic_store(&p_a, false, ord);
    }

    void clear(MemoryOrder ord = MemoryOrder::seq_cst) {
        octa::detail::atomic_store(&p_a, false, ord);
    }
};

inline bool atomic_flag_test_and_set(volatile AtomicFlag *a) {
    return a->test_and_set();
}

inline bool atomic_flag_test_and_set(AtomicFlag *a) {
    return a->test_and_set();
}

inline bool atomic_flag_test_and_set_explicit(volatile AtomicFlag *a,
                                              MemoryOrder ord) {
    return a->test_and_set(ord);
}

inline bool atomic_flag_test_and_set_explicit(AtomicFlag *a,
                                              MemoryOrder ord) {
    return a->test_and_set(ord);
}

inline void atomic_flag_clear(volatile AtomicFlag *a) {
    a->clear();
}

inline void atomic_flag_clear(AtomicFlag *a) {
    a->clear();
}

inline void atomic_flag_clear_explicit(volatile AtomicFlag *a,
                                       MemoryOrder ord) {
    a->clear(ord);
}

inline void atomic_flag_clear_explicit(AtomicFlag *a, MemoryOrder ord) {
    a->clear(ord);
}

inline void atomic_thread_fence(MemoryOrder ord) {
    octa::detail::atomic_thread_fence(ord);
}

inline void atomic_signal_fence(MemoryOrder ord) {
    octa::detail::atomic_signal_fence(ord);
}

using AtomicBool = Atomic<bool>;
using AtomicChar = Atomic<char>;
using AtomicShort = Atomic<short>;
using AtomicInt = Atomic<int>;
using AtomicLong = Atomic<long>;
using AtomicSchar = Atomic<octa::schar>;
using AtomicUchar = Atomic<octa::uchar>;
using AtomicUshort = Atomic<octa::ushort>;
using AtomicUint = Atomic<octa::uint>;
using AtomicUlong = Atomic<octa::ulong>;
using AtomicLlong = Atomic<octa::llong>;
using AtomicUllong = Atomic<octa::ullong>;

using AtomicChar16 = Atomic<octa::Char16>;
using AtomicChar32 = Atomic<octa::Char32>;
using AtomicWchar = Atomic<octa::Wchar>;

using AtomicPtrdiff = Atomic<octa::Ptrdiff>;
using AtomicSize = Atomic<octa::Size>;

using AtomicIntmax = Atomic<octa::Intmax>;
using AtomicUintmax = Atomic<octa::Uintmax>;

using AtomicIntptr = Atomic<octa::Intptr>;
using AtomicUintptr = Atomic<octa::Uintptr>;

using AtomicInt8 = Atomic<octa::Int8>;
using AtomicInt16 = Atomic<octa::Int16>;
using AtomicInt32 = Atomic<octa::Int32>;
using AtomicInt64 = Atomic<octa::Int64>;

using AtomicUint8 = Atomic<octa::Uint8>;
using AtomicUint16 = Atomic<octa::Uint16>;
using AtomicUint32 = Atomic<octa::Uint32>;
using AtomicUint64 = Atomic<octa::Uint64>;

using AtomicIntLeast8 = Atomic<octa::IntLeast8>;
using AtomicIntLeast16 = Atomic<octa::IntLeast16>;
using AtomicIntLeast32 = Atomic<octa::IntLeast32>;
using AtomicIntLeast64 = Atomic<octa::IntLeast64>;

using AtomicUintLeast8 = Atomic<octa::UintLeast8>;
using AtomicUintLeast16 = Atomic<octa::UintLeast16>;
using AtomicUintLeast32 = Atomic<octa::UintLeast32>;
using AtomicUintLeast64 = Atomic<octa::UintLeast64>;

using AtomicIntFast8 = Atomic<octa::IntFast8>;
using AtomicIntFast16 = Atomic<octa::IntFast16>;
using AtomicIntFast32 = Atomic<octa::IntFast32>;
using AtomicIntFast64 = Atomic<octa::IntFast64>;

using AtomicUintFast8 = Atomic<octa::UintFast8>;
using AtomicUintFast16 = Atomic<octa::UintFast16>;
using AtomicUintFast32 = Atomic<octa::UintFast32>;
using AtomicUintFast64 = Atomic<octa::UintFast64>;

#define ATOMIC_FLAG_INIT {false}
#define ATOMIC_VAR_INIT(v) {v}

}

#endif