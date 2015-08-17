/* Keyed set for OctaSTD. Implemented as a hash table.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_KEYSET_HH
#define OSTD_KEYSET_HH

#include "ostd/types.hh"
#include "ostd/utility.hh"
#include "ostd/memory.hh"
#include "ostd/functional.hh"
#include "ostd/initializer_list.hh"
#include "ostd/type_traits.hh"

#include "ostd/internal/hashtable.hh"

namespace ostd {

namespace detail {
    template<typename T>
    using KeysetKeyRet = decltype(declval<const T &>().get_key());
    template<typename T>
    using KeysetKey = const Decay<KeysetKeyRet<T>>;

    template<typename T, typename A> struct KeysetBase {
        using Key = KeysetKey<T>;

        using RetKey = Conditional<
            IsReference<KeysetKeyRet<T>>::value, Key &, Key
        >;
        static inline RetKey get_key(const T &e) {
            return e.get_key();
        }
        static inline T &get_data(T &e) {
            return e;
        }
        template<typename U>
        static inline void set_key(T &, const U &, A &) {}
        static inline void swap_elem(T &a, T &b) { swap_adl(a, b); }
    };

    template<
        typename T, typename H, typename C, typename A, bool IsMultihash
    > struct KeysetImpl: detail::Hashtable<detail::KeysetBase<T, A>,
        T, KeysetKey<T>, T, H, C, A, IsMultihash
    > {
    private:
        using Base = detail::Hashtable<detail::KeysetBase<T, A>,
            T, KeysetKey<T>, T, H, C, A, IsMultihash
        >;

    public:
        using Key = KeysetKey<T>;
        using Mapped = T;
        using Size = ostd::Size;
        using Difference = Ptrdiff;
        using Hasher = H;
        using KeyEqual = C;
        using Value = T;
        using Reference = Value &;
        using Pointer = AllocatorPointer<A>;
        using ConstPointer = AllocatorConstPointer<A>;
        using Range = HashRange<T>;
        using ConstRange = HashRange<const T>;
        using LocalRange = BucketRange<T>;
        using ConstLocalRange = BucketRange<const T>;
        using Allocator = A;

        explicit KeysetImpl(Size size, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size, hf, eqf, alloc) {}

        KeysetImpl(): KeysetImpl(0) {}
        explicit KeysetImpl(const A &alloc): KeysetImpl(0, H(), C(), alloc) {}

        KeysetImpl(Size size, const A &alloc):
            KeysetImpl(size, H(), C(), alloc) {}
        KeysetImpl(Size size, const H &hf, const A &alloc):
            KeysetImpl(size, hf, C(), alloc) {}

        KeysetImpl(const KeysetImpl &m): Base(m,
            allocator_container_copy(m.get_alloc())) {}

        KeysetImpl(const KeysetImpl &m, const A &alloc): Base(m, alloc) {}

        KeysetImpl(KeysetImpl &&m): Base(move(m)) {}
        KeysetImpl(KeysetImpl &&m, const A &alloc): Base(move(m), alloc) {}

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value && IsConvertible<RangeReference<R>,
            Value>::value
        >> KeysetImpl(R range, Size size = 0, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size ? size : detail::estimate_hrsize(range),
                   hf, eqf, alloc) {
            for (; !range.empty(); range.pop_front())
                Base::emplace(range.front());
            Base::rehash_up();
        }

        template<typename R>
        KeysetImpl(R range, Size size, const A &alloc)
        : KeysetImpl(range, size, H(), C(), alloc) {}

        template<typename R>
        KeysetImpl(R range, Size size, const H &hf, const A &alloc)
        : KeysetImpl(range, size, hf, C(), alloc) {}

        KeysetImpl(InitializerList<Value> init, Size size = 0,
            const H &hf = H(), const C &eqf = C(), const A &alloc = A()
        ): KeysetImpl(iter(init), size, hf, eqf, alloc) {}

        KeysetImpl(InitializerList<Value> init, Size size, const A &alloc)
        : KeysetImpl(iter(init), size, H(), C(), alloc) {}

        KeysetImpl(InitializerList<Value> init, Size size, const H &hf,
            const A &alloc
        ): KeysetImpl(iter(init), size, hf, C(), alloc) {}

        KeysetImpl &operator=(const KeysetImpl &m) {
            Base::operator=(m);
            return *this;
        }

        KeysetImpl &operator=(KeysetImpl &&m) {
            Base::operator=(move(m));
            return *this;
        }

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value &&
            IsConvertible<RangeReference<R>, Value>::value
        >> KeysetImpl &operator=(R range) {
            Base::assign_range(range);
            return *this;
        }

        KeysetImpl &operator=(InitializerList<Value> il) {
            Base::assign_init(il);
            return *this;
        }

        T *at(const Key &key) {
            static_assert(!IsMultihash, "at() only allowed on regular keysets");
            return Base::access(key);
        }
        const T *at(const Key &key) const {
            static_assert(!IsMultihash, "at() only allowed on regular keysets");
            return Base::access(key);
        }

        T &operator[](const Key &key) {
            static_assert(!IsMultihash, "operator[] only allowed on regular keysets");
            return Base::access_or_insert(key);
        }
        T &operator[](Key &&key) {
            static_assert(!IsMultihash, "operator[] only allowed on regular keysets");
            return Base::access_or_insert(move(key));
        }

        void swap(KeysetImpl &v) {
            Base::swap(v);
        }
    };
}

template<
    typename T,
    typename H = ToHash<detail::KeysetKey<T>>,
    typename C = EqualWithCstr<detail::KeysetKey<T>>,
    typename A = Allocator<T>
> using Keyset = detail::KeysetImpl<T, H, C, A, false>;

template<
    typename T,
    typename H = ToHash<detail::KeysetKey<T>>,
    typename C = EqualWithCstr<detail::KeysetKey<T>>,
    typename A = Allocator<T>
> using Multikeyset = detail::KeysetImpl<T, H, C, A, true>;

} /* namespace ostd */

#endif