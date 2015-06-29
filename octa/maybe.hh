/* Option type implementation. Inspired by libc++.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_MAYBE_HH
#define OCTA_MAYBE_HH

#include "octa/types.hh"
#include "octa/type_traits.hh"
#include "octa/memory.hh"
#include "octa/utility.hh"
#include "octa/initializer_list.hh"
#include "octa/functional.hh"

namespace octa {

struct InPlace {};
constexpr InPlace in_place = InPlace();

struct Nothing {
    explicit constexpr Nothing(int) {}
};
constexpr Nothing nothing = Nothing(0);

namespace detail {
    template<typename T, bool = octa::IsTriviallyDestructible<T>::value>
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
            if (p_engaged) ::new(octa::address_of(p_value)) Value(v.p_value);
        }

        MaybeStorage(MaybeStorage &&v): p_engaged(v.p_engaged) {
            if (p_engaged)
                ::new(octa::address_of(p_value)) Value(octa::move(v.p_value));
        }

        constexpr MaybeStorage(const Value &v): p_value(v), p_engaged(true) {}
        constexpr MaybeStorage(Value &&v): p_value(octa::move(v)), p_engaged(true) {}

        template<typename ...A> constexpr MaybeStorage(octa::InPlace, A &&...args):
            p_value(octa::forward<A>(args)...), p_engaged(true) {}

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
            if (p_engaged) ::new(octa::address_of(p_value)) Value(v.p_value);
        }

        MaybeStorage(MaybeStorage &&v): p_engaged(v.p_engaged) {
            if (p_engaged)
                ::new(octa::address_of(p_value)) Value(octa::move(v.p_value));
        }

        constexpr MaybeStorage(const Value &v): p_value(v), p_engaged(true) {}
        constexpr MaybeStorage(Value &&v):
            p_value(octa::move(v)), p_engaged(true) {}

        template<typename ...A>
        constexpr MaybeStorage(octa::InPlace, A &&...args):
            p_value(octa::forward<A>(args)...), p_engaged(true) {}
    };
}

template<typename T>
class Maybe: private octa::detail::MaybeStorage<T> {
    using Base = octa::detail::MaybeStorage<T>;
public:
    using Value = T;

    static_assert(!octa::IsReference<T>::value,
        "Initialization of Maybe with a reference type is not allowed.");
    static_assert(!octa::IsSame<octa::RemoveCv<T>, octa::InPlace>::value,
        "Initialization of Maybe with InPlace is not allowed.");
    static_assert(!octa::IsSame<octa::RemoveCv<T>, octa::Nothing>::value,
        "Initialization of Maybe with Nothing is not allowed.");
    static_assert(octa::IsObject<T>::value,
        "Initialization of Maybe with non-object type is not allowed.");
    static_assert(octa::IsDestructible<T>::value,
        "Initialization of Maybe with a non-destructible object is not allowed.");

    constexpr Maybe() {}
    Maybe(const Maybe &) = default;
    Maybe(Maybe &&) = default;
    constexpr Maybe(octa::Nothing) {}
    constexpr Maybe(const Value &v): Base(v) {}
    constexpr Maybe(Value &&v): Base(octa::move(v)) {}

    template<typename ...A, typename = octa::EnableIf<
        octa::IsConstructible<T, A...>::value>>
    constexpr explicit Maybe(octa::InPlace, A &&...args): Base(octa::in_place,
        octa::forward<A>(args)...) {}

    template<typename U, typename ...A, typename = typename octa::EnableIf<
        octa::IsConstructible<T, std::initializer_list<U> &, A...>::value>>
    constexpr explicit
    Maybe(octa::InPlace, std::initializer_list<U> il, A &&...args):
        Base(octa::in_place, il, octa::forward<A>(args)...) {}

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
                ::new(octa::address_of(this->p_value)) Value(v.p_value);
            this->p_engaged = v.p_engaged;
        }
        return *this;
    }

    Maybe &operator=(Maybe &&v) {
        if (this->p_engaged == v.p_engaged) {
            if (this->p_engaged) this->p_value = octa::move(v.p_value);
        } else {
            if (this->p_engaged)
                this->p_value.~Value();
            else {
                ::new(octa::address_of(this->p_value))
                    Value(octa::move(v.p_value));
            }
            this->p_engaged = v.p_engaged;
        }
        return *this;
    }

    template<typename U, typename = octa::EnableIf<
        octa::IsSame<octa::RemoveReference<U>, Value>::value &&
        octa::IsConstructible<Value, U>::value &&
        octa::IsAssignable<Value &, U>::value
    >>
    Maybe &operator=(U &&v) {
        if (this->p_engaged) {
            this->p_value = octa::forward<U>(v);
        } else {
            ::new(octa::address_of(this->p_value)) Value(octa::forward<U>(v));
            this->p_engaged = true;
        }
        return *this;
    }

    template<typename ...A, typename = octa::EnableIf<
        octa::IsConstructible<Value, A...>::value
    >>
    void emplace(A &&...args) {
        *this = octa::nothing;
        ::new(octa::address_of(this->p_value))
            Value(octa::forward<A>(args)...);
        this->p_engaged = true;
    }

    template<typename U, typename ...A, typename = octa::EnableIf<
        octa::IsConstructible<Value, std::initializer_list<U> &, A...>::value
    >>
    void emplace(std::initializer_list<U> il, A &&...args) {
        *this = octa::nothing;
        ::new(octa::address_of(this->p_value))
            Value(il, octa::forward<A>(args)...);
        this->p_engaged = true;
    }

    constexpr const Value *operator->() const {
        return octa::address_of(this->p_value);
    }

    Value *operator->() {
        return octa::address_of(this->p_value);
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
        static_assert(octa::IsCopyConstructible<Value>::value,
            "Maybe<T>::value_or: T must be copy constructible");
        static_assert(octa::IsConvertible<U, Value>::value,
            "Maybe<T>::value_or: U must be convertible to T");
        return this->p_engaged ? this->p_value : Value(octa::forward<U>(v));
    }

    template<typename U>
    Value value_or(U &&v) && {
        static_assert(octa::IsMoveConstructible<Value>::value,
            "Maybe<T>::value_or: T must be copy constructible");
        static_assert(octa::IsConvertible<U, Value>::value,
            "Maybe<T>::value_or: U must be convertible to T");
        return this->p_engaged ? octa::move(this->p_value)
                               : Value(octa::forward<U>(v));
    }

    void swap(Maybe &v) {
        if (this->p_engaged == v.p_engaged) {
            if (this->p_engaged) octa::swap(this->p_value, v.p_value);
        } else {
            if (this->p_engaged) {
                ::new(octa::address_of(v.p_value))
                    Value(octa::move(this->p_value));
                this->p_value.~Value();
            } else {
                ::new(octa::address_of(this->p_value))
                    Value(octa::move(v.p_value));
                v.p_value.~Value();
            }
            octa::swap(this->p_engaged, v.p_engaged);
        }
    }

    octa::Size to_hash() const {
        return this->p_engaged ? octa::ToHash<T>()(this->p_value) : 0;
    }
};

/* maybe vs maybe */

template<typename T>
static inline constexpr bool operator==(const Maybe<T> &a, const Maybe<T> &b) {
    return (bool(a) != bool(b)) ? false : (!bool(a) ? true : (*a == *b));
}

template<typename T>
static inline constexpr bool operator!=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(a == b);
}

template<typename T>
static inline constexpr bool operator<(const Maybe<T> &a, const Maybe<T> &b) {
    return !bool(b) ? false : (!bool(a) ? true : (*a < *b));
}

template<typename T>
static inline constexpr bool operator>(const Maybe<T> &a, const Maybe<T> &b) {
    return b < a;
}

template<typename T>
static inline constexpr bool operator<=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(b < a);
}

template<typename T>
static inline constexpr bool operator>=(const Maybe<T> &a, const Maybe<T> &b) {
    return !(a < b);
}

/* maybe vs nothing */

template<typename T>
static inline constexpr bool operator==(const Maybe<T> &v, Nothing) {
    return !bool(v);
}

template<typename T>
static inline constexpr bool operator==(Nothing, const Maybe<T> &v) {
    return !bool(v);
}

template<typename T>
static inline constexpr bool operator!=(const Maybe<T> &v, Nothing) {
    return bool(v);
}

template<typename T>
static inline constexpr bool operator!=(Nothing, const Maybe<T> &v) {
    return bool(v);
}

template<typename T>
static inline constexpr bool operator<(const Maybe<T> &, Nothing) {
    return false;
}

template<typename T>
static inline constexpr bool operator<(Nothing, const Maybe<T> &v) {
    return bool(v);
}

template<typename T>
static inline constexpr bool operator<=(const Maybe<T> &v, Nothing) {
    return !bool(v);
}

template<typename T>
static inline constexpr bool operator<=(Nothing, const Maybe<T> &) {
    return true;
}

template<typename T>
static inline constexpr bool operator>(const Maybe<T> &v, Nothing) {
    return bool(v);
}

template<typename T>
static inline constexpr bool operator>(Nothing, const Maybe<T> &) {
    return false;
}

template<typename T>
static inline constexpr bool operator>=(const Maybe<T> &, Nothing) {
    return true;
}

template<typename T>
static inline constexpr bool operator>=(Nothing, const Maybe<T> &v) {
    return !bool(v);
}

/* maybe vs T */

template<typename T>
static inline constexpr bool operator==(const Maybe<T> &a, const T &b) {
    return bool(a) ? (*a == b) : false;
}

template<typename T>
static inline constexpr bool operator==(const T &b, const Maybe<T> &a) {
    return bool(a) ? (*a == b) : false;
}

template<typename T>
static inline constexpr bool operator!=(const Maybe<T> &a, const T &b) {
    return bool(a) ? !(*a == b) : true;
}

template<typename T>
static inline constexpr bool operator!=(const T &b, const Maybe<T> &a) {
    return bool(a) ? !(*a == b) : true;
}

template<typename T>
static inline constexpr bool operator<(const Maybe<T> &a, const T &b) {
    return bool(a) ? octa::Less<T>()(*a, b) : true;
}

template<typename T>
static inline constexpr bool operator<(const T &b, const Maybe<T> &a) {
    return bool(a) ? octa::Less<T>()(b, *a) : false;
}

template<typename T>
static inline constexpr bool operator<=(const Maybe<T> &a, const T &b) {
    return !(a > b);
}

template<typename T>
static inline constexpr bool operator<=(const T &b, const Maybe<T> &a) {
    return !(b > a);
}

template<typename T>
static inline constexpr bool operator>(const Maybe<T> &a, const T &b) {
    return bool(a) ? (b < a) : true;
}

template<typename T>
static inline constexpr bool operator>(const T &b, const Maybe<T> &a) {
    return bool(a) ? (a < b) : true;
}

template<typename T>
static inline constexpr bool operator>=(const Maybe<T> &a, const T &b) {
    return !(a < b);
}

template<typename T>
static inline constexpr bool operator>=(const T &b, const Maybe<T> &a) {
    return !(b < a);
}

/* make maybe */

template<typename T>
constexpr Maybe<octa::Decay<T>> make_maybe(T &&v) {
    return Maybe<octa::Decay<T>>(octa::forward<T>(v));
}

} /* namespace octa */

#endif