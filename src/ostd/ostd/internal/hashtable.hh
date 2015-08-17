/* Internal hash table implementation. Used as a base for set, map etc.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_INTERNAL_HASHTABLE_HH
#define OSTD_INTERNAL_HASHTABLE_HH

#include <string.h>
#include <math.h>

#include "ostd/types.hh"
#include "ostd/utility.hh"
#include "ostd/memory.hh"
#include "ostd/range.hh"
#include "ostd/initializer_list.hh"

namespace ostd {

namespace detail {
    template<typename T>
    struct HashChain {
        HashChain<T> *prev;
        HashChain<T> *next;
        T value;
    };

    template<typename R>
    static inline Size estimate_hrsize(const R &range,
        EnableIf<IsFiniteRandomAccessRange<R>::value, bool> = true
    ) {
        return range.size();
    }

    template<typename R>
    static inline Size estimate_hrsize(const R &,
        EnableIf<!IsFiniteRandomAccessRange<R>::value, bool> = true
    ) {
        /* we have no idea how big the range actually is */
        return 16;
    }
}

template<typename T>
struct HashRange: InputRange<HashRange<T>, ForwardRangeTag, T> {
private:
    template<typename U>
    friend struct HashRange;

    using Chain = detail::HashChain<T>;
    Chain *p_node;
public:
    HashRange(): p_node(nullptr) {}
    HashRange(const HashRange &v): p_node(v.p_node) {}
    HashRange(Chain *node): p_node(node) {}

    template<typename U>
    HashRange(const HashRange<U> &v, EnableIf<
        IsSame<RemoveCv<T>, RemoveCv<U>>::value &&
        IsConvertible<U *, T *>::value, bool
    > = true): p_node((Chain *)v.p_node) {}

    HashRange &operator=(const HashRange &v) {
        p_node = v.p_node;
        return *this;
    }

    bool empty() const { return !p_node; }

    bool pop_front() {
        if (!p_node) return false;
        p_node = p_node->next;
        return true;
    }

    bool equals_front(const HashRange &v) const {
        return p_node == v.p_node;
    }

    T &front() const { return p_node->value; }
};

template<typename T>
struct BucketRange: InputRange<BucketRange<T>, ForwardRangeTag, T> {
private:
    template<typename U>
    friend struct BucketRange;

    using Chain = detail::HashChain<T>;
    Chain *p_node, *p_end;
public:
    BucketRange(): p_node(nullptr) {}
    BucketRange(Chain *node, Chain *end): p_node(node), p_end(end) {}
    BucketRange(const BucketRange &v): p_node(v.p_node), p_end(v.p_end) {}

    template<typename U>
    BucketRange(const BucketRange<U> &v, EnableIf<
        IsSame<RemoveCv<T>, RemoveCv<U>>::value &&
        IsConvertible<U *, T *>::value, bool
    > = true): p_node((Chain *)v.p_node), p_end((Chain *)v.p_end) {}

    BucketRange &operator=(const BucketRange &v) {
        p_node = v.p_node;
        p_end = v.p_end;
        return *this;
    }

    bool empty() const { return p_node == p_end; }

    bool pop_front() {
        if (p_node == p_end) return false;
        p_node = p_node->next;
        return true;
    }

    bool equals_front(const BucketRange &v) const {
        return p_node == v.p_node;
    }

    T &front() const { return p_node->value; }
};

namespace detail {
    /* Use template metaprogramming to figure out a correct number
     * of elements to use per chunk for proper cache alignment
     * (i.e. sizeof(Chunk) % CACHE_LINE_SIZE == 0).
     *
     * If this is not possible, use the upper bound and pad the
     * structure with some extra bytes.
     */
    static constexpr Size CACHE_LINE_SIZE = 64;
    static constexpr Size CHUNK_LOWER_BOUND = 32;
    static constexpr Size CHUNK_UPPER_BOUND = 128;

    template<typename E, Size N>
    struct HashChainAlign {
        static constexpr Size csize = sizeof(HashChain<E>[N]) + sizeof(void *);
        static constexpr Size value = ((csize % CACHE_LINE_SIZE) == 0)
            ? N : HashChainAlign<E, N + 1>::value;
    };

    template<typename E>
    struct HashChainAlign<E, CHUNK_UPPER_BOUND> {
        static constexpr Size value = CHUNK_UPPER_BOUND;
    };

    template<Size N, bool B>
    struct HashChainPad;

    template<Size N>
    struct HashChainPad<N, true> {};

    template<Size N>
    struct HashChainPad<N, false> {
        byte pad[CACHE_LINE_SIZE - (N % CACHE_LINE_SIZE)];
    };

    template<Size N>
    struct HashPad: HashChainPad<N, N % CACHE_LINE_SIZE == 0> {};

    template<typename E, Size V = HashChainAlign<E, CHUNK_LOWER_BOUND>::value,
             bool P = (V == CHUNK_UPPER_BOUND)
    > struct HashChunk;

    template<typename E, Size V>
    struct HashChunk<E, V, false> {
        static constexpr Size num = V;
        HashChain<E> chains[num];
        HashChunk *next;
    };

    template<typename E, Size V>
    struct HashChunk<E, V, true>: HashPad<
        sizeof(HashChain<E>[V]) + sizeof(void *)
    > {
        static constexpr Size num = V;
        HashChain<E> chains[num];
        HashChunk *next;
    };

    template<
        typename B, /* contains methods specific to each ht type */
        typename E, /* element type */
        typename K, /* key type */
        typename T, /* value type */
        typename H, /* hash func */
        typename C, /* equality check */
        typename A, /* allocator */
        bool Multihash
    > struct Hashtable {
private:
        using Chain = HashChain<E>;
        using Chunk = HashChunk<E>;

        Size p_size;
        Size p_len;

        Chunk *p_chunks;
        Chain *p_unused;

        using CPA = AllocatorRebind<A, Chain *>;
        using CHA = AllocatorRebind<A, Chunk>;

        using CoreAllocPair = detail::CompressedPair<CPA, CHA>;
        using AllocPair = detail::CompressedPair<A, CoreAllocPair>;
        using FuncPair = detail::CompressedPair<H, C>;
        using FAPair = detail::CompressedPair<AllocPair, FuncPair>;
        using DataPair = detail::CompressedPair<Chain **, FAPair>;

        using Range = HashRange<E>;
        using ConstRange = HashRange<const E>;
        using LocalRange = BucketRange<E>;
        using ConstLocalRange = BucketRange<const E>;

        DataPair p_data;

        float p_maxlf;

        void clear_buckets() {
            memset(p_data.first(), 0, (p_size + 1) * sizeof(Chain *));
        }

        void init_buckets() {
            p_data.first() = allocator_allocate(get_cpalloc(), p_size + 1);
            clear_buckets();
        }

        Chain *find(const K &key, Size &h) const {
            if (!p_size) return nullptr;
            h = bucket(key);
            Chain **cp = p_data.first();
            for (Chain *c = cp[h], *e = cp[h + 1]; c != e; c = c->next)
                if (get_eq()(key, B::get_key(c->value)))
                    return c;
            return nullptr;
        }

        Chain *insert_node(Size h, Chain *c) {
            Chain **cp = p_data.first();
            Chain *it = cp[h + 1];
            c->next = it;
            if (it) {
                c->prev = it->prev;
                it->prev = c;
                if (c->prev) c->prev->next = c;
            } else {
                size_t nb = h;
                while (nb && !cp[nb]) --nb;
                Chain *prev = cp[nb];
                while (prev && prev->next) prev = prev->next;
                c->prev = prev;
                if (prev) prev->next = c;
            }
            for (; it == cp[h]; --h) {
                cp[h] = c;
                if (!h) break;
            }
            return c;
        }

        Chain *request_node() {
            if (!p_unused) {
                Chunk *chunk = allocator_allocate(get_challoc(), 1);
                allocator_construct(get_challoc(), chunk);
                chunk->next = p_chunks;
                p_chunks = chunk;
                for (Size i = 0; i < (Chunk::num - 1); ++i)
                    chunk->chains[i].next = &chunk->chains[i + 1];
                chunk->chains[Chunk::num - 1].next = p_unused;
                p_unused = chunk->chains;
            }
            ++p_len;
            Chain *c = p_unused;
            p_unused = p_unused->next;
            return c;
        }

        Chain *insert(Size h) {
            return insert_node(h, request_node());
        }

        void delete_chunks(Chunk *chunks) {
            for (Chunk *nc; chunks; chunks = nc) {
                nc = chunks->next;
                allocator_destroy(get_challoc(), chunks);
                allocator_deallocate(get_challoc(), chunks, 1);
            }
        }

        void rehash_ahead(Size n) {
            if (!bucket_count())
                reserve(n);
            else if ((float(size() + n) / bucket_count()) > max_load_factor())
                rehash(Size((size() + 1) / max_load_factor()) * 2);
        }

protected:
        template<typename U>
        T &insert(Size h, U &&key) {
            Chain *c = insert(h);
            B::set_key(c->value, forward<U>(key), get_alloc());
            return B::get_data(c->value);
        }

        T &access_or_insert(const K &key) {
            Size h = 0;
            Chain *c = find(key, h);
            if (c) return B::get_data(c->value);
            rehash_ahead(1);
            return insert(bucket(key), key);
        }

        T &access_or_insert(K &&key) {
            Size h = 0;
            Chain *c = find(key, h);
            if (c) return B::get_data(c->value);
            rehash_ahead(1);
            return insert(bucket(key), move(key));
        }

        T *access(const K &key) const {
            Size h;
            Chain *c = find(key, h);
            if (c) return &B::get_data(c->value);
            return nullptr;
        }

        template<typename R>
        void assign_range(R range) {
            clear();
            reserve_at_least(detail::estimate_hrsize(range));
            for (; !range.empty(); range.pop_front())
                emplace(range.front());
            rehash_up();
        }

        void assign_init(InitializerList<E> il) {
            const E *beg = il.begin(), *end = il.end();
            clear();
            reserve_at_least(end - beg);
            while (beg != end)
                emplace(*beg++);
        }

        const H &get_hash() const { return p_data.second().second().first(); }
        const C &get_eq() const { return p_data.second().second().second(); }

        A &get_alloc() { return p_data.second().first().first(); }
        const A &get_alloc() const { return p_data.second().first().first(); }

        CPA &get_cpalloc() { return p_data.second().first().second().first(); }
        const CPA &get_cpalloc() const {
            return p_data.second().first().second().first();
        }

        CHA &get_challoc() { return p_data.second().first().second().second(); }
        const CHA &get_challoc() const {
            return p_data.second().first().second().second();
        }

        Hashtable(Size size, const H &hf, const C &eqf, const A &alloc):
        p_size(size), p_len(0), p_chunks(nullptr), p_unused(nullptr),
        p_data(nullptr, FAPair(AllocPair(alloc, CoreAllocPair(alloc, alloc)),
            FuncPair(hf, eqf))),
        p_maxlf(1.0f) {
            if (!size) return;
            init_buckets();
        }

        Hashtable(const Hashtable &ht, const A &alloc): p_size(ht.p_size),
        p_len(0), p_chunks(nullptr), p_unused(nullptr),
        p_data(nullptr, FAPair(AllocPair(alloc, CoreAllocPair(alloc, alloc)),
            FuncPair(ht.get_hash(), ht.get_eq()))),
        p_maxlf(ht.p_maxlf) {
            if (!p_size) return;
            init_buckets();
            Chain **och = ht.p_data.first();
            for (Chain *oc = *och; oc; oc = oc->next) {
                Size h = bucket(B::get_key(oc->value));
                Chain *nc = insert(h);
                allocator_destroy(get_alloc(), &nc->value);
                allocator_construct(get_alloc(), &nc->value, oc->value);
            }
        }

        Hashtable(Hashtable &&ht): p_size(ht.p_size), p_len(ht.p_len),
        p_chunks(ht.p_chunks), p_unused(ht.p_unused),
        p_data(move(ht.p_data)), p_maxlf(ht.p_maxlf) {
            ht.p_size = ht.p_len = 0;
            ht.p_chunks = nullptr;
            ht.p_unused = nullptr;
            ht.p_data.first() = nullptr;
        }

        Hashtable(Hashtable &&ht, const A &alloc): p_data(nullptr,
            FAPair(AllocPair(alloc, CoreAllocPair(alloc, alloc)),
                FuncPair(ht.get_hash(), ht.get_eq()))) {
            p_size = ht.p_size;
            if (alloc == ht.get_alloc()) {
                p_len = ht.p_len;
                p_chunks = ht.p_chunks;
                p_unused = ht.p_unused;
                p_data.first() = ht.p_data.first();
                p_maxlf = ht.p_maxlf;
                ht.p_size = ht.p_len = 0;
                ht.p_chunks = nullptr;
                ht.p_unused = nullptr;
                ht.p_data.first() = nullptr;
                return;
            }
            p_len = 0;
            p_chunks = nullptr;
            p_unused = nullptr;
            init_buckets();
            Chain **och = ht.p_data.first();
            for (Chain *oc = *och; oc; oc = oc->next) {
                Size h = bucket(B::get_key(oc->value));
                Chain *nc = insert(h);
                B::swap_elem(oc->value, nc->value);
            }
        }

        Hashtable &operator=(const Hashtable &ht) {
            clear();
            if (AllocatorPropagateOnContainerCopyAssignment<A>::value) {
                if ((get_cpalloc() != ht.get_cpalloc()) && p_size) {
                    allocator_deallocate(get_cpalloc(),
                        p_data.first(), p_size + 1);
                    init_buckets();
                }
                get_alloc() = ht.get_alloc();
                get_cpalloc() = ht.get_cpalloc();
                get_challoc() = ht.get_challoc();
            }
            for (ConstRange range = ht.iter(); !range.empty(); range.pop_front())
                emplace(range.front());
            return *this;
        }

        Hashtable &operator=(Hashtable &&ht) {
            clear();
            swap_adl(p_size, ht.p_size);
            swap_adl(p_len, ht.p_len);
            swap_adl(p_chunks, ht.p_chunks);
            swap_adl(p_unused, ht.p_unused);
            swap_adl(p_data.first(), ht.p_data.first());
            swap_adl(p_data.second().second(), ht.p_data.second().second());
            if (AllocatorPropagateOnContainerMoveAssignment<A>::value)
                swap_adl(p_data.second().first(), ht.p_data.second().first());
            return *this;
        }

        void rehash_up() {
            if (load_factor() <= max_load_factor()) return;
            rehash(Size(size() / max_load_factor()) * 2);
        }

        void reserve_at_least(Size count) {
            Size nc = Size(ceil(count / max_load_factor()));
            if (p_size > nc) return;
            rehash(nc);
        }

        void swap(Hashtable &ht) {
            swap_adl(p_size, ht.p_size);
            swap_adl(p_len, ht.p_len);
            swap_adl(p_chunks, ht.p_chunks);
            swap_adl(p_unused, ht.p_unused);
            swap_adl(p_data.first(), ht.p_data.first());
            swap_adl(p_data.second().second(), ht.p_data.second().second());
            if (AllocatorPropagateOnContainerSwap<A>::value)
                swap_adl(p_data.second().first(), ht.p_data.second().first());
        }

public:
        ~Hashtable() {
            if (p_size) allocator_deallocate(get_cpalloc(),
                p_data.first(), p_size + 1);
            delete_chunks(p_chunks);
        }

        A get_allocator() const {
            return get_alloc();
        }

        void clear() {
            if (!p_len) return;
            clear_buckets();
            p_len = 0;
            p_unused = nullptr;
            delete_chunks(p_chunks);
        }

        bool empty() const { return p_len == 0; }
        Size size() const { return p_len; }
        Size max_size() const { return Size(~0) / sizeof(E); }

        Size bucket_count() const { return p_size; }
        Size max_bucket_count() const { return Size(~0) / sizeof(Chain); }

        Size bucket(const K &key) const {
            return get_hash()(key) & (p_size - 1);
        }

        Size bucket_size(Size n) const {
            Size ret = 0;
            if (n >= p_size) return ret;
            Chain **cp = p_data.first();
            for (Chain *c = cp[n], *e = cp[n + 1]; c != e; c = c->next)
                ++ret;
            return ret;
        }

        template<typename ...Args>
        Pair<Range, bool> emplace(Args &&...args) {
            rehash_ahead(1);
            E elem(forward<Args>(args)...);
            if (Multihash) {
                /* multihash: always insert
                 * gotta make sure that equal keys always come  after
                 * each other (this is then used by other APIs)
                 */
                Size h = bucket(B::get_key(elem));
                Chain *ch = insert(h);
                B::swap_elem(ch->value, elem);
                return make_pair(Range(ch), true);
            }
            Size h = bucket(B::get_key(elem));
            Chain *found = nullptr;
            bool ins = true;
            Chain **cp = p_data.first();
            for (Chain *c = cp[h], *e = cp[h + 1]; c != e; c = c->next) {
                if (get_eq()(B::get_key(elem), B::get_key(c->value))) {
                    found = c;
                    ins = false;
                    break;
                }
            }
            if (!found) {
                found = insert(h);
                B::swap_elem(found->value, elem);
            }
            return make_pair(Range(found), ins);
        }

        Size erase(const K &key) {
            Size h = 0;
            Chain *c = find(key, h);
            if (!c) return 0;
            Chain **cp = p_data.first();
            Size olen = p_len;
            for (Chain *e = cp[h + 1]; c != e; c = c->next) {
                if (!get_eq()(key, B::get_key(c->value))) break;
                --p_len;
                Size hh = h;
                Chain *next = c->next;
                for (; cp[hh] == c; --hh) {
                    cp[hh] = next;
                    if (!hh) break;
                }
                if (c->prev) c->prev->next = next;
                if (next) next->prev = c->prev;
                c->next = p_unused;
                c->prev = nullptr;
                p_unused = c;
                allocator_destroy(get_alloc(), &c->value);
                allocator_construct(get_alloc(), &c->value);
                if (!Multihash) return 1;
            }
            return olen - p_len;
        }

        Size count(const K &key) {
            Size h = 0;
            Chain *c = find(key, h);
            if (!c) return 0;
            Size ret = 1;
            if (!Multihash) return ret;
            for (c = c->next; c; c = c->next)
                if (get_eq()(key, B::get_key(c->value))) ++ret;
            return ret;
        }

        Range find(const K &key) {
            Size h = 0;
            return Range(find(key, h));
        }

        ConstRange find(const K &key) const {
            Size h = 0;
            return ConstRange((detail::HashChain<const E> *)find(key, h));
        }

        float load_factor() const { return float(p_len) / p_size; }
        float max_load_factor() const { return p_maxlf; }
        void max_load_factor(float lf) { p_maxlf = lf; }

        void rehash(Size count) {
            Size fbcount = Size(p_len / max_load_factor());
            if (fbcount > count) count = fbcount;

            Chain **och = p_data.first();
            Size osize = p_size;

            p_size = count;
            init_buckets();

            Chain *p = och ? *och : nullptr;
            while (p) {
                Chain *pp = p->next;
                Size h = bucket(B::get_key(p->value));
                p->prev = p->next = nullptr;
                insert_node(h, p);
                p = pp;
            }

            if (och && osize) allocator_deallocate(get_cpalloc(),
                och, osize + 1);
        }

        void reserve(Size count) {
            rehash(Size(ceil(count / max_load_factor())));
        }

        Range iter() {
            if (!p_len) return Range();
            return Range(*p_data.first());
        }
        ConstRange iter() const {
            using Chain = detail::HashChain<const E>;
            if (!p_len) return ConstRange();
            return ConstRange((Chain *)*p_data.first());
        }
        ConstRange citer() const {
            using Chain = detail::HashChain<const E>;
            if (!p_len) return ConstRange();
            return ConstRange((Chain *)*p_data.first());
        }

        LocalRange iter(Size n) {
            if (n >= p_size) return LocalRange();
            return LocalRange(p_data.first()[n], p_data.first()[n + 1]);
        }
        ConstLocalRange iter(Size n) const {
            using Chain = detail::HashChain<const E>;
            if (n >= p_size) return ConstLocalRange();
            return ConstLocalRange((Chain *)p_data.first()[n],
                                   (Chain *)p_data.first()[n + 1]);
        }
        ConstLocalRange citer(Size n) const {
            using Chain = detail::HashChain<const E>;
            if (n >= p_size) return ConstLocalRange();
            return ConstLocalRange((Chain *)p_data.first()[n],
                                   (Chain *)p_data.first()[n + 1]);
        }
    };
} /* namespace detail */

} /* namespace ostd */

#endif