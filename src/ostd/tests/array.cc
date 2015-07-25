#include <assert.h>
#include "ostd/array.hh"
#include "ostd/string.hh"

using namespace ostd;

int main() {
    Array<int, 5> x = { 2, 4, 8, 16, 32 };

    assert(x.front() == 2);
    assert(x.back() == 32);

    assert(x[0] == 2);
    assert(x[2] == 8);

    assert(*(x.at(0)) == x[0]);
    assert(*(x.at(3)) == x[3]);

    assert(x.size() == 5);

    assert(!x.empty());

    assert(x.in_range(4));
    assert(x.in_range(0));
    assert(!x.in_range(5));

    assert(x.data()[0] == x[0]);

    auto r = x.iter();
    assert(r.front() == 2);
    assert(r.back() == 32);

    Array<int, 5> z;
    x.swap(z);

    assert(z.front() == 2);
    assert(z.back() == 32);

    assert(z.size() == 5);

    assert(to_string(z) == "{2, 4, 8, 16, 32}");

    return 0;
}