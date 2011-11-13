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
 * This namespace provides basic type traits. It can be used for checking
 * if a type is POD, pointer, integral or floating point and if two types
 * are equal.
 */
namespace traits
{
    /* Variable: Bool_Type
     * Compile-time boolean type.
     */
    template<bool v> struct Bool_Type { enum { value = v }; };

    /* Variable: True_Type
     * True version of <Bool_Type>.
     */
    typedef Bool_Type<true> True_Type;

    /* Variable: False_Type
     * False version of <Bool_Type>.
     */
    typedef Bool_Type<false> False_Type;

    /* Variable: Is_Integral
     * Version of <Bool_Type> for integral types.
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
    template<typename T> struct Is_Integral: False_Type {};

    /* Variable: Is_Floating_Point
     * Version of <Bool_Type> for floating point types.
     *
     * Specializations:
     *  float
     *  double
     *  long double
     */
    template<typename T> struct Is_Floating_Point: False_Type {};

    /* Variable: Is_Pointer
     * Version of <Bool_Type> for pointer types.
     *
     * Only true specialization here is for T*.
     */
    template<typename T> struct Is_Pointer: False_Type {};

    /* the specializations */
    template<>           struct Is_Integral<bool             > :  True_Type {};
    template<>           struct Is_Integral<char             > :  True_Type {};
    template<>           struct Is_Integral<unsigned char    > :  True_Type {};
    template<>           struct Is_Integral<signed char      > :  True_Type {};
    template<>           struct Is_Integral<short            > :  True_Type {};
    template<>           struct Is_Integral<unsigned short   > :  True_Type {};
    template<>           struct Is_Integral<int              > :  True_Type {};
    template<>           struct Is_Integral<unsigned int     > :  True_Type {};
    template<>           struct Is_Integral<long             > :  True_Type {};
    template<>           struct Is_Integral<unsigned long    > :  True_Type {};
    template<>           struct Is_Floating_Point<float      > :  True_Type {};
    template<>           struct Is_Floating_Point<double     > :  True_Type {};
    template<>           struct Is_Floating_Point<long double> :  True_Type {};
    template<typename T> struct Is_Pointer<T*                > :  True_Type {};

    /* Variable: Is_POD
     * Version of <Bool_Type> for POD types. POD type is every integral,
     * floating point or pointer type. Non-POD types are defined, like
     * various structs / classes.
     */
    template<typename T> struct Is_POD: Bool_Type<(
        Is_Integral      <T>::value ||
        Is_Floating_Point<T>::value ||
        Is_Pointer       <T>::value
    )> {};

    /* Variable: Is_Equal
     * Checks whether two types are equal. This is a definition for
     * the case when they are different, so its "value" is 0.
     */
    template<typename, typename> struct Is_Equal { enum { value = 0 }; };

    /* Variable: Is_Equal
     * Version for when they are equal, so the "value" is 1.
     */
    template<typename T> struct Is_Equal<T, T> { enum { value = 1 }; };
} /* end namespace traits */

#endif
