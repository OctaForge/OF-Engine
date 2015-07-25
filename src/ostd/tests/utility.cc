#include <assert.h>
#include "ostd/utility.hh"
#include "ostd/string.hh"

using namespace ostd;

struct Foo {
    int x;
    Foo(): x(5) {}
    Foo(int x): x(x) {}
    Foo(const Foo &x): x(x.x) {}
    Foo(Foo &&x): x(x.x) { x.x = 0; }
    Foo &operator=(int _x) {
        x = _x;
        return *this;
    }
};

struct NotSwappable {
    int i;
    NotSwappable(int i): i(i) {}
};

struct Swappable {
    int i;
    bool swapped;
    Swappable(int i): i(i), swapped(false) {}
    void swap(Swappable &v) {
        auto j = i;
        i = v.i;
        v.i = j;
        swapped = v.swapped = true;
    }
};

int main() {
    Foo bar(150);
    Foo baz(move(bar));

    assert(bar.x == 0);
    assert(baz.x == 150);

    Foo cp(baz);

    assert(baz.x == 150);
    assert(cp.x == 150);

    auto i = exchange(baz, 20);
    assert(baz.x == 20);
    assert(i.x == 150);

    NotSwappable nsx(10);
    NotSwappable nsy(20);

    swap(nsx, nsy);
    assert(nsx.i == 20);
    assert(nsy.i == 10);

    Swappable sx(10);
    Swappable sy(20);

    assert(!sx.swapped);
    assert(!sy.swapped);

    swap(sx, sy);
    assert(sx.swapped);
    assert(sy.swapped);
    assert(sx.i == 20);
    assert(sy.i == 10);

    int ai[3] = { 5, 10, 15 };
    int bi[3] = { 6, 11, 16 };
    swap(ai, bi);

    assert(ai[0] == 6);
    assert(bi[2] == 15);

    auto x = make_pair(5, 3.14f);

    assert((IsSame<decltype(x.first), int>::value));
    assert((IsSame<decltype(x.second), float>::value));

    assert(x.first == 5);
    assert(x.second == 3.14f);

    auto st = make_pair(5, 10);
    assert(to_string(st) == "{5, 10}");

    return 0;
}