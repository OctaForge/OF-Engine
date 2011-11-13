/* File: of_hashmap.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Hashmap class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_HASHMAP_H
#define OF_HASHMAP_H

#include "of_utils.h"
#include "of_algorithm.h"
#include "of_functional.h"
#include "of_pair.h"
#include "of_hashset.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: Hash_Map
     * See <Hash_Set>. This is the same thing, but it makes use of <Pair> to
     * create a key-value associative container, not key-key (value-value).
     * The interface is designed in that way you don't actually access
     * or modify pairs much, only when iterating.
     *
     * (start code)
     *     typedef types::Hash_Map<const char*, int> mymap;
     *     mymap test;
     *     // these two ways are equivalent in function, the
     *     // second one is better if the element doesn't exist.
     *     test["foo"] = 5;
     *     test.insert("bar", 10);
     * 
     *     // searching
     *     printf("%i\n", test["bar"]);
     *     // this will not fail - it'll insert an empty value,
     *     // so it'll print just 0 (default value for an int)
     *     printf("%i\n", test["baz"]);
     *
     *     // iteration
     *     for (mymap::cit it = test.begin(); it != test.end(); ++it)
     *         printf("%s - %i\n", (*n).first, (*n).second);
     *
     *     // erasing, will delete the node
     *     test.erase("baz");
     *
     *     // retrieving the map length
     *     printf("%i\n", test.length());
     *
     *     // will clear the node - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T, typename U> struct Hash_Map: Hash_Set<Pair<T, U> >
    {
        typedef Hash_Set<Pair<T, U> > base;
        typedef Hash_Set_Chain<Pair<T, U> > chain;

        /* Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef Hash_Set_Iterator<Pair<T, U> > it;

        /* Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef Hash_Set_Const_Iterator<Pair<T, U> > cit;

        /* Function: insert
         * Inserts a key / value pair into the map.
         *
         * You can also use the <[]> operator with assignment, both ways are
         * equivalent in function, this is however better on non-existent keys
         * because it doesn't have to insert first and then assign, instead it
         * creates with the given data directly.
         */
        U& insert(const T& key, const U& data)
        {
            return base::insert(Pair<T, U>(key, data)).second;
        }

        /* Function: insert
         * A variant of insert that accepts a <Pair> of key and data instead
         * of key and data separately.
         */
        U& insert(const Pair<T, U>& data)
        {
            return base::insert(data).second;
        }

        /* Function: erase
         * Erases a given key / value pair from the map.
         */
        void erase(const T& key) { base::erase(key); }

        /* Function: find
         * Returns an iterator to a chain that belongs to a given key. There is
         * also a const version that returns a const iterator (non-modifiable).
         */
        it find(const T& key)
        {
            chain **ch   = base::p_chains;
            chain  *curr = NULL;

            p_find(ch, curr, key);
            return it(ch, curr);
        }

        /* Function: find
         * Const version of <find>. The result cannot be modified.
         */
        cit find(const T& key) const
        {
            chain **ch   = base::p_chains;
            chain  *curr = NULL;

            p_find(ch, curr, key);
            return cit(ch, curr);
        }

        /* Operator: []
         * See <find>. If you assign a non-existant key, it'll get created
         * first, because this has to return some data (see <insert>).
         *
         * (start code)
         *     map[key] = value;
         *     printf("%s\n", map[key]);
         * (end)
         */
        U& operator[](const T& key)
        {
            chain **ch   = base::p_chains;
            chain  *curr = NULL;

            p_find(ch, curr, key);
            if (curr == base::p_nil)
                return insert(key, U());
            else
                return curr->p_data.second;
        }

    protected:

        void p_find(chain **&ch, chain *&curr, const T& key)
        {
            uint h = algorithm::hash(key) & (base::p_tsize - 1);
            if (!ch[h])
            {
                ch  += base::p_tsize;
                curr = *ch;
            }
            else
            {
                ch += h;
                chain *e = *ch;
                while (
                    e != base::p_nil &&
                    !functional::Equal<T, T>()(e->p_data.first, key)
                ) e = e->p_next;
                curr = e;
            }
        }
    };
} /* end namespace types */

#endif
