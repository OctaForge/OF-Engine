#include <assert.h>
#include "ostd/vector.hh"
#include "ostd/string.hh"

using namespace ostd;

int main() {
    Vector<int> x = { 5, 10, 15, 20 };

    assert(x.front() == 5);
    assert(x.back() == 20);

    assert(x[0] == 5);
    assert(x[2] == 15);

    assert(*(x.at(0)) == x[0]);
    assert(*(x.at(3)) == x[3]);

    assert(x.data()[0] == x[0]);

    assert(x.size() == 4);

    Vector<int> y(5, 10);

    assert(y.size() == 5);
    assert(y.front() == 10);
    assert(y.back() == 10);

    Vector<int> z(x);

    assert(x.front() == z.front());
    assert(x.back() == z.back());

    z.clear();

    assert(z.size() == 0);
    assert(z.capacity() != 0);
    assert(z.empty());

    z = move(y);

    assert(z.size() == 5);
    assert(y.size() == 0);
    assert(z.front() == 10);
    assert(z.back() == 10);

    z.resize(150, 5);
    assert(z.size() == 150);
    assert(z.front() == 10);
    assert(z.back() == 5);

    assert(z.push(30) == 30);
    assert(z.back() == 30);

    assert(z.emplace_back(20) == 20);
    assert(z.back() == 20);

    z.clear();
    z.resize(10, 5);

    assert(z.in_range(9));
    assert(z.in_range(0));
    assert(!z.in_range(10));

    z.insert(2, 4);
    assert(z[2] == 4);
    assert(z[0] == 5);
    assert(z[3] == 5);
    assert(z.size() == 11);

    auto r = z.iter();
    assert(r.front() == 5);
    assert(r.back() == 5);
    assert(r[2] == 4);

    auto r2 = iter(z);
    assert(r.front() == r2.front());

    Vector<int> w;
    w.swap(z);

    assert(z.size() == 0);
    assert(w.size() != 0);
    assert(w.front() == 5);
    assert(w.back() == 5);

    int pushn[] = { 3, 2, 1 };
    w.push_n(pushn, 3);

    assert(to_string(w) == "{5, 5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 3, 2, 1}");

    return 0;
}