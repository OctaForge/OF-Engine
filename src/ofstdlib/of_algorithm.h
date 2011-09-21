/*
 * File: of_algorithm.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Generic algorithms.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_ALGORITHM_H
#define OF_ALGORITHM_H

namespace algorithm
{
    template<typename T, typename U>
    U copy(T first, T last, U result)
    {
        while (first != last) *result++ = *first++;
        return result;
    }
} /* end namespace algorithm */

#endif
