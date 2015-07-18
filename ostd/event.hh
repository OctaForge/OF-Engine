/* Signals/slots for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_EVENT_HH
#define OSTD_EVENT_HH

#include "ostd/functional.hh"
#include "ostd/utility.hh"

namespace ostd {

namespace detail {
    template<typename C, typename ...A>
    struct SignalBase {
        SignalBase(C *cl): p_class(cl), p_funcs(nullptr), p_nfuncs(0) {}

        SignalBase(const SignalBase &ev): p_class(ev.p_class),
                                        p_nfuncs(ev.p_nfuncs) {
            using Func = Function<void(C &, A...)>;
            Func *nbuf = (Func *)new byte[sizeof(Func) * p_nfuncs];
            for (Size i = 0; i < p_nfuncs; ++i)
                new (&nbuf[i]) Func(ev.p_funcs[i]);
            p_funcs = nbuf;
        }

        SignalBase(SignalBase &&ev): p_class(nullptr), p_funcs(nullptr),
                                   p_nfuncs(0) {
            swap(ev);
        }

        SignalBase &operator=(const SignalBase &ev) {
            using Func = Function<void(C &, A...)>;
            p_class = ev.p_class;
            p_nfuncs = ev.p_nfuncs;
            Func *nbuf = (Func *)new byte[sizeof(Func) * p_nfuncs];
            for (Size i = 0; i < p_nfuncs; ++i)
                new (&nbuf[i]) Func(ev.p_funcs[i]);
            p_funcs = nbuf;
            return *this;
        }

        SignalBase &operator=(SignalBase &&ev) {
            swap(ev);
            return *this;
        }

        ~SignalBase() { clear(); }

        void clear() {
            for (Size i = 0; i < p_nfuncs; ++i)
                p_funcs[i].~Function<void(C &, A...)>();
            delete[] (byte *)p_funcs;
            p_funcs = nullptr;
            p_nfuncs = 0;
        }

        template<typename F>
        Size connect(F &&func) {
            using Func = Function<void(C &, A...)>;
            for (Size i = 0; i < p_nfuncs; ++i)
                if (!p_funcs[i]) {
                    p_funcs[i] = forward<F>(func);
                    return i;
                }
            Func *nbuf = (Func *)new byte[sizeof(Func) * (p_nfuncs + 1)];
            for (Size i = 0; i < p_nfuncs; ++i) {
                new (&nbuf[i]) Func(move(p_funcs[i]));
                p_funcs[i].~Func();
            }
            new (&nbuf[p_nfuncs]) Func(forward<F>(func));
            delete[] (byte *)p_funcs;
            p_funcs = nbuf;
            return p_nfuncs++;
        }

        bool disconnect(Size idx) {
            if ((idx >= p_nfuncs) || !p_funcs[idx]) return false;
            p_funcs[idx] = nullptr;
            return true;
        }

        template<typename ...Args>
        void emit(Args &&...args) const {
            if (!p_class) return;
            for (Size i = 0; i < p_nfuncs; ++i)
                if (p_funcs[i]) p_funcs[i](*p_class, args...);
        }

        C *get_class() const {
            return p_class;
        }

        C *set_class(C *cl) {
            C *ocl = p_class;
            p_class = cl;
            return ocl;
        }

        void swap(SignalBase &ev) {
            detail::swap_adl(p_class, ev.p_class);
            detail::swap_adl(p_funcs, ev.p_funcs);
            detail::swap_adl(p_nfuncs, ev.p_nfuncs);
        }

    private:
        C *p_class;
        Function<void(C &, A...)> *p_funcs;
        Size p_nfuncs;
    };
} /* namespace detail */

template<typename C, typename ...A>
struct Signal {
private:
    using Base = detail::SignalBase<C, A...>;
    Base p_base;
public:
    Signal(C *cl): p_base(cl) {}
    Signal(const Signal &ev): p_base(ev.p_base) {}
    Signal(Signal &&ev): p_base(move(ev.p_base)) {}

    Signal &operator=(const Signal &ev) {
        p_base = ev.p_base;
        return *this;
    }

    Signal &operator=(Signal &&ev) {
        p_base = move(ev.p_base);
        return *this;
    }

    void clear() { p_base.clear(); }

    template<typename F>
    Size connect(F &&func) { return p_base.connect(forward<F>(func)); }

    bool disconnect(Size idx) { return p_base.disconnect(idx); }

    template<typename ...Args>
    void emit(Args &&...args) { p_base.emit(forward<Args>(args)...); }

    template<typename ...Args>
    void operator()(Args &&...args) { emit(forward<Args>(args)...); }

    C *get_class() const { return p_base.get_class(); }
    C *set_class(C *cl) { return p_base.set_class(cl); }

    void swap(Signal &ev) { p_base.swap(ev.p_base); }
};

template<typename C, typename ...A>
struct Signal<const C, A...> {
private:
    using Base = detail::SignalBase<const C, A...>;
    Base p_base;
public:
    Signal(C *cl): p_base(cl) {}
    Signal(const Signal &ev): p_base(ev.p_base) {}
    Signal(Signal &&ev): p_base(move(ev.p_base)) {}

    Signal &operator=(const Signal &ev) {
        p_base = ev.p_base;
        return *this;
    }

    Signal &operator=(Signal &&ev) {
        p_base = move(ev.p_base);
        return *this;
    }

    void clear() { p_base.clear(); }

    template<typename F>
    Size connect(F &&func) { return p_base.connect(forward<F>(func)); }

    bool disconnect(Size idx) { return p_base.disconnect(idx); }

    template<typename ...Args>
    void emit(Args &&...args) const { p_base.emit(forward<Args>(args)...); }

    template<typename ...Args>
    void operator()(Args &&...args) const { emit(forward<Args>(args)...); }

    C *get_class() const { return p_base.get_class(); }
    C *set_class(C *cl) { return p_base.set_class(cl); }

    void swap(Signal &ev) { p_base.swap(ev.p_base); }
};

} /* namespace ostd */

#endif