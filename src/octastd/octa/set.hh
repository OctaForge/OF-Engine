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
    struct SetImpl: octa::detail::Hashtable<
        octa::detail::SetBase<T, A>, T, T, T, H, C, A, IsMultihash
    > {
    private:
        using Base = octa::detail::Hashtable<
            octa::detail::SetBase<T, A>, T, T, T, H, C, A, IsMultihash
        >;

    public:
        using Key = T;
        using Size = octa::Size;
        using Difference = octa::Ptrdiff;
        using Hasher = H;
        using KeyEqual = C;
        using Value = T;
        using Reference = Value &;
        using Pointer = octa::AllocatorPointer<A>;
        using ConstPointer = octa::AllocatorConstPointer<A>;
        using Range = octa::HashRange<T>;
        using ConstRange = octa::HashRange<const T>;
        using LocalRange = octa::BucketRange<T>;
        using ConstLocalRange = octa::BucketRange<const T>;
        using Allocator = A;

        explicit SetImpl(octa::Size size, const H &hf = H(),
            const C &eqf = C(), const A &alloc = A()
        ): Base(size, hf, eqf, alloc) {}

        SetImpl(): SetImpl(0) {}
        explicit SetImpl(const A &alloc): SetImpl(0, H(), C(), alloc) {}

        SetImpl(octa::Size size, const A &alloc):
            SetImpl(size, H(), C(), alloc) {}
        SetImpl(octa::Size size, const H &hf, const A &alloc):
            SetImpl(size, hf, C(), alloc) {}

        SetImpl(const SetImpl &m): Base(m,
            octa::allocator_container_copy(m.get_alloc())) {}

        SetImpl(const SetImpl &m, const A &alloc): Base(m, alloc) {}

        SetImpl(SetImpl &&m): Base(octa::move(m)) {}
        SetImpl(SetImpl &&m, const A &alloc): Base(octa::move(m), alloc) {}

        template<typename R>
        SetImpl(R range, octa::Size size = 0, const H &hf = H(),
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
        SetImpl(R range, octa::Size size, const A &alloc)
        : SetImpl(range, size, H(), C(), alloc) {}

        template<typename R>
        SetImpl(R range, octa::Size size, const H &hf, const A &alloc)
        : SetImpl(range, size, hf, C(), alloc) {}

        SetImpl(octa::InitializerList<Value> init, octa::Size size = 0,
            const H &hf = H(), const C &eqf = C(), const A &alloc = A()
        ): SetImpl(octa::iter(init), size, hf, eqf, alloc) {}

        SetImpl(octa::InitializerList<Value> init, octa::Size size, const A &alloc)
        : SetImpl(octa::iter(init), size, H(), C(), alloc) {}

        SetImpl(octa::InitializerList<Value> init, octa::Size size, const H &hf,
            const A &alloc
        ): SetImpl(octa::iter(init), size, hf, C(), alloc) {}

        SetImpl &operator=(const SetImpl &m) {
            Base::operator=(m);
            return *this;
        }

        SetImpl &operator=(SetImpl &&m) {
            Base::operator=(octa::move(m));
            return *this;
        }

        template<typename R>
        octa::EnableIf<
            octa::IsInputRange<R>::value &&
            octa::IsConvertible<RangeReference<R>, Value>::value,
            SetImpl &
        > operator=(R range) {
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
    typename H = octa::ToHash<T>,
    typename C = octa::Equal<T>,
    typename A = octa::Allocator<T>
> using Set = octa::detail::SetImpl<T, H, C, A, false>;

template<
    typename T,
    typename H = octa::ToHash<T>,
    typename C = octa::Equal<T>,
    typename A = octa::Allocator<T>
> using Multiset = octa::detail::SetImpl<T, H, C, A, true>;

} /* namespace octa */

#endif