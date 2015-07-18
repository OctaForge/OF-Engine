/* Option type implementation. Inspired by libc++.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_MAYBE_HH
#define OSTD_MAYBE_HH

#include "ostd/types.hh"
#include "ostd/type_traits.hh"
#include "ostd/memory.hh"
#include "ostd/utility.hh"
#include "ostd/initializer_list.hh"
#include "ostd/functional.hh"

namespace ostd {

struct InPlace {};
constexpr InPlace in_place = InPlace();

struct Nothing {
    explicit constexpr Nothing(int) {}
};
constexpr Nothing nothing = Nothing(0);

namespace detail {
    template<typename T, bool = IsTriviallyDestructible<T>::value>
    class MaybeStorage {
    protected:
        using Value = T;
        union {
            char p_null_state;
            Value p_value;
        };
        bool p_engaged = false;

        constexpr MaybeStorage(): p_null_state('\0') {}

        MaybeStorage(const MaybeStorage &v): p_engaged(v.p_engaged) {
            if (p_engaged) ::new(address_of(p_value)) Value(v.p_value);
        }

        MaybeStorage(MaybeStorage &&v): p_engaged(v.p_engaged) {
            if (p_engaged)
                ::new(address_of(p_value)) Value(move(v.p_value));
        }

        constexpr MaybeStorage(const Value &v): p_value(v), p_engaged(true) {}
        constexpr MaybeStorage(Value &&v): p_value(move(v)), p_engaged(true) {}

        template<typename ...A> constexpr MaybeStorage(InPlace, A &&...args):
            p_value(forward<A>(args)...), p_engaged(true) {}

        ~MaybeStorage() {
            if (p_engaged) p_value.~Value();
        }
    };

    template<typename T>
    class MaybeStorage<T, true> {
    protected:
        using Value = T;
        union {
            char p_null_state;
            Value p_value;
        };
        bool p_engaged = false;

        constexpr MaybeStorage(): p_null_state('\0') {}

        MaybeStorage(const MaybeStorage &v): p_engaged(v.p_engaged) {
            if (p_engaged) ::new(address_of(p_value)) Value(v.p_value);
        }

        MaybeStorage(MaybeStorage &&v): p_engaged(v.p_engaged) {
            if (p_engaged)
                ::new(address_of(p_value)) Value(move(v.p_value));
        }

        constexpr MaybeStorage(const Value &v): p_value(v), p_engaged(true) {}
        constexpr MaybeStorage(Value &&v):
            p_value(move(v)), p_engaged(true) {}

        template<typename ...A>
        constexpr MaybeStorage(InPlace, A &&...args):
            p_value(forward<A>(args)...), p_engaged(true) {}
    };
}

template<typename T>
class Maybe: private detail::MaybeStorage<T> {
    using Base = detail::MaybeStorage<T>;
public:
    using Value = T;

    static_assert(!IsReference<T>::value,
        "Initialization of Maybe with a reference type is not allowed.");
    static_assert(!IsSame<RemoveCv<T>, InPlace>::value,
        "Initialization of Maybe with InPlace is not allowed.");
    static_assert(!IsSame<RemoveCv<T>, Nothing>::value,
        "Initialization of Maybe with Nothing is not allowed.");
    static_assert(IsObject<T>::value,
        "Initialization of Maybe with non-object type is not allowed.");
    static_assert(IsDestructible<T>::value,
        "Initialization of Maybe with a non-destructible object is not allowed.");

    constexpr Maybe() {}
    Maybe(const Maybe &) = default;
    Maybe(Maybe &&) = default;
    constexpr Maybe(Nothing) {}
    constexpr Maybe(const Value &v): Base(v) {}
    constexpr Maybe(Value &&v): Base(move(v)) {}

    template<typename ...A, typename = EnableIf<
        IsConstructible<T, A...>::value>>
    constexpr explicit Maybe(InPlace, A &&...args): Base(in_place,
        forward<A>(args)...) {}

    template<typename U, typename ...A, typename = EnableIf<
        IsConstructible<T, std::initializer_list<U> &, A...>::value>>
    constexpr explicit
    Maybe(InPlace, std::initializer_list<U> il, A &&...args):
        Base(in_place, il, forward<A>(args)...) {}

    ~Maybe() = default;

    Maybe &operator=(Nothing) {
        if (this->p_engaged) {
            this->p_value.~Value();
            this->p_engaged = false;
        }
        return *this;
    }

    Maybe &operator=(const Maybe &v) {
        if (this->p_engaged == v.p_engaged) {
            if (this->p_engaged) this->p_value = v.p_value;
        } else {
            if (this->p_engaged)
                this->p_value.~Value();
            else
                ::new(address_of(this->p_value)) Value(v.p_value);
            this->p_engaged = v.p_engaged;
        }
        return *this;
    }

    Maybe &operator=(Maybe &&v) {
        if (this->p_engaged == v.p_engaged) {
            if (this->p_engaged) this->p_value = move(v.p_value);
        } else {
            if (this->p_engaged)
                this->p_value.~Value();
            else {
                ::new(address_of(this->p_value)) Value(move(v.p_value));
            }
            this->p_engaged = v.p_engaged;
        }
        return *this;
    }

    template<typename U, typename = EnableIf<
        IsSame<RemoveReference<U>, Value>::value &&
        IsConstructible<Value, U>::value &&
        IsAssignable<Value &, U>::value
    >>
    Maybe &operator=(U &&v) {
        if (this->p_engaged) {
            this->p_value = forward<U>(v);
        } else {
            ::new(address_of(this->p_value)) Value(forward<U>(v));
            this->p_engaged = true;
        }
        return *this;
    }

    template<typename ...A, typename = EnableIf<
        IsConstructible<Value, A...>::value
    >>
    void emplace(A &&...args) {
        *this = nothing;
        ::new(address_of(this->p_value)) Value(forward<A>(args)...);
        this->p_engaged = true;
    }

    template<typename U, typename ...A, typename = EnableIf<
        IsConstructible<Value, std::initializer_list<U> &, A...>::value
    >>
    void emplace(std::initializer_list<U> il, A &&...args) {
        *this = nothing;
        ::new(address_of(this->p_value))
            Value(il, forward<A>(args)...);
        this->p_engaged = true;
    }

    constexpr const Value *operator->() const {
        return address_of(this->p_value);
    }

    Value *operator->() {
        return address_of(this->p_value);
    }

    constexpr const Value &operator*() const {
        return this->p_value;
    }

    Value &operator*() {
        return this->p_value;
    }

    constexpr explicit operator bool() const { return this->p_engaged; }

    constexpr const Value &value() const {
        return this->p_value;
    }

    Value &value() {
        return this->p_value;
    }

    template<typename U>
    constexpr Value value_or(U &&v) const & {
        static_assert(IsCopyConstructible<Value>::value,
            "Maybe<T>::value_or: T must be copy constructible");
        static_assert(IsConvertible<U, Value>::value,
            "Maybe<T>::value_or: U must be convertible to T");
        return this->p_engaged ? this->p_value : Value(forward<U>(v));
    }

    template<typename U>
    Value value_or(U &&v) && {
        static_assert(IsMoveConstructible<Value>::value,
            "Maybe<T>::value_or: T must be copy constructible");
        static_assert(IsConvertible<U, Value>::value,
            "Maybe<T>::value_or: U must be convertible to T");
        return this->p_engaged ? move(this->p_value)
                               : Value(forward<U>(v));
    }

    void swap(Maybe &v) {
        if (this->p_engaged == v.p_engaged) {
            if (this->p_engaged) detail::swap_adl(this->p_value, v.p_value);
        } else {
            if (this->p_engaged) {
                ::new(address_of(v.p_value)) Value(move(this->p_value));
                this->p_value.~Value();
            } else {
                ::new(address_of(this->p_value)) Value(move(v.p_value));
                v.p_value.~Value();
            }
            detail::swap_adl(this->p_engaged, v.p_engaged);
        }
    }

    Size to_hash() const {
        return this->p_engaged ? ostd::ToHash<T>()(this->p_value) : 0;
    }
};

/* maybe vs maybe */

template<typename T>
inline constexpr bool operator==(const Maybe<T> &a, const Maybe<T> &b) {
    return (bool(a) != bool(b)) ? false : (!bool(a) ? true : (*a == *b));
}

template<typename T>
inline constexpr bool operator!=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(a == b);
}

template<typename T>
inline constexpr bool operator<(const Maybe<T> &a, const Maybe<T> &b) {
    return !bool(b) ? false : (!bool(a) ? true : (*a < *b));
}

template<typename T>
inline constexpr bool operator>(const Maybe<T> &a, const Maybe<T> &b) {
    return b < a;
}

template<typename T>
inline constexpr bool operator<=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(b < a);
}

template<typename T>
inline constexpr bool operator>=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(a < b);
}

/* maybe vs nothing */

template<typename T>
inline constexpr bool operator==(const Maybe<T> &v, Nothing) {
    return !bool(v);
}

template<typename T>
inline constexpr bool operator==(Nothing, const Maybe<T> &v) {
    return !bool(v);
}

template<typename T>
inline constexpr bool operator!=(const Maybe<T> &v, Nothing) {
    return bool(v);
}

template<typename T>
inline constexpr bool operator!=(Nothing, const Maybe<T> &v) {
    return bool(v);
}

template<typename T>
inline constexpr bool operator<(const Maybe<T> &, Nothing) {
    return false;
}

template<typename T>
inline constexpr bool operator<(Nothing, const Maybe<T> &v) {
    return bool(v);
}

template<typename T>
inline constexpr bool operator<=(const Maybe<T> &v, Nothing) {
    return !bool(v);
}

template<typename T>
inline constexpr bool operator<=(Nothing, const Maybe<T> &) {
    return true;
}

template<typename T>
inline constexpr bool operator>(const Maybe<T> &v, Nothing) {
    return bool(v);
}

template<typename T>
inline constexpr bool operator>(Nothing, const Maybe<T> &) {
    return false;
}

template<typename T>
inline constexpr bool operator>=(const Maybe<T> &, Nothing) {
    return true;
}

template<typename T>
inline constexpr bool operator>=(Nothing, const Maybe<T> &v) {
    return !bool(v);
}

/* maybe vs T */

template<typename T>
inline constexpr bool operator==(const Maybe<T> &a, const T &b) {
    return bool(a) ? (*a == b) : false;
}

template<typename T>
inline constexpr bool operator==(const T &b, const Maybe<T> &a) {
    return bool(a) ? (*a == b) : false;
}

template<typename T>
inline constexpr bool operator!=(const Maybe<T> &a, const T &b) {
    return bool(a) ? !(*a == b) : true;
}

template<typename T>
inline constexpr bool operator!=(const T &b, const Maybe<T> &a) {
    return bool(a) ? !(*a == b) : true;
}

template<typename T>
inline constexpr bool operator<(const Maybe<T> &a, const T &b) {
    return bool(a) ? Less<T>()(*a, b) : true;
}

template<typename T>
inline constexpr bool operator<(const T &b, const Maybe<T> &a) {
    return bool(a) ? Less<T>()(b, *a) : false;
}

template<typename T>
inline constexpr bool operator<=(const Maybe<T> &a, const T &b) {
    return !(a > b);
}

template<typename T>
inline constexpr bool operator<=(const T &b, const Maybe<T> &a) {
    return !(b > a);
}

template<typename T>
inline constexpr bool operator>(const Maybe<T> &a, const T &b) {
    return bool(a) ? (b < a) : true;
}

template<typename T>
inline constexpr bool operator>(const T &b, const Maybe<T> &a) {
    return bool(a) ? (a < b) : true;
}

template<typename T>
inline constexpr bool operator>=(const Maybe<T> &a, const T &b) {
    return !(a < b);
}

template<typename T>
inline constexpr bool operator>=(const T &b, const Maybe<T> &a) {
    return !(b < a);
}

/* make maybe */

template<typename T>
inline constexpr Maybe<Decay<T>> make_maybe(T &&v) {
    return Maybe<Decay<T>>(forward<T>(v));
}

} /* namespace ostd */

#endif