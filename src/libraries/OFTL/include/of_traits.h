/* File: of_traits.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Basic type traits.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_TRAITS_H
#define OF_TRAITS_H

/* Package: traits
 * This namespace provides basic type traits. It can be used for
 * checking if a type is POD, pointer, integral or floating point
 * and if two types are equal.
 */
namespace traits
{
    /* Variable: bool_type
     * Compile-time boolean type.
     */
    template<bool v> struct bool_type { enum { value = v }; };

    /* Variable: true_type
     * True version of <bool_type>.
     */
    typedef bool_type<true> true_type;

    /* Variable: false_type
     * False version of <bool_type>.
     */
    typedef bool_type<false> false_type;

    /* Variable: is_integral
     * Version of <bool_type> for integral types.
     *
     * Specializations:
     *  bool
     *  char
     *  unsigned char
     *  signed char
     *  short
     *  unsigned short
     *  int
     *  unsigned int
     *  long
     *  unsigned long
     */
    template<typename T> struct is_integral: false_type {};

    /* Variable: is_fpoint
     * Version of <bool_type> for floating point types.
     *
     * Specializations:
     *  float
     *  double
     *  long double
     */
    template<typename T> struct is_fpoint: false_type {};

    /* Variable: is_pointer
     * Version of <bool_type> for pointer types.
     *
     * Only true specialization here is for T*.
     */
    template<typename T> struct is_pointer: false_type {};

    /* the specializations */
    template<>           struct is_integral<bool          > :  true_type {};
    template<>           struct is_integral<char          > :  true_type {};
    template<>           struct is_integral<unsigned char > :  true_type {};
    template<>           struct is_integral<signed char   > :  true_type {};
    template<>           struct is_integral<short         > :  true_type {};
    template<>           struct is_integral<unsigned short> :  true_type {};
    template<>           struct is_integral<int           > :  true_type {};
    template<>           struct is_integral<unsigned int  > :  true_type {};
    template<>           struct is_integral<long          > :  true_type {};
    template<>           struct is_integral<unsigned long > :  true_type {};
    template<>           struct is_fpoint<float           > :  true_type {};
    template<>           struct is_fpoint<double          > :  true_type {};
    template<>           struct is_fpoint<long double     > :  true_type {};
    template<typename T> struct is_pointer<T*             > :  true_type {};

    /* Variable: is_pod
     * Version of <bool_type> for POD types. POD type is every integral,
     * floating point or pointer type. Non-POD types are defined, like
     * various structs / classes.
     */
    template<typename T> struct is_pod: bool_type<(is_integral<T>::value
                                                || is_fpoint  <T>::value
                                                || is_pointer <T>::value)> {};

    /* Variable: are_equal
     * Checks whether two types are equal. This is a definition for
     * the case when they are different, so its "value" is 0.
     */
    template<typename, typename> struct are_equal { enum { value = 0 }; };

    /* Variable: are_equal
     * Version for when they are equal, so the "value" is 1.
     */
    template<typename T> struct are_equal<T, T> { enum { value = 1 }; };
} /* end namespace traits */

#endif
