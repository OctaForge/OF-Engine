/* File: of_random.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Pseudo-random number generator using Mersenne Twister.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_RANDOM_H
#define OF_RANDOM_H

#include "of_utils.h"

/* Package: pseudorandom
 * Pseudo-random number generation facilities.
 */
namespace pseudorandom
{
    /* Variable: MT_Base
     * A base struct for the Mersenne Twister class. It then specializes
     * for T == uint.
     */
    template<typename T> struct MT_Base {};

    /* Struct: MT_Base
     * A Mersenne Twister (MT19937) implementation. You first need to seed
     * a number and then you can get the values.
     */
    template<> struct MT_Base<uint>
    {
        /* Constructor: MT_Base
         * Empty constructor. You need to call <seed> separately after
         * creating the instance.
         */
        MT_Base(): p_index(0) {}

        /* Constructor: MT_Base
         * Given an argument, it initializes the instance and also calls
         * <seed> with the given argument.
         */
        MT_Base(uint s): p_index(0) { seed(s); }

        /* Function: seed
         * Initializes a random number generator using seed. Note that this
         * is not a true random number generator, pseudo-random numbers are
         * generated so you have to select seed to be random enough (for
         * example, time(0) after inclusion of time.h).
         *
         * You have to call this before calling <get>.
         *
         * (start code)
         *     pseudorandom::mt gen;
         *     gen.seed(time(0));
         *     printf("Random integer: %i\n", gen.get(100));
         * (end)
         * 
         * Note that there is no need to call this if you pass the
         * seed already via constructor.
         */
        void seed(uint s)
        {
            p_MT[0] = s;
            for (uint i = 1; i < N; ++i)
                p_MT[i] = s = (1812433253U * (s ^ (s >> 30)) + i);
        }

        /* Function: get
         * Generates a 32 bit unsigned integer within the range.
         * Note that you need to <seed> a value before calling this.
         */
        uint get()
        {
            if (p_index == 0)
            {
                for (uint i = 0; i < N; ++i)
                {
                    uint y   = (p_MT[i] & 0x1U) + (p_MT[(i + 1) % N] & 0x31U);
                    p_MT[i]  = (p_MT[(i + M) % N] ^ (y >> 1));
                    if ((y % 2) != 0)
                        p_MT[i] ^= 0x9908B0DFU;
                }
            }

            uint y = p_MT[p_index];
            y ^= (y >> 11);
            y ^= (y << 7 ) & 0x9D2C5680U;
            y ^= (y << 15) & 0xEFC60000U;
            y ^= (y >> 18);

            p_index = (p_index + 1) % N;

            return y;
        }

        /* Function: get
         * Generates a random number within the given range. It's a template
         * in order to support all integral types.
         */
        template<typename U> U get(U range)
        {
            return (U)(get() % range);
        }

        /* Function: get
         * Generates a floating point random number within
         * the given range.
         */
        float get(float range)
        {
            return float(
                (get() & 0xFFFFFF) * (double(range) / double(0xFFFFFF))
            );
        }

    private:

        enum
        {
            N = 624,
            M = 397
        };

        uint p_MT[N];
        uint p_index;
    };

    /* Typedef: MT
     * Expands as MT_Base< <uint> >.
     */
    typedef MT_Base<uint> MT;
} /* end namespace pseudorandom */

#endif
