/* Associative array for OctaSTD. Implemented as a hash table.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_MAP_HH
#define OCTA_MAP_HH

#include "octa/types.hh"
#include "octa/utility.hh"
#include "octa/memory.hh"
#include "octa/functional.hh"
#include "octa/initializer_list.hh"

#include "octa/internal/hashtable.hh"

namespace octa {

namespace detail {
    template<typename K, typename T, typename A> struct MapBase {
        using Element = Pair<const K, T>;

        static inline const K &get_key(Element &e) {
            return e.first;
        }
        static inline T &get_data(Element &e) {
            return e.second;
        }
        template<typename U>
        static inline void set_key(Element &e, U &&key, A &alloc) {
            allocator_destroy(alloc, &e);
            allocator_construct(alloc, &e, forward<U>(key), move(T()));
        }
        static inline void swap_elem(Element &a, Element &b) {
            octa::swap(*((K *)&a.first), *((K *)&b.first));
            octa::swap(*((T *)&a.second), *((T *)&b.second));
        }
    };

    template<
        typename K, typename T, typename H,
        typename C, typename A, bool IsMultihash
    > struct MapImpl: detail::Hashtable<detail::MapBase<K, T, A>,
        Pair<const K, T>, K, T, H, C, A, IsMultihash
    > {
    private:
        using Base = detail::Hashtable<detail::MapBase<K, T, A>,
            Pair<const K, T>, K, T, H, C, A, IsMultihash
        >;

    public:
        using Key = K;
        using Mapped = T;
        using Size = Size;
        using Difference = Ptrdiff;
        using Hasher = H;
        using KeyEqual = C;
        using Value = Pair<const K, T>;
        using Reference = Value &;
        using Pointer = AllocatorPointer<A>;
        using ConstPointer = AllocatorConstPointer<A>;
        using Range = HashRange<Pair<const K, T>>;
        using ConstRange = HashRange<const Pair<const K, T>>;
        using LocalRange = BucketRange<Pair<const K, T>>;
        using ConstLocalRange = BucketRange<const Pair<const K, T>>;
        using Allocator = A;

        explicit MapImpl(Size size, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size, hf, eqf, alloc) {}

        MapImpl(): MapImpl(0) {}
        explicit MapImpl(const A &alloc): MapImpl(0, H(), C(), alloc) {}

        MapImpl(Size size, const A &alloc):
            MapImpl(size, H(), C(), alloc) {}
        MapImpl(Size size, const H &hf, const A &alloc):
            MapImpl(size, hf, C(), alloc) {}

        MapImpl(const MapImpl &m): Base(m,
            allocator_container_copy(m.get_alloc())) {}

        MapImpl(const MapImpl &m, const A &alloc): Base(m, alloc) {}

        MapImpl(MapImpl &&m): Base(move(m)) {}
        MapImpl(MapImpl &&m, const A &alloc): Base(move(m), alloc) {}

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value && IsConvertible<RangeReference<R>,
            Value>::value
        >> MapImpl(R range, Size size = 0, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size ? size : detail::estimate_hrsize(range),
                   hf, eqf, alloc) {
            for (; !range.empty(); range.pop_front())
                Base::emplace(range.front());
            Base::rehash_up();
        }

        template<typename R>
        MapImpl(R range, Size size, const A &alloc)
        : MapImpl(range, size, H(), C(), alloc) {}

        template<typename R>
        MapImpl(R range, Size size, const H &hf, const A &alloc)
        : MapImpl(range, size, hf, C(), alloc) {}

        MapImpl(InitializerList<Value> init, Size size = 0,
            const H &hf = H(), const C &eqf = C(), const A &alloc = A()
        ): MapImpl(iter(init), size, hf, eqf, alloc) {}

        MapImpl(InitializerList<Value> init, Size size, const A &alloc)
        : MapImpl(iter(init), size, H(), C(), alloc) {}

        MapImpl(InitializerList<Value> init, Size size, const H &hf,
            const A &alloc
        ): MapImpl(iter(init), size, hf, C(), alloc) {}

        MapImpl &operator=(const MapImpl &m) {
            Base::operator=(m);
            return *this;
        }

        MapImpl &operator=(MapImpl &&m) {
            Base::operator=(move(m));
            return *this;
        }

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value &&
            IsConvertible<RangeReference<R>, Value>::value
        >> MapImpl &operator=(R range) {
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
            return Base::access_or_insert(move(key));
        }

        void swap(MapImpl &v) {
            Base::swap(v);
        }
    };
}

template<
    typename K, typename T,
    typename H = ToHash<K>,
    typename C = Equal<K>,
    typename A = Allocator<Pair<const K, T>>
> using Map = detail::MapImpl<K, T, H, C, A, false>;

template<
    typename K, typename T,
    typename H = ToHash<K>,
    typename C = Equal<K>,
    typename A = Allocator<Pair<const K, T>>
> using Multimap = detail::MapImpl<K, T, H, C, A, true>;

} /* namespace octa */

#endif