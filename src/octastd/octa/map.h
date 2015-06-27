/* Associative array for OctaSTD. Implemented as a hash table.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_MAP_H
#define OCTA_MAP_H

#include "octa/types.h"
#include "octa/utility.h"
#include "octa/memory.h"
#include "octa/functional.h"
#include "octa/initializer_list.h"

#include "octa/internal/hashtable.h"

namespace octa {

namespace detail {
    template<typename K, typename T, typename A> struct MapBase {
        using Element = octa::Pair<const K, T>;

        static inline const K &get_key(Element &e) {
            return e.first;
        }
        static inline T &get_data(Element &e) {
            return e.second;
        }
        template<typename U>
        static inline void set_key(Element &e, U &&key, A &alloc) {
            octa::allocator_destroy(alloc, &e);
            octa::allocator_construct(alloc, &e, octa::forward<U>(key),
                octa::move(T()));
        }
        static inline void swap_elem(Element &a, Element &b) {
            octa::swap(*((K *)&a.first), *((K *)&b.first));
            octa::swap(*((T *)&a.second), *((T *)&b.second));
        }
    };

    template<
        typename K, typename T, typename H,
        typename C, typename A, bool IsMultihash
    > struct MapImpl: octa::detail::Hashtable<
        octa::detail::MapBase<K, T, A>, octa::Pair<const K, T>,
        K, T, H, C, A, IsMultihash
    > {
    private:
        using Base = octa::detail::Hashtable<
            octa::detail::MapBase<K, T, A>, octa::Pair<const K, T>,
            K, T, H, C, A, IsMultihash
        >;

    public:
        using Key = K;
        using Mapped = T;
        using Size = octa::Size;
        using Difference = octa::Ptrdiff;
        using Hasher = H;
        using KeyEqual = C;
        using Value = octa::Pair<const K, T>;
        using Reference = Value &;
        using Pointer = octa::AllocatorPointer<A>;
        using ConstPointer = octa::AllocatorConstPointer<A>;
        using Range = octa::HashRange<octa::Pair<const K, T>>;
        using ConstRange = octa::HashRange<const octa::Pair<const K, T>>;
        using LocalRange = octa::BucketRange<octa::Pair<const K, T>>;
        using ConstLocalRange = octa::BucketRange<const octa::Pair<const K, T>>;
        using Allocator = A;

        explicit MapImpl(octa::Size size, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size, hf, eqf, alloc) {}

        MapImpl(): MapImpl(0) {}
        explicit MapImpl(const A &alloc): MapImpl(0, H(), C(), alloc) {}

        MapImpl(octa::Size size, const A &alloc):
            MapImpl(size, H(), C(), alloc) {}
        MapImpl(octa::Size size, const H &hf, const A &alloc):
            MapImpl(size, hf, C(), alloc) {}

        MapImpl(const MapImpl &m): Base(m,
            octa::allocator_container_copy(m.get_alloc())) {}

        MapImpl(const MapImpl &m, const A &alloc): Base(m, alloc) {}

        MapImpl(MapImpl &&m): Base(octa::move(m)) {}
        MapImpl(MapImpl &&m, const A &alloc): Base(octa::move(m), alloc) {}

        template<typename R>
        MapImpl(R range, octa::Size size = 0, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A(),
            octa::EnableIf<
                octa::IsInputRange<R>::value &&
                octa::IsConvertible<RangeReference<R>, Value>::value,
                bool
            > = true
        ): Base(size ? size : octa::detail::estimate_hrsize(range),
                   hf, eqf, alloc) {
            for (; !range.empty(); range.pop_front())
                Base::emplace(range.front());
            Base::rehash_up();
        }

        template<typename R>
        MapImpl(R range, octa::Size size, const A &alloc)
        : MapImpl(range, size, H(), C(), alloc) {}

        template<typename R>
        MapImpl(R range, octa::Size size, const H &hf, const A &alloc)
        : MapImpl(range, size, hf, C(), alloc) {}

        MapImpl(octa::InitializerList<Value> init, octa::Size size = 0,
            const H &hf = H(), const C &eqf = C(), const A &alloc = A()
        ): MapImpl(octa::iter(init), size, hf, eqf, alloc) {}

        MapImpl(octa::InitializerList<Value> init, octa::Size size, const A &alloc)
        : MapImpl(octa::iter(init), size, H(), C(), alloc) {}

        MapImpl(octa::InitializerList<Value> init, octa::Size size, const H &hf,
            const A &alloc
        ): MapImpl(octa::iter(init), size, hf, C(), alloc) {}

        MapImpl &operator=(const MapImpl &m) {
            Base::operator=(m);
            return *this;
        }

        MapImpl &operator=(MapImpl &&m) {
            Base::operator=(octa::move(m));
            return *this;
        }

        template<typename R>
        octa::EnableIf<
            octa::IsInputRange<R>::value &&
            octa::IsConvertible<RangeReference<R>, Value>::value,
            MapImpl &
        > operator=(R range) {
            Base::assign_range(range);
            return *this;
        }

        MapImpl &operator=(InitializerList<Value> il) {
            Base::assign_init(il);
            return *this;
        }

        T &at(const K &key) {
            static_assert(!IsMultihash, "at() only allowed on regular maps");
            return Base::access(key);
        }
        const T &at(const K &key) const {
            static_assert(!IsMultihash, "at() only allowed on regular maps");
            return Base::access(key);
        }

        T &operator[](const K &key) {
            static_assert(!IsMultihash, "operator[] only allowed on regular maps");
            return Base::access_or_insert(key);
        }
        T &operator[](K &&key) {
            static_assert(!IsMultihash, "operator[] only allowed on regular maps");
            return Base::access_or_insert(octa::move(key));
        }

        void swap(MapImpl &v) {
            Base::swap(v);
        }
    };
}

template<
    typename K, typename T,
    typename H = octa::ToHash<K>,
    typename C = octa::Equal<K>,
    typename A = octa::Allocator<octa::Pair<const K, T>>
> using Map = octa::detail::MapImpl<K, T, H, C, A, false>;

template<
    typename K, typename T,
    typename H = octa::ToHash<K>,
    typename C = octa::Equal<K>,
    typename A = octa::Allocator<octa::Pair<const K, T>>
> using Multimap = octa::detail::MapImpl<K, T, H, C, A, true>;

} /* namespace octa */

#endif