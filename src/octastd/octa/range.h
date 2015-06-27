/* Ranges for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_RANGE_H
#define OCTA_RANGE_H

#include <stddef.h>

#include "octa/types.h"
#include "octa/utility.h"
#include "octa/type_traits.h"

namespace octa {

struct InputRangeTag {};
struct OutputRangeTag {};
struct ForwardRangeTag: InputRangeTag {};
struct BidirectionalRangeTag: ForwardRangeTag {};
struct RandomAccessRangeTag: BidirectionalRangeTag {};
struct FiniteRandomAccessRangeTag: RandomAccessRangeTag {};

template<typename T> struct RangeHalf;

#define OCTA_RANGE_TRAIT(Name) \
namespace detail { \
    template<typename T> \
    struct Range##Name##Test { \
        template<typename U> static char test(RemoveReference<typename U::Name> *); \
        template<typename U> static  int test(...); \
        static constexpr bool value = (sizeof(test<T>(0)) == sizeof(char)); \
    }; \
    template<typename T, bool = Range##Name##Test<T>::value> \
    struct Range##Name##Base {}; \
    template<typename T> \
    struct Range##Name##Base<T, true> { \
        using Type = typename T::Name; \
    }; \
} \
template<typename T> \
using Range##Name = typename octa::detail::Range##Name##Base<T>::Type;

OCTA_RANGE_TRAIT(Category)
OCTA_RANGE_TRAIT(Size)
OCTA_RANGE_TRAIT(Value)
OCTA_RANGE_TRAIT(Reference)
OCTA_RANGE_TRAIT(Difference)

#undef OCTA_RANGE_TRAIT

namespace detail {
    template<typename T>
    struct IsRangeTest {
        template<typename U> static char test(typename U::Category *,
                                              typename U::Size *,
                                              typename U::Difference *,
                                              typename U::Value *,
                                              RemoveReference<
                                                  typename U::Reference
                                              > *);
        template<typename U> static  int test(...);
        static constexpr bool value
            = (sizeof(test<T>(0, 0, 0, 0, 0)) == sizeof(char));
    };
}

// is input range

namespace detail {
    template<typename T, bool = octa::IsConvertible<
        RangeCategory<T>, InputRangeTag
    >::value> struct IsInputRangeBase: False {};

    template<typename T>
    struct IsInputRangeBase<T, true>: True {};
}

template<typename T, bool = octa::detail::IsRangeTest<T>::value>
struct IsInputRange: False {};

template<typename T>
struct IsInputRange<T, true>: octa::detail::IsInputRangeBase<T>::Type {};

// is forward range

namespace detail {
    template<typename T, bool = octa::IsConvertible<
        RangeCategory<T>, ForwardRangeTag
    >::value> struct IsForwardRangeBase: False {};

    template<typename T>
    struct IsForwardRangeBase<T, true>: True {};
}

template<typename T, bool = octa::detail::IsRangeTest<T>::value>
struct IsForwardRange: False {};

template<typename T>
struct IsForwardRange<T, true>: octa::detail::IsForwardRangeBase<T>::Type {};

// is bidirectional range

namespace detail {
    template<typename T, bool = octa::IsConvertible<
        RangeCategory<T>, BidirectionalRangeTag
    >::value> struct IsBidirectionalRangeBase: False {};

    template<typename T>
    struct IsBidirectionalRangeBase<T, true>: True {};
}

template<typename T, bool = octa::detail::IsRangeTest<T>::value>
struct IsBidirectionalRange: False {};

template<typename T>
struct IsBidirectionalRange<T, true>:
    octa::detail::IsBidirectionalRangeBase<T>::Type {};

// is random access range

namespace detail {
    template<typename T, bool = octa::IsConvertible<
        RangeCategory<T>, RandomAccessRangeTag
    >::value> struct IsRandomAccessRangeBase: False {};

    template<typename T>
    struct IsRandomAccessRangeBase<T, true>: True {};
}

template<typename T, bool = octa::detail::IsRangeTest<T>::value>
struct IsRandomAccessRange: False {};

template<typename T>
struct IsRandomAccessRange<T, true>:
    octa::detail::IsRandomAccessRangeBase<T>::Type {};

// is finite random access range

namespace detail {
    template<typename T, bool = octa::IsConvertible<
        RangeCategory<T>, FiniteRandomAccessRangeTag
    >::value> struct IsFiniteRandomAccessRangeBase: False {};

    template<typename T>
    struct IsFiniteRandomAccessRangeBase<T, true>: True {};
}

template<typename T, bool = octa::detail::IsRangeTest<T>::value>
struct IsFiniteRandomAccessRange: False {};

template<typename T>
struct IsFiniteRandomAccessRange<T, true>:
    octa::detail::IsFiniteRandomAccessRangeBase<T>::Type {};

// is infinite random access range

template<typename T>
struct IsInfiniteRandomAccessRange: IntegralConstant<bool,
    (IsRandomAccessRange<T>::value && !IsFiniteRandomAccessRange<T>::value)
> {};

// is output range

namespace detail {
    template<typename T, typename P>
    struct OutputRangeTest {
        template<typename U, void (U::*)(P)> struct Test {};
        template<typename U> static char test(Test<U, &U::put> *);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == sizeof(char));
    };
}

template<typename T, bool = (octa::IsConvertible<
    RangeCategory<T>, OutputRangeTag
>::value || (IsInputRange<T>::value &&
    (octa::detail::OutputRangeTest<T, const RangeValue<T>  &>::value ||
     octa::detail::OutputRangeTest<T,       RangeValue<T> &&>::value)
))> struct IsOutputRange: False {};

template<typename T>
struct IsOutputRange<T, true>: True {};

namespace detail {
    // range iterator

    template<typename T>
    struct RangeIterator {
        RangeIterator(): p_range() {}
        explicit RangeIterator(const T &range): p_range(range) {}
        RangeIterator &operator++() {
            p_range.pop_front();
            return *this;
        }
        RangeReference<T> operator*() const {
            return p_range.front();
        }
        bool operator!=(RangeIterator) const { return !p_range.empty(); }
    private:
        T p_range;
    };
}

// range half

template<typename T> struct HalfRange;

namespace detail {
    template<typename R, bool = IsBidirectionalRange<typename R::Range>::value>
    struct RangeAdd;

    template<typename R>
    struct RangeAdd<R, true> {
        using Diff = RangeDifference<typename R::Range>;

        static Diff add_n(R &half, Diff n) {
            if (n < 0) return -half.prev_n(n);
            return half.next_n(n);
        }
        static Diff sub_n(R &half, Diff n) {
            if (n < 0) return -half.next_n(n);
            return half.prev_n(n);
        }
    };

    template<typename R>
    struct RangeAdd<R, false> {
        using Diff = RangeDifference<typename R::Range>;

        static Diff add_n(R &half, Diff n) {
            if (n < 0) return 0;
            return half.next_n(n);
        }
        static Diff sub_n(R &half, Diff n) {
            if (n < 0) return 0;
            return half.prev_n(n);
        }
    };
}

template<typename T>
struct RangeHalf {
private:
    T p_range;
public:
    using Range = T;

    RangeHalf(): p_range() {}

    RangeHalf(const T &range): p_range(range) {}

    template<typename U> RangeHalf(const RangeHalf<U> &half,
        octa::EnableIf<octa::IsConvertible<U, T>::value, bool> = true
    ): p_range(half.p_range) {}

    RangeHalf(RangeHalf &&half): p_range(octa::move(half.p_range)) {}

    RangeHalf &operator=(const RangeHalf &half) {
        p_range = half.p_range;
        return *this;
    }

    RangeHalf &operator=(RangeHalf &&half) {
        p_range = octa::move(half.p_range);
        return *this;
    }

    bool next() { return p_range.pop_front(); }
    bool prev() { return p_range.push_front(); }

    RangeSize<T> next_n(RangeSize<T> n) {
        return p_range.pop_front_n(n);
    }
    RangeSize<T> prev_n(RangeSize<T> n) {
        return p_range.push_front_n(n);
    }

    RangeDifference<T> add_n(RangeDifference<T> n) {
        return octa::detail::RangeAdd<RangeHalf<T>>::add_n(*this, n);
    }
    RangeDifference<T> sub_n(RangeDifference<T> n) {
        return octa::detail::RangeAdd<RangeHalf<T>>::sub_n(*this, n);
    }

    RangeReference<T> get() const {
        return p_range.front();
    }

    RangeDifference<T> distance(const RangeHalf &half) const {
        return p_range.distance_front(half.p_range);
    }

    bool equals(const RangeHalf &half) const {
        return p_range.equals_front(half.p_range);
    }

    bool operator==(const RangeHalf &half) const {
        return equals(half);
    }
    bool operator!=(const RangeHalf &half) const {
        return !equals(half);
    }

    /* iterator like interface */

    RangeReference<T> operator*() const {
        return get();
    }

    RangeReference<T> operator[](RangeSize<T> idx) const {
        return p_range[idx];
    }

    RangeHalf &operator++() {
        next();
        return *this;
    }
    RangeHalf operator++(int) {
        RangeHalf tmp(*this);
        next();
        return tmp;
    }

    RangeHalf &operator--() {
        prev();
        return *this;
    }
    RangeHalf operator--(int) {
        RangeHalf tmp(*this);
        prev();
        return tmp;
    }

    RangeHalf operator+(RangeDifference<T> n) const {
        RangeHalf tmp(*this);
        tmp.add_n(n);
        return tmp;
    }
    RangeHalf operator-(RangeDifference<T> n) const {
        RangeHalf tmp(*this);
        tmp.sub_n(n);
        return tmp;
    }

    RangeHalf &operator+=(RangeDifference<T> n) {
        add_n(n);
        return *this;
    }
    RangeHalf &operator-=(RangeDifference<T> n) {
        sub_n(n);
        return *this;
    }

    T iter() const { return p_range; }

    HalfRange<RangeHalf> iter(const RangeHalf &other) const {
        return HalfRange<RangeHalf>(*this, other);
    }
};

template<typename R>
RangeDifference<R> operator-(const R &lhs, const R &rhs) {
    return rhs.distance(lhs);
}

namespace detail {
    template<typename R>
    RangeSize<R> pop_front_n(R &range, RangeSize<R> n) {
        for (RangeSize<R> i = 0; i < n; ++i)
            if (!range.pop_front()) return i;
        return n;
    }

    template<typename R>
    RangeSize<R> pop_back_n(R &range, RangeSize<R> n) {
        for (RangeSize<R> i = 0; i < n; ++i)
            if (!range.pop_back()) return i;
        return n;
    }

    template<typename R>
    RangeSize<R> push_front_n(R &range, RangeSize<R> n) {
        for (RangeSize<R> i = 0; i < n; ++i)
            if (!range.push_front()) return i;
        return n;
    }

    template<typename R>
    RangeSize<R> push_back_n(R &range, RangeSize<R> n) {
        for (RangeSize<R> i = 0; i < n; ++i)
            if (!range.push_back()) return i;
        return n;
    }
}

template<typename> struct ReverseRange;
template<typename> struct MoveRange;

template<typename B, typename C, typename V, typename R = V &,
         typename S = octa::Size, typename D = octa::Ptrdiff
> struct InputRange {
    using Category = C;
    using Size = S;
    using Difference = D;
    using Value = V;
    using Reference = R;

    octa::detail::RangeIterator<B> begin() const {
        return octa::detail::RangeIterator<B>((const B &)*this);
    }
    octa::detail::RangeIterator<B> end() const {
        return octa::detail::RangeIterator<B>();
    }

    Size pop_front_n(Size n) {
        return octa::detail::pop_front_n<B>(*((B *)this), n);
    }

    Size pop_back_n(Size n) {
        return octa::detail::pop_back_n<B>(*((B *)this), n);
    }

    Size push_front_n(Size n) {
        return octa::detail::push_front_n<B>(*((B *)this), n);
    }

    Size push_back_n(Size n) {
        return octa::detail::push_back_n<B>(*((B *)this), n);
    }

    B iter() const {
        return B(*((B *)this));
    }

    ReverseRange<B> reverse() const {
        return ReverseRange<B>(iter());
    }

    MoveRange<B> movable() const {
        return MoveRange<B>(iter());
    }

    RangeHalf<B> half() const {
        return RangeHalf<B>(iter());
    }
};

template<typename T>
auto iter(T &r) -> decltype(r.iter()) {
    return r.iter();
}

template<typename T>
auto iter(const T &r) -> decltype(r.iter()) {
    return r.iter();
}

template<typename T>
auto citer(const T &r) -> decltype(r.iter()) {
    return r.iter();
}

template<typename V, typename R = V &, typename S = octa::Size,
         typename D = octa::Ptrdiff
> struct OutputRange {
    using Category = OutputRangeTag;
    using Size = S;
    using Difference = D;
    using Value = V;
    using Reference = R;
};

template<typename T>
struct HalfRange: InputRange<HalfRange<T>,
    RangeCategory<T>, RangeValue<T>, RangeReference<T>, RangeSize<T>,
    RangeDifference<T>
> {
private:
    T p_beg;
    T p_end;
public:
    HalfRange(): p_beg(), p_end() {}
    HalfRange(const HalfRange &range): p_beg(range.p_beg),
        p_end(range.p_end) {}
    HalfRange(HalfRange &&range): p_beg(octa::move(range.p_beg)),
        p_end(octa::move(range.p_end)) {}
    HalfRange(const T &beg, const T &end): p_beg(beg),
        p_end(end) {}
    HalfRange(T &&beg, T &&end): p_beg(octa::move(beg)),
        p_end(octa::move(end)) {}

    HalfRange &operator=(const HalfRange &range) {
        p_beg = range.p_beg;
        p_end = range.p_end;
        return *this;
    }

    HalfRange &operator=(HalfRange &&range) {
        p_beg = octa::move(range.p_beg);
        p_end = octa::move(range.p_end);
        return *this;
    }

    bool empty() const { return p_beg == p_end; }

    bool pop_front() {
        if (empty()) return false;
        return p_beg.next();
    }
    bool push_front() {
        return p_beg.prev();
    }
    bool pop_back() {
        if (empty()) return false;
        return p_end.prev();
    }
    bool push_back() {
        return p_end.next();
    }

    RangeReference<T> front() const { return *p_beg; }
    RangeReference<T> back() const { return *(p_end - 1); }

    bool equals_front(const HalfRange &range) const {
        return p_beg == range.p_beg;
    }
    bool equals_back(const HalfRange &range) const {
        return p_end == range.p_end;
    }

    RangeDifference<T> distance_front(const HalfRange &range) const {
        return range.p_beg - p_beg;
    }
    RangeDifference<T> distance_back(const HalfRange &range) const {
        return range.p_end - p_end;
    }

    RangeSize<T> size() const { return p_end - p_beg; }

    HalfRange<T> slice(RangeSize<T> start, RangeSize<T> p_end) const {
        return HalfRange<T>(p_beg + start, p_beg + p_end);
    }

    RangeReference<T> operator[](RangeSize<T> idx) const {
        return p_beg[idx];
    }

    void put(const RangeValue<T> &v) {
        p_beg.range().put(v);
    }
    void put(RangeValue<T> &&v) {
        p_beg.range().put(octa::move(v));
    }
};

template<typename T>
struct ReverseRange: InputRange<ReverseRange<T>,
    RangeCategory<T>, RangeValue<T>, RangeReference<T>, RangeSize<T>,
    RangeDifference<T>
> {
private:
    using Rref = RangeReference<T>;
    using Rsize = RangeSize<T>;

    T p_range;

public:
    ReverseRange(): p_range() {}

    ReverseRange(const T &range): p_range(range) {}

    ReverseRange(const ReverseRange &it): p_range(it.p_range) {}

    ReverseRange(ReverseRange &&it): p_range(octa::move(it.p_range)) {}

    ReverseRange &operator=(const ReverseRange &v) {
        p_range = v.p_range;
        return *this;
    }
    ReverseRange &operator=(ReverseRange &&v) {
        p_range = octa::move(v.p_range);
        return *this;
    }
    ReverseRange &operator=(const T &v) {
        p_range = v;
        return *this;
    }
    ReverseRange &operator=(T &&v) {
        p_range = octa::move(v);
        return *this;
    }

    bool empty() const { return p_range.empty(); }
    Rsize size() const { return p_range.size(); }

    bool equals_front(const ReverseRange &r) const {
    return p_range.equals_back(r.p_range);
    }
    bool equals_back(const ReverseRange &r) const {
        return p_range.equals_front(r.p_range);
    }

    RangeDifference<T> distance_front(const ReverseRange &r) const {
        return -p_range.distance_back(r.p_range);
    }
    RangeDifference<T> distance_back(const ReverseRange &r) const {
        return -p_range.distance_front(r.p_range);
    }

    bool pop_front() { return p_range.pop_back(); }
    bool pop_back() { return p_range.pop_front(); }

    bool push_front() { return p_range.push_back(); }
    bool push_back() { return p_range.push_front(); }

    Rsize pop_front_n(Rsize n) { return p_range.pop_front_n(n); }
    Rsize pop_back_n(Rsize n) { return p_range.pop_back_n(n); }

    Rsize push_front_n(Rsize n) { return p_range.push_front_n(n); }
    Rsize push_back_n(Rsize n) { return p_range.push_back_n(n); }

    Rref front() const { return p_range.back(); }
    Rref back() const { return p_range.front(); }

    Rref operator[](Rsize i) const { return p_range[size() - i - 1]; }

    ReverseRange<T> slice(Rsize start, Rsize end) const {
        Rsize len = p_range.size();
        return ReverseRange<T>(p_range.slice(len - end, len - start));
    }
};

template<typename T>
struct MoveRange: InputRange<MoveRange<T>,
    RangeCategory<T>, RangeValue<T>, RangeValue<T> &&, RangeSize<T>,
    RangeDifference<T>
> {
private:
    using Rval = RangeValue<T>;
    using Rref = RangeValue<T> &&;
    using Rsize = RangeSize<T>;

    T p_range;

public:
    MoveRange(): p_range() {}

    MoveRange(const T &range): p_range(range) {}

    MoveRange(const MoveRange &it): p_range(it.p_range) {}

    MoveRange(MoveRange &&it): p_range(octa::move(it.p_range)) {}

    MoveRange &operator=(const MoveRange &v) {
        p_range = v.p_range;
        return *this;
    }
    MoveRange &operator=(MoveRange &&v) {
        p_range = octa::move(v.p_range);
        return *this;
    }
    MoveRange &operator=(const T &v) {
        p_range = v;
        return *this;
    }
    MoveRange &operator=(T &&v) {
        p_range = octa::move(v);
        return *this;
    }

    bool empty() const { return p_range.empty(); }
    Rsize size() const { return p_range.size(); }

    bool equals_front(const MoveRange &r) const {
        return p_range.equals_front(r.p_range);
    }
    bool equals_back(const MoveRange &r) const {
        return p_range.equals_back(r.p_range);
    }

    RangeDifference<T> distance_front(const MoveRange &r) const {
        return p_range.distance_front(r.p_range);
    }
    RangeDifference<T> distance_back(const MoveRange &r) const {
        return p_range.distance_back(r.p_range);
    }

    bool pop_front() { return p_range.pop_front(); }
    bool pop_back() { return p_range.pop_back(); }

    bool push_front() { return p_range.push_front(); }
    bool push_back() { return p_range.push_back(); }

    Rsize pop_front_n(Rsize n) { return p_range.pop_front_n(n); }
    Rsize pop_back_n(Rsize n) { return p_range.pop_back_n(n); }

    Rsize push_front_n(Rsize n) { return p_range.push_front_n(n); }
    Rsize push_back_n(Rsize n) { return p_range.push_back_n(n); }

    Rref front() const { return octa::move(p_range.front()); }
    Rref back() const { return octa::move(p_range.back()); }

    Rref operator[](Rsize i) const { return octa::move(p_range[i]); }

    MoveRange<T> slice(Rsize start, Rsize end) const {
        return MoveRange<T>(p_range.slice(start, end));
    }

    void put(const Rval &v) { p_range.put(v); }
    void put(Rval &&v) { p_range.put(octa::move(v)); }
};

template<typename T>
struct NumberRange: InputRange<NumberRange<T>, ForwardRangeTag, T, T> {
    NumberRange(): p_a(0), p_b(0), p_step(0) {}
    NumberRange(const NumberRange &it): p_a(it.p_a), p_b(it.p_b),
        p_step(it.p_step) {}
    NumberRange(T a, T b, T step = T(1)): p_a(a), p_b(b),
        p_step(step) {}
    NumberRange(T v): p_a(0), p_b(v), p_step(1) {}

    bool empty() const { return p_a * p_step >= p_b * p_step; }

    bool equals_front(const NumberRange &range) const {
        return p_a == range.p_a;
    }

    bool pop_front() { p_a += p_step; return true; }
    T front() const { return p_a; }

private:
    T p_a, p_b, p_step;
};

template<typename T>
NumberRange<T> range(T a, T b, T step = T(1)) {
    return NumberRange<T>(a, b, step);
}

template<typename T>
NumberRange<T> range(T v) {
    return NumberRange<T>(v);
}

template<typename T>
struct PointerRange: InputRange<PointerRange<T>, FiniteRandomAccessRangeTag, T> {
    PointerRange(): p_beg(nullptr), p_end(nullptr) {}
    PointerRange(T *beg, T *end): p_beg(beg), p_end(end) {}
    PointerRange(T *beg, octa::Size n): p_beg(beg), p_end(beg + n) {}

    template<typename U>
    PointerRange(const PointerRange<U> &v, octa::EnableIf<
        octa::IsConvertible<U *, T *>::value, bool
    > = true): p_beg(&v[0]), p_end(&v[v.size()]) {}

    PointerRange &operator=(const PointerRange &v) {
        p_beg = v.p_beg;
        p_end = v.p_end;
        return *this;
    }

    /* satisfy InputRange / ForwardRange */
    bool empty() const { return p_beg == p_end; }

    bool pop_front() {
        if (p_beg == p_end) return false;
        ++p_beg;
        return true;
    }
    bool push_front() {
        --p_beg; return true;
    }

    octa::Size pop_front_n(octa::Size n) {
        octa::Size olen = p_end - p_beg;
        p_beg += n;
        if (p_beg > p_end) {
            p_beg = p_end;
            return olen;
        }
        return n;
    }

    octa::Size push_front_n(octa::Size n) {
        p_beg -= n; return true;
    }

    T &front() const { return *p_beg; }

    bool equals_front(const PointerRange &range) const {
        return p_beg == range.p_beg;
    }

    octa::Ptrdiff distance_front(const PointerRange &range) const {
        return range.p_beg - p_beg;
    }

    /* satisfy BidirectionalRange */
    bool pop_back() {
        if (p_end == p_beg) return false;
        --p_end;
        return true;
    }
    bool push_back() {
        ++p_end; return true;
    }

    octa::Size pop_back_n(octa::Size n) {
        octa::Size olen = p_end - p_beg;
        p_end -= n;
        if (p_end < p_beg) {
            p_end = p_beg;
            return olen;
        }
        return n;
    }

    octa::Size push_back_n(octa::Size n) {
        p_end += n; return true;
    }

    T &back() const { return *(p_end - 1); }

    bool equals_back(const PointerRange &range) const {
        return p_end == range.p_end;
    }

    octa::Ptrdiff distance_back(const PointerRange &range) const {
        return range.p_end - p_end;
    }

    /* satisfy FiniteRandomAccessRange */
    octa::Size size() const { return p_end - p_beg; }

    PointerRange slice(octa::Size start, octa::Size end) const {
        return PointerRange(p_beg + start, p_beg + end);
    }

    T &operator[](octa::Size i) const { return p_beg[i]; }

    /* satisfy OutputRange */
    void put(const T &v) {
        *(p_beg++) = v;
    }
    void put(T &&v) {
        *(p_beg++) = octa::move(v);
    }

private:
    T *p_beg, *p_end;
};

template<typename T, octa::Size N>
PointerRange<T> iter(T (&array)[N]) {
    return PointerRange<T>(array, N);
}

template<typename T, typename S>
struct EnumeratedValue {
    S index;
    T value;
};

template<typename T>
struct EnumeratedRange: InputRange<EnumeratedRange<T>,
    CommonType<RangeCategory<T>, ForwardRangeTag>, RangeValue<T>,
    EnumeratedValue<RangeReference<T>, RangeSize<T>>,
    RangeSize<T>
> {
private:
    using Rref = RangeReference<T>;
    using Rsize = RangeSize<T>;

    T p_range;
    Rsize p_index;

public:
    EnumeratedRange(): p_range(), p_index(0) {}

    EnumeratedRange(const T &range): p_range(range), p_index(0) {}

    EnumeratedRange(const EnumeratedRange &it):
        p_range(it.p_range), p_index(it.p_index) {}

    EnumeratedRange(EnumeratedRange &&it):
        p_range(octa::move(it.p_range)), p_index(it.p_index) {}

    EnumeratedRange &operator=(const EnumeratedRange &v) {
        p_range = v.p_range;
        p_index = v.p_index;
        return *this;
    }
    EnumeratedRange &operator=(EnumeratedRange &&v) {
        p_range = octa::move(v.p_range);
        p_index = v.p_index;
        return *this;
    }
    EnumeratedRange &operator=(const T &v) {
        p_range = v;
        p_index = 0;
        return *this;
    }
    EnumeratedRange &operator=(T &&v) {
        p_range = octa::move(v);
        p_index = 0;
        return *this;
    }

    bool empty() const { return p_range.empty(); }

    bool equals_front(const EnumeratedRange &r) const {
        return p_range.equals_front(r.p_range);
    }

    bool pop_front() {
        if (p_range.pop_front()) {
            ++p_index;
            return true;
        }
        return false;
    }

    Rsize pop_front_n(Rsize n) {
        Rsize ret = p_range.pop_front_n(n);
        p_index += ret;
        return ret;
    }

    EnumeratedValue<Rref, Rsize> front() const {
        return EnumeratedValue<Rref, Rsize> { p_index, p_range.front() };
    }
};

template<typename T>
EnumeratedRange<T> enumerate(const T &it) {
    return EnumeratedRange<T>(it);
}

template<typename T>
struct TakeRange: InputRange<TakeRange<T>,
    CommonType<RangeCategory<T>, ForwardRangeTag>,
    RangeValue<T>, RangeReference<T>, RangeSize<T>
> {
private:
    T p_range;
    RangeSize<T> p_remaining;
public:
    TakeRange(): p_range(), p_remaining(0) {}
    TakeRange(const T &range, RangeSize<T> rem): p_range(range),
        p_remaining(rem) {}
    TakeRange(const TakeRange &it): p_range(it.p_range),
        p_remaining(it.p_remaining) {}
    TakeRange(TakeRange &&it): p_range(octa::move(it.p_range)),
        p_remaining(it.p_remaining) {}

    TakeRange &operator=(const TakeRange &v) {
        p_range = v.p_range; p_remaining = v.p_remaining; return *this;
    }
    TakeRange &operator=(TakeRange &&v) {
        p_range = octa::move(v.p_range);
        p_remaining = v.p_remaining;
        return *this;
    }

    bool empty() const { return (p_remaining <= 0) || p_range.empty(); }

    bool pop_front() {
        if (p_range.pop_front()) {
            --p_remaining;
            return true;
        }
        return false;
    }

    RangeSize<T> pop_front_n(RangeSize<T> n) {
        RangeSize<T> ret = p_range.pop_front_n(n);
        p_remaining -= ret;
        return ret;
    }

    RangeReference<T> front() const { return p_range.front(); }

    bool equals_front(const TakeRange &r) const {
        return p_range.equals_front(r.p_range);
    }
};

template<typename T>
TakeRange<T> take(const T &it, RangeSize<T> n) {
    return TakeRange<T>(it, n);
}

template<typename T>
struct ChunksRange: InputRange<ChunksRange<T>,
    CommonType<RangeCategory<T>, ForwardRangeTag>,
    TakeRange<T>, TakeRange<T>, RangeSize<T>
> {
private:
    T p_range;
    RangeSize<T> p_chunksize;
public:
    ChunksRange(): p_range(), p_chunksize(0) {}
    ChunksRange(const T &range, RangeSize<T> chs): p_range(range),
        p_chunksize(chs) {}
    ChunksRange(const ChunksRange &it): p_range(it.p_range),
        p_chunksize(it.p_chunksize) {}
    ChunksRange(ChunksRange &&it): p_range(octa::move(it.p_range)),
        p_chunksize(it.p_chunksize) {}

    ChunksRange &operator=(const ChunksRange &v) {
        p_range = v.p_range; p_chunksize = v.p_chunksize; return *this;
    }
    ChunksRange &operator=(ChunksRange &&v) {
        p_range = octa::move(v.p_range);
        p_chunksize = v.p_chunksize;
        return *this;
    }

    bool empty() const { return p_range.empty(); }

    bool equals_front(const ChunksRange &r) const {
        return p_range.equals_front(r.p_range);
    }

    bool pop_front() { return p_range.pop_front_n(p_chunksize) > 0; }
    RangeSize<T> pop_front_n(RangeSize<T> n) {
        return p_range.pop_front_n(p_chunksize * n) / p_chunksize;
    }

    TakeRange<T> front() const { return take(p_range, p_chunksize); }
};

template<typename T>
ChunksRange<T> chunks(const T &it, RangeSize<T> chs) {
    return ChunksRange<T>(it, chs);
}

// range of
template<typename T> using RangeOf = decltype(octa::iter(octa::declval<T>()));

} /* namespace octa */

#endif