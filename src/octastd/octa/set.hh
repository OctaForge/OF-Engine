/* A set container for OctaSTD. Implemented as a hash table.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_SET_HH
#define OCTA_SET_HH

#include "octa/types.hh"
#include "octa/utility.hh"
#include "octa/memory.hh"
#include "octa/functional.hh"
#include "octa/initializer_list.hh"

#include "octa/internal/hashtable.hh"

namespace octa {

namespace detail {
    template<typename T, typename A> struct SetBase {
        static inline const T &get_key(const T &e) {
            return e;
        }
        static inline T &get_data(T &e) {
            return e;
        }
        template<typename U>
        static inline void set_key(T &, const U &, A &) {}
        static inline void swap_elem(T &a, T &b) { octa::swap(a, b); }
    };

    template<typename T, typename H, typename C, typename A, bool IsMultihash>
    struct SetImpl: detail::Hashtable<
        detail::SetBase<T, A>, T, T, T, H, C, A, IsMultihash
    > {
    private:
        using Base = detail::Hashtable<
            detail::SetBase<T, A>, T, T, T, H, C, A, IsMultihash
        >;

    public:
        using Key = T;
        using Size = Size;
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

        explicit SetImpl(Size size, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size, hf, eqf, alloc) {}

        SetImpl(): SetImpl(0) {}
        explicit SetImpl(const A &alloc): SetImpl(0, H(), C(), alloc) {}

        SetImpl(Size size, const A &alloc):
            SetImpl(size, H(), C(), alloc) {}
        SetImpl(Size size, const H &hf, const A &alloc):
            SetImpl(size, hf, C(), alloc) {}

        SetImpl(const SetImpl &m): Base(m,
            allocator_container_copy(m.get_alloc())) {}

        SetImpl(const SetImpl &m, const A &alloc): Base(m, alloc) {}

        SetImpl(SetImpl &&m): Base(move(m)) {}
        SetImpl(SetImpl &&m, const A &alloc): Base(move(m), alloc) {}

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value &&
            IsConvertible<RangeReference<R>, Value>::value
        >> SetImpl(R range, Size size = 0, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size ? size : detail::estimate_hrsize(range),
                   hf, eqf, alloc) {
            for (; !range.empty(); range.pop_front())
                Base::emplace(range.front());
            Base::rehash_up();
        }

        template<typename R>
        SetImpl(R range, Size size, const A &alloc)
        : SetImpl(range, size, H(), C(), alloc) {}

        template<typename R>
        SetImpl(R range, Size size, const H &hf, const A &alloc)
        : SetImpl(range, size, hf, C(), alloc) {}

        SetImpl(InitializerList<Value> init, Size size = 0,
            const H &hf = H(), const C &eqf = C(), const A &alloc = A()
        ): SetImpl(iter(init), size, hf, eqf, alloc) {}

        SetImpl(InitializerList<Value> init, Size size, const A &alloc)
        : SetImpl(iter(init), size, H(), C(), alloc) {}

        SetImpl(InitializerList<Value> init, Size size, const H &hf,
            const A &alloc
        ): SetImpl(iter(init), size, hf, C(), alloc) {}

        SetImpl &operator=(const SetImpl &m) {
            Base::operator=(m);
            return *this;
        }

        SetImpl &operator=(SetImpl &&m) {
            Base::operator=(move(m));
            return *this;
        }

        template<typename R, typename = EnableIf<
            IsInputRange<R>::value &&
            IsConvertible<RangeReference<R>, Value>::value
        >> SetImpl &operator=(R range) {
            Base::assign_range(range);
            return *this;
        }

        SetImpl &operator=(InitializerList<Value> il) {
            Base::assign_init(il);
            return *this;
        }

        void swap(SetImpl &v) {
            Base::swap(v);
        }
    };
}

template<
    typename T,
    typename H = ToHash<T>,
    typename C = Equal<T>,
    typename A = Allocator<T>
> using Set = detail::SetImpl<T, H, C, A, false>;

template<
    typename T,
    typename H = ToHash<T>,
    typename C = Equal<T>,
    typename A = Allocator<T>
> using Multiset = detail::SetImpl<T, H, C, A, true>;

} /* namespace octa */

#endif