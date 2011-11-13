/* File: of_hashset.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Hashset class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_HASHSET_H
#define OF_HASHSET_H

#include "of_utils.h"
#include "of_algorithm.h"
#include "of_functional.h"
#include "of_iterator.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    template<typename T> struct Hash_Set_Chain
    {
        Hash_Set_Chain(): p_next(this) {}
        Hash_Set_Chain(const T& data, Hash_Set_Chain *next):
            p_data(data), p_next(next) {}

    protected:

        T p_data;
        Hash_Set_Chain *p_next;

        template<typename U> friend struct Hash_Set_Iterator;
        template<typename U> friend struct Hash_Set_Const_Iterator;
        template<typename U> friend struct Hash_Set;
        template<typename U, typename V> friend struct Hash_Map;
    };

    /* Struct: Hash_Set_Iterator
     * An iterator for <Hash_Set> (and <Hash_Map>). It's a forward iterator,
     * you can only go one direction and without offsets.
     */
    template<typename T> struct Hash_Set_Iterator
    {
        typedef Hash_Set_Chain<T> chain;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;

        /* Constructor: Hash_Set_Iterator
         * Constructs an empty iterator.
         */
        Hash_Set_Iterator(): p_current(NULL), p_chains(NULL) {}

        /* Constructor: Hash_Set_Iterator
         * Constructs an iterator from <chain>**.
         */
        Hash_Set_Iterator(chain **chains):
            p_chains(chains), p_current(*chains) {}

        /* Constructor: Hash_Set_Iterator
         * Constructs an iterator from <chain>** and "current"
         * <chain>*. Used by the find function.
         */
        Hash_Set_Iterator(chain **chains, chain *current):
            p_chains(chains), p_current(current) {}

        /* Constructor: Hash_Set_Iterator
         * Constructs an iterator from another iterator.
         */
        Hash_Set_Iterator(const Hash_Set_Iterator& it):
            p_chains(it.p_chains), p_current(it.p_current) {}

        /* Operator: *
         * Dereferencing Hash_Set iterator returns the current chain data.
         */
        ref_t operator*() const { return p_current->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &p_current->p_data; }

        /* Operator: ++
         * Moves on to the next chain, prefix version.
         */
        Hash_Set_Iterator& operator++()
        {
            if (p_current->p_next == p_current->p_next->p_next)
            {
                ++p_chains;
                while (*p_chains == NULL)
                      ++p_chains;

                p_current = *p_chains;
                return *this;
            }
            p_current = p_current->p_next;

            return *this;
        }

        /* Operator: ++
         * Moves on to the next chain and returns
         * an iterator to the current chain (before
         * incrementing). Postfix version.
         */
        Hash_Set_Iterator operator++(int)
        {
            Hash_Set_Iterator tmp = *this;
            operator++();
            return tmp;
        }

        /* Operator: == */
        template<typename U>
        friend bool operator==(
            const Hash_Set_Iterator& a, const Hash_Set_Iterator<U>& b
        )
        { return a.p_current == b.p_current; }

        /* Operator: != */
        template<typename U>
        friend bool operator!=(
            const Hash_Set_Iterator& a, const Hash_Set_Iterator<U>& b
        )
        { return a.p_current != b.p_current; }

    protected:

        chain **p_chains;
        chain  *p_current;

        template<typename U> friend struct Hash_Set_Iterator;
        template<typename U> friend struct Hash_Set_Const_Iterator;
    };

    /* Struct: Hash_Set_Const_Iterator
     * Const version of <Hash_Set_Iterator>. Inherits from <Hash_Set_Iterator>.
     * Besides its own typedefs, it provides a constructor allowing to create
     * it from a standard <Hash_Set_Iterator> and overloads for the * and ->
     * operators.
     */
    template<typename T> struct Hash_Set_Const_Iterator: Hash_Set_Iterator<T>
    {
        typedef Hash_Set_Iterator<T> base;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T* ptr_t;
        /* Typedef: ref_t */
        typedef const T& ref_t;
        /* Typedef: val_t */
        typedef T val_t;

        /* Constructor: Hash_Set_Const_Iterator
         * Constructs a Hash_Set const iterator from <Hash_Set_Iterator>.
         */
        Hash_Set_Const_Iterator(const base& it): base(it) {}

        /* Operator: *
         * Dereferencing Hash_Set iterator returns the current chain data.
         */
        ref_t operator*() const { return base::p_current->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &base::p_current->p_data; }
    };

    /* Struct: Hash_Set
     * An efficient associative container implementation using a hash table.
     * It can be used for efficient key-value associations that are unordered.
     *
     * Anything can be used as either key or value, ranging from POD types
     * through objects to pointers.
     *
     * You should, however, never store a pointer inside the container unless
     * you manage it elsewhere to prevent memory leaks (you can however store
     * it in reference counted container, <shared_ptr>).
     *
     * This structure represents a "set", where a key value is the same as
     * data value. It serves as a base for actual map, where key and data are
     * different. It simply inherits and makes use of <pair>.
     *
     * If you need ordered storage with bidirectional and reverse iterators,
     * you can use <set>, which is implemented using binary tree. It has,
     * however, worse insertion / lookup time complexity. It can also use
     * any type as a key, while this can use only those which are supported
     * by the hash function.
     *
     * (start code)
     *     typedef types::Hash_Set<int> myset;
     *     myset test;
     *     // these two ways are equivalent in function, the
     *     // second one is better if the element doesn't exist.
     *     test[5] = 5;
     *     test.insert(5);
     * 
     *     // searching
     *     printf("%i\n", test[5]);
     *     // this will not fail - it'll insert a value, so it'll print 10.
     *     printf("%i\n", test[10]);
     *
     *     // iteration
     *     for (myset::cit it = test.begin(); it != test.end(); ++it)
     *         printf("%i\n", *it);
     *
     *     // erasing, will delete the data
     *     test.erase(5);
     *
     *     // retrieving the set length
     *     printf("%i\n", test.length());
     *
     *     // will clear the set - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T> struct Hash_Set
    {
        typedef Hash_Set_Chain<T> chain;

        /* Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef Hash_Set_Iterator<T> it;

        /* Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef Hash_Set_Const_Iterator<T> cit;

        /* Constructor: Hash_Set
         * Constructs an empty Hash_Set. You can provide the size
         * it'll use for the table (bigger size means less chaining,
         * the default of 1 << 10 should be fine in most of cases).
         */
        Hash_Set(size_t size = 1 << 10):
            p_chains(NULL), p_nil(NULL), p_tsize(size), p_length(0)
        {
            p_nil    = new chain;
            p_chains = new chain*[size + 1];

            for (size_t  s  = 0; s < size; ++s)
                p_chains[s] = NULL;

            p_chains[size] = p_nil;
        }

        /* Destructor: Hash_Set
         * Clears up the Hash_Set, deletes the table and
         * the nil chain, so it doesn't leak.
         */
        ~Hash_Set()
        {
            clear();
            delete[] p_chains;
            delete   p_nil;
        }

        /* Function: length
         * Returns the set length (the amount of chains
         * with actual data).
         */
        size_t length() const { return p_length; }

        /* Function: is_empty
         * Returns true if the set contains no chains
         * (except nil) and false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Function: begin
         * Returns an iterator to the first chain.
         */
        it begin()
        {
            for (size_t s = 0; s < p_tsize; ++s)
                if (p_chains[s]) return it(&p_chains[s]);

            return it(&p_chains[p_tsize]);
        }

        /* Function: begin
         * Returns a const iterator to the first chain.
         */
        cit begin() const
        {
            for (size_t s = 0; s < p_tsize; ++s)
                if (p_chains[s]) return cit(&p_chains[s]);

            return cit(&p_chains[p_tsize]);
        }

        /* Function: end
         * Returns an iterator to the last chain.
         */
        it end()
        {
            return it(&p_chains[p_tsize]);
        }

        /* Function: end
         * Returns a const iterator to the last chain.
         */
        cit end() const
        {
            return cit(&p_chains[p_tsize]);
        }

        /* Function: insert
         * Inserts the given data into the table.
         */
        T& insert(const T& data)
        {
            uint h = algorithm::hash(data) & (p_tsize - 1);

            if (!p_chains[h])
            {
                 p_chains[h] = new chain(data, p_nil);
                 ++p_length;

                 return p_chains[h]->p_data;
            }
            else
            {
                chain *e = p_chains[h];
                while  (e->p_next != p_nil)
                    e = e->p_next;

                if (functional::Equal<T, T>()(e->p_data, data))
                    return e->p_data;
                else
                {
                    e->p_next = new chain(data, p_nil);
                    ++p_length;
                }

                return e->p_next->p_data;
            }
        }

        /* Function: clear
         * Clears up the Hash_Set and makes the
         * length zero. Doesn't delete the table.
         */
        void clear()
        {
            for (size_t s = 0; s < p_tsize; ++s)
            {
                if (p_chains[s])
                {
                    chain *p = NULL;
                    chain *e = p_chains[s];
                    while (e && e != p_nil)
                    {
                        p = e;
                        e = e->p_next;
                        delete p;
                    }
                    p_chains[s] = NULL;
                }
            }
            p_length = 0;
        }

        /* Function: erase
         * Erases a chain with a given key from the set.
         */
        template<typename U>
        void erase(const U& data)
        {
            uint h = algorithm::hash(data) & (p_tsize - 1);
            if (p_chains[h])
            {
                chain *p = NULL;
                chain *e = p_chains[h];
                while (
                    e->p_next != p_nil &&
                    !functional::Equal<U, T>()(data, e->p_data)
                )
                {
                    p = e;
                    e = e->p_next;
                }
                if (functional::Equal<U, T>()(data, e->p_data))
                {
                    if (!p)
                    {
                        chain *n = e->p_next;
                        delete e;
                        p_chains[h] = (n == p_nil) ? NULL : n;
                    }
                    else
                    {
                        chain *n = e->p_next;
                        delete e;
                        p->p_next = n;
                    }

                    --p_length;
                }
            }
        }

        /* Function: find
         * Returns an iterator to a chain that belongs to a given key. There is
         * also a const version that returns a const iterator (non-modifiable).
         */
        it find(const T& data)
        {
            chain **ch = p_chains;
            chain  *curr = NULL;

            p_find(ch, curr, data);
            return it(ch, curr);
        }

        /* Function: find
         * Const version of <find>. The result cannot be modified.
         */
        cit find(const T& data) const
        {
            chain **ch = p_chains;
            chain  *curr = NULL;

            p_find(ch, curr, data);
            return cit(ch, curr);
        }

    protected:

        void p_find(chain **&ch, chain *&curr, const T& data)
        {
            uint h = algorithm::hash(data) & (p_tsize - 1);
            if (!ch[h])
            {
                ch  += p_tsize;
                curr = *ch;
            }
            else
            {
                ch += h;
                chain *e = *ch;
                while (
                    e != p_nil &&
                    !functional::Equal<T, T>()(e->p_data, data)
                ) e = e->p_next;
                curr = e;
            }
        }

        chain **p_chains;
        chain  *p_nil;

        size_t p_tsize;

    private:

        size_t p_length;
    };
} /* end namespace types */

#endif
