# include <cmath>
# include <cstdlib>
# include <cstring>
# include <ctime>
# include <iomanip>
# include <iostream>

using namespace std;

#include "prob.hpp"

double r8_epsilon ( )

//****************************************************************************80
//
//  Purpose:
//
//    R8_EPSILON returns the R8 roundoff unit.
//
//  Discussion:
//
//    The roundoff unit is a number R which is a power of 2 with the
//    property that, to the precision of the computer's arithmetic,
//      1 < 1 + R
//    but
//      1 = ( 1 + R / 2 )
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    01 September 2012
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Output, double R8_EPSILON, the R8 round-off unit.
//
{
  const double value = 2.220446049250313E-016;

  return value;
}
//****************************************************************************80

//****************************************************************************80

double r8_error_f ( double x )

//****************************************************************************80
//
//  Purpose:
//
//    R8_ERROR_F evaluates the error function ERF.
//
//  Discussion:
//
//    Since some compilers already supply a routine named ERF which evaluates
//    the error function, this routine has been given a distinct, if
//    somewhat unnatural, name.
//
//    The function is defined by:
//
//      ERF(X) = ( 2 / sqrt ( PI ) ) * Integral ( 0 <= T <= X ) EXP ( - T^2 ) dT.
//
//    Properties of the function include:
//
//      Limit ( X -> -Infinity ) ERF(X) =          -1.0;
//                               ERF(0) =           0.0;
//                               ERF(0.476936...) = 0.5;
//      Limit ( X -> +Infinity ) ERF(X) =          +1.0.
//
//      0.5 * ( ERF(X/sqrt(2)) + 1 ) = Normal_01_CDF(X)
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    17 November 2006
//
//  Author:
//
//    Original FORTRAN77 versino by William Cody.
//    C++ version by John Burkardt.
//
//  Reference:
//
//    William Cody,
//    "Rational Chebyshev Approximations for the Error Function",
//    Mathematics of Computation,
//    1969, pages 631-638.
//
//  Parameters:
//
//    Input, double X, the argument of the error function.
//
//    Output, double R8_ERROR_F, the value of the error function.
//
{
  double a[5] = {
    3.16112374387056560,
    1.13864154151050156E+02,
    3.77485237685302021E+02,
    3.20937758913846947E+03,
    1.85777706184603153E-01 };
  double b[4] = {
    2.36012909523441209E+01,
    2.44024637934444173E+02,
    1.28261652607737228E+03,
    2.84423683343917062E+03 };
  double c[9] = {
    5.64188496988670089E-01,
    8.88314979438837594,
    6.61191906371416295E+01,
    2.98635138197400131E+02,
    8.81952221241769090E+02,
    1.71204761263407058E+03,
    2.05107837782607147E+03,
    1.23033935479799725E+03,
    2.15311535474403846E-08 };
  double d[8] = {
    1.57449261107098347E+01,
    1.17693950891312499E+02,
    5.37181101862009858E+02,
    1.62138957456669019E+03,
    3.29079923573345963E+03,
    4.36261909014324716E+03,
    3.43936767414372164E+03,
    1.23033935480374942E+03 };
  double del;
  double erfxd;
  int i;
  double p[6] = {
    3.05326634961232344E-01,
    3.60344899949804439E-01,
    1.25781726111229246E-01,
    1.60837851487422766E-02,
    6.58749161529837803E-04,
    1.63153871373020978E-02 };
  double q[5] = {
    2.56852019228982242,
    1.87295284992346047,
    5.27905102951428412E-01,
    6.05183413124413191E-02,
    2.33520497626869185E-03 };
  double sqrpi = 0.56418958354775628695;
  double thresh = 0.46875;
  double xabs;
  double xbig = 26.543;
  double xden;
  double xnum;
  double xsmall = 1.11E-16;
  double xsq;

  xabs = fabs ( ( x ) );
//
//  Evaluate ERF(X) for |X| <= 0.46875.
//
  if ( xabs <= thresh )
  {
    if ( xsmall < xabs )
    {
      xsq = xabs * xabs;
    }
    else
    {
      xsq = 0.0;
    }

    xnum = a[4] * xsq;
    xden = xsq;

    for ( i = 0; i < 3; i++ )
    {
      xnum = ( xnum + a[i] ) * xsq;
      xden = ( xden + b[i] ) * xsq;
    }

    erfxd = x * ( xnum + a[3] ) / ( xden + b[3] );
  }
//
//  Evaluate ERFC(X) for 0.46875 <= |X| <= 4.0.
//
  else if ( xabs <= 4.0 )
  {
    xnum = c[8] * xabs;
    xden = xabs;
    for ( i = 0; i < 7; i++ )
    {
      xnum = ( xnum + c[i] ) * xabs;
      xden = ( xden + d[i] ) * xabs;
    }

    erfxd = ( xnum + c[7] ) / ( xden + d[7] );
    xsq = ( ( double ) ( ( int ) ( xabs * 16.0 ) ) ) / 16.0;
    del = ( xabs - xsq ) * ( xabs + xsq );
    erfxd = exp ( - xsq * xsq ) * exp ( -del ) * erfxd;

    erfxd = ( 0.5 - erfxd ) + 0.5;

    if ( x < 0.0 )
    {
      erfxd = -erfxd;
    }
  }
//
//  Evaluate ERFC(X) for 4.0 < |X|.
//
  else
  {
    if ( xbig <= xabs )
    {
      if ( 0.0 < x )
      {
        erfxd = 1.0;
      }
      else
      {
        erfxd = - 1.0;
      }
    }
    else
    {
      xsq = 1.0 / ( xabs * xabs );

      xnum = p[5] * xsq;
      xden = xsq;

      for ( i = 0; i < 4; i++ )
      {
        xnum = ( xnum + p[i] ) * xsq;
        xden = ( xden + q[i] ) * xsq;
      }

      erfxd = xsq * ( xnum + p[4] ) / ( xden + q[4] );
      erfxd = ( sqrpi - erfxd ) / xabs;
      xsq = ( ( double ) ( ( int ) ( xabs * 16.0 ) ) ) / 16.0;
      del = ( xabs - xsq ) * ( xabs + xsq );
      erfxd = exp ( - xsq * xsq ) * exp ( - del ) * erfxd;

      erfxd = ( 0.5 - erfxd ) + 0.5;

      if ( x < 0.0 )
      {
        erfxd = - erfxd;
      }
    }
  }

  return erfxd;
}
//****************************************************************************80

//****************************************************************************80

double r8_max ( double x, double y )

//****************************************************************************80
//
//  Purpose:
//
//    R8_MAX returns the maximum of two R8's.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    18 August 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double X, Y, the quantities to compare.
//
//    Output, double R8_MAX, the maximum of X and Y.
//
{
  if ( y < x )
  {
    return x;
  }
  else
  {
    return y;
  }
}
//****************************************************************************80

double r8_min ( double x, double y )

//****************************************************************************80
//
//  Purpose:
//
//    R8_MIN returns the minimum of two R8's.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    31 August 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double X, Y, the quantities to compare.
//
//    Output, double R8_MIN, the minimum of X and Y.
//
{
  if ( y < x )
  {
    return y;
  }
  else
  {
    return x;
  }
}
//****************************************************************************80


double r8_modp ( double x, double y )

//****************************************************************************80
//
//  Purpose:
//
//    R8_MODP returns the nonnegative remainder of R8 division.
//
//  Discussion:
//
//    If
//      REM = R8_MODP ( X, Y )
//      RMULT = ( X - REM ) / Y
//    then
//      X = Y * RMULT + REM
//    where REM is always nonnegative.
//
//    The MOD function computes a result with the same sign as the
//    quantity being divided.  Thus, suppose you had an angle A,
//    and you wanted to ensure that it was between 0 and 360.
//    Then mod(A,360.0) would do, if A was positive, but if A
//    was negative, your result would be between -360 and 0.
//
//    On the other hand, R8_MODP(A,360.0) is between 0 and 360, always.
//
//  Example:
//
//        I         J     MOD R8_MODP  R8_MODP Factorization
//
//      107        50       7       7    107 =  2 *  50 + 7
//      107       -50       7       7    107 = -2 * -50 + 7
//     -107        50      -7      43   -107 = -3 *  50 + 43
//     -107       -50      -7      43   -107 =  3 * -50 + 43
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    18 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double X, the number to be divided.
//
//    Input, double Y, the number that divides X.
//
//    Output, double R8_MODP, the nonnegative remainder when X is divided by Y.
//
{
  double value;

  if ( y == 0.0 )
  {
    cerr << "\n";
    cerr << "R8_MODP - Fatal error!\n";
    cerr << "  R8_MODP ( X, Y ) called with Y = " << y << "\n";
    exit ( 1 );
  }

  value = x - ( ( double ) ( ( int ) ( x / y ) ) ) * y;

  if ( value < 0.0 )
  {
    value = value + fabs ( y );
  }

  return value;
}
//****************************************************************************80

//****************************************************************************80

double r8_sign ( double x )

//****************************************************************************80
//
//  Purpose:
//
//    R8_SIGN returns the sign of an R8.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    18 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double X, the number whose sign is desired.
//
//    Output, double R8_SIGN, the sign of X.
//
{
  if ( x < 0.0 )
  {
    return ( -1.0 );
  }
  else
  {
    return ( 1.0 );
  }
}
//****************************************************************************80

double r8_uniform_01 ( int &seed )

//****************************************************************************80
//
//  Purpose:
//
//    R8_UNIFORM_01 returns a unit pseudorandom R8.
//
//  Discussion:
//
//    This routine implements the recursion
//
//      seed = 16807 * seed mod ( 2^31 - 1 )
//      unif = seed / ( 2^31 - 1 )
//
//    The integer arithmetic never requires more than 32 bits,
//    including a sign bit.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    11 August 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Paul Bratley, Bennett Fox, Linus Schrage,
//    A Guide to Simulation,
//    Springer Verlag, pages 201-202, 1983.
//
//    Bennett Fox,
//    Algorithm 647:
//    Implementation and Relative Efficiency of Quasirandom
//    Sequence Generators,
//    ACM Transactions on Mathematical Software,
//    Volume 12, Number 4, pages 362-376, 1986.
//
//  Parameters:
//
//    Input/output, int &SEED, the "seed" value.  Normally, this
//    value should not be 0.  On output, SEED has been updated.
//
//    Output, double R8_UNIFORM_01, a new pseudorandom variate, strictly between
//    0 and 1.
//
{
  int k;
  double r;

  k = seed / 127773;

  seed = 16807 * ( seed - k * 127773 ) - k * 2836;

  if ( seed < 0 )
  {
    seed = seed + 2147483647;
  }

  r = ( double ) ( seed ) * 4.656612875E-10;

  return r;
}
//****************************************************************************80

//****************************************************************************80

double bessel_i0 ( double arg )

//****************************************************************************80
//
//  Purpose:
//
//    BESSEL_I0 evaluates the modified Bessel function I0.
//
//  Discussion:
//
//    The main computation evaluates slightly modified forms of
//    minimax approximations generated by Blair and Edwards, Chalk
//    River (Atomic Energy of Canada Limited) Report AECL-4928,
//    October, 1974.  This transportable program is patterned after
//    the machine dependent FUNPACK packet NATSI0, but cannot match
//    that version for efficiency or accuracy.  This version uses
//    rational functions that theoretically approximate I-SUB-0(X)
//    to at least 18 significant decimal digits.
//
//  Machine dependent constants:
//
//    beta   = Radix for the floating-point system
//    maxexp = Smallest power of beta that overflows
//    XSMALL = Positive argument such that 1.0 - X = 1.0 to
//             machine precision for all ABS(X) .LE. XSMALL.
//    XMAX =   Largest argument acceptable to BESI0;  Solution to
//             equation:
//               W(X) * (1+1/(8*X)+9/(128*X^2) = beta^maxexp
//             where  W(X) = EXP(X)/sqrt(2*PI*X)
//
//    Approximate values for some important machines are:
//
//                             beta       maxexp       XSMALL
//
//    CRAY-1        (S.P.)       2         8191       3.55D-15
//    Cyber 180/855
//      under NOS   (S.P.)       2         1070       3.55D-15
//    IEEE (IBM/XT,
//      SUN, etc.)  (S.P.)       2          128       2.98D-8
//    IEEE (IBM/XT,
//      SUN, etc.)  (D.P.)       2         1024       5.55D-17
//    IBM 3033      (D.P.)      16           63       6.95D-18
//    VAX           (S.P.)       2          127       2.98D-8
//    VAX D-Format  (D.P.)       2          127       6.95D-18
//    VAX G-Format  (D.P.)       2         1023       5.55D-17
//
//
//                                  XMAX
//
//    CRAY-1        (S.P.)       5682.810
//    Cyber 180/855
//      under NOS   (S.P.)       745.893
//    IEEE (IBM/XT,
//      SUN, etc.)  (S.P.)        91.900
//    IEEE (IBM/XT,
//      SUN, etc.)  (D.P.)       713.986
//    IBM 3033      (D.P.)       178.182
//    VAX           (S.P.)        91.203
//    VAX D-Format  (D.P.)        91.203
//    VAX G-Format  (D.P.)       713.293
//
//  Author:
//
//    Original FORTRAN77 version by W. J. Cody and L. Stoltz.
//    C++ version by John Burkardt.
//
//  Parameters:
//
//    Input, double ARG, the argument.
//
//    Output, double BESSEL_I0, the value of the modified Bessel function
//    of the first kind.
//
{
  double a;
  double b;
  double exp40 = 2.353852668370199854E+17;
  int i;
  double p[15] = {
    -5.2487866627945699800E-18,
    -1.5982226675653184646E-14,
    -2.6843448573468483278E-11,
    -3.0517226450451067446E-08,
    -2.5172644670688975051E-05,
    -1.5453977791786851041E-02,
    -7.0935347449210549190,
    -2.4125195876041896775E+03,
    -5.9545626019847898221E+05,
    -1.0313066708737980747E+08,
    -1.1912746104985237192E+10,
    -8.4925101247114157499E+11,
    -3.2940087627407749166E+13,
    -5.5050369673018427753E+14,
    -2.2335582639474375249E+15 };
  double pp[8] = {
    -3.9843750000000000000E-01,
     2.9205384596336793945,
    -2.4708469169133954315,
     4.7914889422856814203E-01,
    -3.7384991926068969150E-03,
    -2.6801520353328635310E-03,
     9.9168777670983678974E-05,
    -2.1877128189032726730E-06 };
  double q[5] = {
    -3.7277560179962773046E+03,
     6.5158506418655165707E+06,
    -6.5626560740833869295E+09,
     3.7604188704092954661E+12,
    -9.7087946179594019126E+14 };
  double qq[7] = {
    -3.1446690275135491500E+01,
     8.5539563258012929600E+01,
    -6.0228002066743340583E+01,
     1.3982595353892851542E+01,
    -1.1151759188741312645,
     3.2547697594819615062E-02,
    -5.5194330231005480228E-04 };
  const double r8_huge = 1.0E+30;
  double rec15 = 6.6666666666666666666E-02;
  double sump;
  double sumq;
  double value;
  double x;
  double xmax = 91.9;
  double xsmall = 2.98E-08;
  double xx;

  x = fabs ( arg );

  if ( x < xsmall )
  {
    value = 1.0;
  }
  else if ( x < 15.0 )
  {
//
//  XSMALL <= ABS(ARG) < 15.0
//
    xx = x * x;
    sump = p[0];
    for ( i = 1; i < 15; i++ )
    {
      sump = sump * xx + p[i];
    }

    xx = xx - 225.0;
    sumq = ((((
           xx + q[0] )
         * xx + q[1] )
         * xx + q[2] )
         * xx + q[3] )
         * xx + q[4];

    value = sump / sumq;
  }
  else if ( 15.0 <= x )
  {
    if ( xmax < x )
    {
      value = r8_huge;
    }
    else
    {
//
//  15.0 <= ABS(ARG)
//
      xx = 1.0 / x - rec15;

      sump = ((((((
                  pp[0]
           * xx + pp[1] )
           * xx + pp[2] )
           * xx + pp[3] )
           * xx + pp[4] )
           * xx + pp[5] )
           * xx + pp[6] )
           * xx + pp[7];

      sumq = ((((((
             xx + qq[0] )
           * xx + qq[1] )
           * xx + qq[2] )
           * xx + qq[3] )
           * xx + qq[4] )
           * xx + qq[5] )
           * xx + qq[6];

      value = sump / sumq;
//
//  Calculation reformulated to avoid premature overflow.
//
      if ( x <= xmax - 15.0 )
      {
        a = exp ( x );
        b = 1.0;
      }
      else
      {
        a = exp ( x - 40.0 );
        b = exp40;
      }

      value = ( ( value * a - pp[0] * a ) / sqrt ( x ) ) * b;
    }
  }

  return value;
}
//****************************************************************************80

void bessel_i0_values ( int &n_data, double &x, double &fx )

//****************************************************************************80
//
//  Purpose:
//
//    BESSEL_I0_VALUES returns some values of the I0 Bessel function.
//
//  Discussion:
//
//    The modified Bessel functions In(Z) and Kn(Z) are solutions of
//    the differential equation
//
//      Z^2 W'' + Z * W' - ( Z^2 + N^2 ) * W = 0.
//
//    The modified Bessel function I0(Z) corresponds to N = 0.
//
//    In Mathematica, the function can be evaluated by:
//
//      BesselI[0,x]
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    20 August 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Milton Abramowitz, Irene Stegun,
//    Handbook of Mathematical Functions,
//    National Bureau of Standards, 1964,
//    ISBN: 0-486-61272-4,
//    LC: QA47.A34.
//
//    Stephen Wolfram,
//    The Mathematica Book,
//    Fourth Edition,
//    Cambridge University Press, 1999,
//    ISBN: 0-521-64314-7,
//    LC: QA76.95.W65.
//
//  Parameters:
//
//    Input/output, int &N_DATA.  The user sets N_DATA to 0 before the
//    first call.  On each call, the routine increments N_DATA by 1, and
//    returns the corresponding data; when there is no more data, the
//    output value of N_DATA will be 0 again.
//
//    Output, double &X, the argument of the function.
//
//    Output, double &FX, the value of the function.
//
{
# define N_MAX 20

  static double fx_vec[N_MAX] = {
     0.1000000000000000E+01,
     0.1010025027795146E+01,
     0.1040401782229341E+01,
     0.1092045364317340E+01,
     0.1166514922869803E+01,
     0.1266065877752008E+01,
     0.1393725584134064E+01,
     0.1553395099731217E+01,
     0.1749980639738909E+01,
     0.1989559356618051E+01,
     0.2279585302336067E+01,
     0.3289839144050123E+01,
     0.4880792585865024E+01,
     0.7378203432225480E+01,
     0.1130192195213633E+02,
     0.1748117185560928E+02,
     0.2723987182360445E+02,
     0.6723440697647798E+02,
     0.4275641157218048E+03,
     0.2815716628466254E+04 };

  static double x_vec[N_MAX] = {
     0.00E+00,
     0.20E+00,
     0.40E+00,
     0.60E+00,
     0.80E+00,
     0.10E+01,
     0.12E+01,
     0.14E+01,
     0.16E+01,
     0.18E+01,
     0.20E+01,
     0.25E+01,
     0.30E+01,
     0.35E+01,
     0.40E+01,
     0.45E+01,
     0.50E+01,
     0.60E+01,
     0.80E+01,
     0.10E+02 };

  if ( n_data < 0 )
  {
    n_data = 0;
  }

  n_data = n_data + 1;

  if ( N_MAX < n_data )
  {
    n_data = 0;
    x = 0.0;
    fx = 0.0;
  }
  else
  {
    x = x_vec[n_data-1];
    fx = fx_vec[n_data-1];
  }

  return;
# undef N_MAX
}
//****************************************************************************80

double bessel_i1 ( double arg )

//****************************************************************************80
//
//  Purpose:
//
//    BESSEL_I1 evaluates the Bessel I function of order I.
//
//  Discussion:
//
//    The main computation evaluates slightly modified forms of
//    minimax approximations generated by Blair and Edwards.
//    This transportable program is patterned after the machine-dependent
//    FUNPACK packet NATSI1, but cannot match that version for efficiency
//    or accuracy.  This version uses rational functions that theoretically
//    approximate I-SUB-1(X) to at least 18 significant decimal digits.
//    The accuracy achieved depends on the arithmetic system, the compiler,
//    the intrinsic functions, and proper selection of the machine-dependent
//    constants.
//
//  Machine-dependent constants:
//
//    beta   = Radix for the floating-point system.
//    maxexp = Smallest power of beta that overflows.
//    XMAX =   Largest argument acceptable to BESI1;  Solution to
//             equation:
//               EXP(X) * (1-3/(8*X)) / SQRT(2*PI*X) = beta^maxexp
//
//
//    Approximate values for some important machines are:
//
//                            beta       maxexp    XMAX
//
//    CRAY-1        (S.P.)       2         8191    5682.810
//    Cyber 180/855
//      under NOS   (S.P.)       2         1070     745.894
//    IEEE (IBM/XT,
//      SUN, etc.)  (S.P.)       2          128      91.906
//    IEEE (IBM/XT,
//      SUN, etc.)  (D.P.)       2         1024     713.987
//    IBM 3033      (D.P.)      16           63     178.185
//    VAX           (S.P.)       2          127      91.209
//    VAX D-Format  (D.P.)       2          127      91.209
//    VAX G-Format  (D.P.)       2         1023     713.293
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    28 October 2004
//
//  Author:
//
//    Original FORTRAN77 version by William Cody, Laura Stoltz,
//    C++ version by John Burkardt.
//
//  Reference:
//
//    Blair, Edwards,
//    Chalk River Report AECL-4928,
//    Atomic Energy of Canada, Limited,
//    October, 1974.
//
//  Parameters:
//
//    Input, double ARG, the argument.
//
//    Output, double BESSEL_I1, the value of the Bessel
//    I1 function.
//
{
  double a;
  double b;
  double exp40 = 2.353852668370199854E+17;
  double forty = 40.0;
  double half = 0.5;
  int j;
  double one = 1.0;
  double one5 = 15.0;
  double p[15] = {
    -1.9705291802535139930E-19,
    -6.5245515583151902910E-16,
    -1.1928788903603238754E-12,
    -1.4831904935994647675E-09,
    -1.3466829827635152875E-06,
    -9.1746443287817501309E-04,
    -4.7207090827310162436E-01,
    -1.8225946631657315931E+02,
    -5.1894091982308017540E+04,
    -1.0588550724769347106E+07,
    -1.4828267606612366099E+09,
    -1.3357437682275493024E+11,
    -6.9876779648010090070E+12,
    -1.7732037840791591320E+14,
    -1.4577180278143463643E+15 };
  double pbar = 3.98437500E-01;
  double pp[8] = {
    -6.0437159056137600000E-02,
     4.5748122901933459000E-01,
    -4.2843766903304806403E-01,
     9.7356000150886612134E-02,
    -3.2457723974465568321E-03,
    -3.6395264712121795296E-04,
     1.6258661867440836395E-05,
    -3.6347578404608223492E-07 };
  double q[5] = {
    -4.0076864679904189921E+03,
     7.4810580356655069138E+06,
    -8.0059518998619764991E+09,
     4.8544714258273622913E+12,
    -1.3218168307321442305E+15 };
  double qq[6] = {
    -3.8806586721556593450,
     3.2593714889036996297,
    -8.5017476463217924408E-01,
     7.4212010813186530069E-02,
    -2.2835624489492512649E-03,
     3.7510433111922824643E-05 };
  double r8_huge = 1.0E+30;
  double rec15 = 6.6666666666666666666E-02;
  double sump;
  double sumq;
  double two25 = 225.0;
  double value;
  double x;
  double xmax = 713.987;
  double xx;
  double zero = 0.0;

  x = fabs ( arg );
//
//  ABS(ARG) < EPSILON ( ARG )
//
  if ( x < r8_epsilon ( ) )
  {
    value = half * x;
  }
//
//  EPSILON ( ARG ) <= ABS(ARG) < 15.0
//
  else if ( x < one5 )
  {
    xx = x * x;
    sump = p[0];
    for ( j = 1; j < 15; j++ )
    {
      sump = sump * xx + p[j];
    }

    xx = xx - two25;

    sumq = ((((
          xx + q[0]
      ) * xx + q[1]
      ) * xx + q[2]
      ) * xx + q[3]
      ) * xx + q[4];

    value = ( sump / sumq ) * x;
  }
  else if ( xmax < x )
  {
    value = r8_huge;
  }
//
//  15.0 <= ABS(ARG)
//
  else
  {
    xx = one / x - rec15;

    sump = ((((((
               pp[0]
        * xx + pp[1]
      ) * xx + pp[2]
      ) * xx + pp[3]
      ) * xx + pp[4]
      ) * xx + pp[5]
      ) * xx + pp[6]
      ) * xx + pp[7];

    sumq = (((((
          xx + qq[0]
      ) * xx + qq[1]
      ) * xx + qq[2]
      ) * xx + qq[3]
      ) * xx + qq[4]
      ) * xx + qq[5];

    value = sump / sumq;

    if ( xmax - one5 < x )
    {
      a = exp ( x - forty );
      b = exp40;
    }
    else
    {
      a = exp ( x );
      b = one;
    }
    value = ( ( value * a + pbar * a ) / sqrt ( x ) ) * b;
  }

  if ( arg < zero )
  {
    value = - value;
  }

  return value;
}
//****************************************************************************80

void bessel_i1_values ( int &n_data, double &x, double &fx )

//****************************************************************************80
//
//  Purpose:
//
//    BESSEL_I1_VALUES returns some values of the I1 Bessel function.
//
//  Discussion:
//
//    The modified Bessel functions In(Z) and Kn(Z) are solutions of
//    the differential equation
//
//      Z^2 W'' + Z * W' - ( Z^2 + N^2 ) * W = 0.
//
//    In Mathematica, the function can be evaluated by:
//
//      BesselI[1,x]
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    20 August 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Milton Abramowitz, Irene Stegun,
//    Handbook of Mathematical Functions,
//    National Bureau of Standards, 1964,
//    ISBN: 0-486-61272-4,
//    LC: QA47.A34.
//
//    Stephen Wolfram,
//    The Mathematica Book,
//    Fourth Edition,
//    Cambridge University Press, 1999,
//    ISBN: 0-521-64314-7,
//    LC: QA76.95.W65.
//
//  Parameters:
//
//    Input/output, int &N_DATA.  The user sets N_DATA to 0 before the
//    first call.  On each call, the routine increments N_DATA by 1, and
//    returns the corresponding data; when there is no more data, the
//    output value of N_DATA will be 0 again.
//
//    Output, double &X, the argument of the function.
//
//    Output, double &FX, the value of the function.
//
{
# define N_MAX 20

  static double fx_vec[N_MAX] = {
     0.0000000000000000E+00,
     0.1005008340281251E+00,
     0.2040267557335706E+00,
     0.3137040256049221E+00,
     0.4328648026206398E+00,
     0.5651591039924850E+00,
     0.7146779415526431E+00,
     0.8860919814143274E+00,
     0.1084810635129880E+01,
     0.1317167230391899E+01,
     0.1590636854637329E+01,
     0.2516716245288698E+01,
     0.3953370217402609E+01,
     0.6205834922258365E+01,
     0.9759465153704450E+01,
     0.1538922275373592E+02,
     0.2433564214245053E+02,
     0.6134193677764024E+02,
     0.3998731367825601E+03,
     0.2670988303701255E+04 };

  static double x_vec[N_MAX] = {
     0.00E+00,
     0.20E+00,
     0.40E+00,
     0.60E+00,
     0.80E+00,
     0.10E+01,
     0.12E+01,
     0.14E+01,
     0.16E+01,
     0.18E+01,
     0.20E+01,
     0.25E+01,
     0.30E+01,
     0.35E+01,
     0.40E+01,
     0.45E+01,
     0.50E+01,
     0.60E+01,
     0.80E+01,
     0.10E+02 };

  if ( n_data < 0 )
  {
    n_data = 0;
  }

  n_data = n_data + 1;

  if ( N_MAX < n_data )
  {
    n_data = 0;
    x = 0.0;
    fx = 0.0;
  }
  else
  {
    x = x_vec[n_data-1];
    fx = fx_vec[n_data-1];
  }

  return;
# undef N_MAX
}
//****************************************************************************80

//****************************************************************************80

double von_mises_cdf ( double x, double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_CDF evaluates the von Mises CDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    17 November 2006
//
//  Author:
//
//    Original FORTRAN77 version by Geoffrey Hill
//    C++ version by John Burkardt
//
//  Reference:
//
//    Geoffrey Hill,
//    ACM TOMS Algorithm 518,
//    Incomplete Bessel Function I0: The von Mises Distribution,
//    ACM Transactions on Mathematical Software,
//    Volume 3, Number 3, September 1977, pages 279-284.
//
//    Kanti Mardia, Peter Jupp,
//    Directional Statistics,
//    Wiley, 2000, QA276.M335
//
//  Parameters:
//
//    Input, double X, the argument of the CDF.
//    A - PI <= X <= A + PI.
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, double VON_MISES_CDF, the value of the CDF.
//
{
  double a1 = 12.0;
  double a2 = 0.8;
  double a3 = 8.0;
  double a4 = 1.0;
  double arg;
  double c;
  double c1 = 56.0;
  double cdf;
  double ck = 10.5;
  double cn;
  double erfx;
  int ip;
  int n;
  double p;
  const double r8_pi = 3.14159265358979323;
  double r;
  double s;
  double sn;
  double u;
  double v;
  double y;
  double z;
//
//  We expect -PI <= X - A <= PI.
//
  if ( x - a <= - r8_pi )
  {
    cdf = 0.0;
    return cdf;
  }

  if ( r8_pi <= x - a )
  {
    cdf = 1.0;
    return cdf;
  }
//
//  Convert the angle (X - A) modulo 2 PI to the range ( 0, 2 * PI ).
//
  z = b;

  u = r8_modp ( x - a + r8_pi, 2.0 * r8_pi );

  if ( u < 0.0 )
  {
    u = u + 2.0 * r8_pi;
  }

  y = u - r8_pi;
//
//  For small B, sum IP terms by backwards recursion.
//
  if ( z <= ck )
  {
    v = 0.0;

    if ( 0.0 < z )
    {
      ip = ( int ) ( z * a2 - a3 / ( z + a4 ) + a1 );
      p = ( double ) ( ip );
      s = sin ( y );
      c = cos ( y );
      y = p * y;
      sn = sin ( y );
      cn = cos ( y );
      r = 0.0;
      z = 2.0 / z;

      for ( n = 2; n <= ip; n++ )
      {
        p = p - 1.0;
        y = sn;
        sn = sn * c - cn * s;
        cn = cn * c + y * s;
        r = 1.0 / ( p * z + r );
        v = ( sn / p + v ) * r;
      }
    }
    cdf = ( u * 0.5 + v ) / r8_pi;
  }
//
//  For large B, compute the normal approximation and left tail.
//
  else
  {
    c = 24.0 * z;
    v = c - c1;
    r = sqrt ( ( 54.0 / ( 347.0 / v + 26.0 - c ) - 6.0 + c ) / 12.0 );
    z = sin ( 0.5 * y ) * r;
    s = 2.0 * z * z;
    v = v - s + 3.0;
    y = ( c - s - s - 16.0 ) / 3.0;
    y = ( ( s + 1.75 ) * s + 83.5 ) / v - y;
    arg = z * ( 1.0 - s / y / y );
    erfx = r8_error_f ( arg );
    cdf = 0.5 * erfx + 0.5;
  }

  cdf = r8_max ( cdf, 0.0 );
  cdf = r8_min ( cdf, 1.0 );

  return cdf;
}
//****************************************************************************80

double von_mises_cdf_inv ( double cdf, double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_CDF_INV inverts the von Mises CDF.
//
//  Discussion:
//
//    A simple bisection method is used on the interval [ A - PI, A + PI ].
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    17 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double CDF, the value of the CDF.
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, double VON_MISES_CDF_INV, the corresponding argument of the CDF.
//    A - PI <= X <= A + PI.
//
{
  double cdf1;
  double cdf3;
  int it;
  int it_max = 100;
  const double r8_pi = 3.14159265358979323;
  double tol = 0.0001;
  double x;
  double x1;
  double x2;
  double x3;

  if ( cdf < 0.0 || 1.0 < cdf )
  {
    cerr << " \n";
    cerr << "VON_MISES_CDF_INV - Fatal error!\n";
    cerr << "  CDF < 0 or 1 < CDF.\n";
    exit ( 1 );
  }

  if ( cdf == 0.0 )
  {
    x = a - r8_pi;
    return x;
  }
  else if ( 1.0 == cdf )
  {
    x = a + r8_pi;
    return x;
  }

  x1 = a - r8_pi;
  cdf1 = 0.0;

  x2 = a + r8_pi;
//
//  Now use bisection.
//
  it = 0;

  for ( ; ; )
  {
    it = it + 1;

    x3 = 0.5 * ( x1 + x2 );
    cdf3 = von_mises_cdf ( x3, a, b );

    if ( fabs ( cdf3 - cdf ) < tol )
    {
      x = x3;
      break;
    }

    if ( it_max < it )
    {
      cerr << " \n";
      cerr << "VON_MISES_CDF_INV - Fatal error!\n";
      cerr << "  Iteration limit exceeded.\n";
      exit ( 1 );
    }

    if ( ( cdf3 <= cdf && cdf1 <= cdf ) || ( cdf <= cdf3 && cdf <= cdf1 ) )
    {
      x1 = x3;
      cdf1 = cdf3;
    }
    else
    {
      x2 = x3;
    }
  }

  return x;
}
//****************************************************************************80

void von_mises_cdf_values ( int &n_data, double &a, double &b, double &x,
  double &fx )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_CDF_VALUES returns some values of the von Mises CDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    08 December 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Kanti Mardia, Peter Jupp,
//    Directional Statistics,
//    Wiley, 2000, QA276.M335
//
//  Parameters:
//
//    Input/output, int &N_DATA.  The user sets N_DATA to 0 before the
//    first call.  On each call, the routine increments N_DATA by 1, and
//    returns the corresponding data; when there is no more data, the
//    output value of N_DATA will be 0 again.
//
//    Output, double &A, &B, the parameters of the function.
//
//    Output, double &X, the argument of the function.
//
//    Output, double &FX, the value of the function.
//
{
# define N_MAX 23

  static double a_vec[N_MAX] = {
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.1E+01,
     0.1E+01,
     0.1E+01,
     0.1E+01,
     0.1E+01,
     0.1E+01,
    -0.2E+01,
    -0.1E+01,
     0.0E+01,
     0.1E+01,
     0.2E+01,
     0.3E+01,
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.0E+00,
     0.0E+00 };

  static double b_vec[N_MAX] = {
      0.1E+01,
      0.1E+01,
      0.1E+01,
      0.1E+01,
      0.1E+01,
      0.2E+01,
      0.2E+01,
      0.2E+01,
      0.2E+01,
      0.2E+01,
      0.2E+01,
      0.3E+01,
      0.3E+01,
      0.3E+01,
      0.3E+01,
      0.3E+01,
      0.3E+01,
      0.0E+00,
      0.1E+01,
      0.2E+01,
      0.3E+01,
      0.4E+01,
      0.5E+01 };

  static double fx_vec[N_MAX] = {
     0.2535089956281180E-01,
     0.1097539041177346E+00,
     0.5000000000000000E+00,
     0.8043381312498558E+00,
     0.9417460124555197E+00,
     0.5000000000000000E+00,
     0.6018204118446155E+00,
     0.6959356933122230E+00,
     0.7765935901304593E+00,
     0.8410725934916615E+00,
     0.8895777369550366E+00,
     0.9960322705517925E+00,
     0.9404336090170247E+00,
     0.5000000000000000E+00,
     0.5956639098297530E-01,
     0.3967729448207649E-02,
     0.2321953958111930E-03,
     0.6250000000000000E+00,
     0.7438406999109122E+00,
     0.8369224904294019E+00,
     0.8941711407897124E+00,
     0.9291058600568743E+00,
     0.9514289900655436E+00 };

  static double x_vec[N_MAX] = {
     -0.2617993977991494E+01,
     -0.1570796326794897E+01,
      0.0000000000000000E+00,
      0.1047197551196598E+01,
      0.2094395102393195E+01,
      0.1000000000000000E+01,
      0.1200000000000000E+01,
      0.1400000000000000E+01,
      0.1600000000000000E+01,
      0.1800000000000000E+01,
      0.2000000000000000E+01,
      0.0000000000000000E+00,
      0.0000000000000000E+00,
      0.0000000000000000E+00,
      0.0000000000000000E+00,
      0.0000000000000000E+00,
      0.0000000000000000E+00,
      0.7853981633974483E+00,
      0.7853981633974483E+00,
      0.7853981633974483E+00,
      0.7853981633974483E+00,
      0.7853981633974483E+00,
      0.7853981633974483E+00 };

  if ( n_data < 0 )
  {
    n_data = 0;
  }

  n_data = n_data + 1;

  if ( N_MAX < n_data )
  {
    n_data = 0;
    a = 0.0;
    b = 0.0;
    x = 0.0;
    fx = 0.0;
  }
  else
  {
    a = a_vec[n_data-1];
    b = b_vec[n_data-1];
    x = x_vec[n_data-1];
    fx = fx_vec[n_data-1];
  }

  return;
# undef N_MAX
}
//****************************************************************************80

bool von_mises_check ( double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_CHECK checks the parameters of the von Mises PDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    14 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, bool VON_MISES_CHECK, is true if the parameters are legal.
//
{
  const double r8_pi = 3.14159265358979323;

  if ( a < - r8_pi || r8_pi < a )
  {
    cout << " \n";
    cout << "VON_MISES_CHECK - Warning!\n";
    cout << "  A < -PI or PI < A.\n";
    return false;
  }

  if ( b <= 0.0 )
  {
    cout << " \n";
    cout << "VON_MISES_CHECK - Warning!\n";
    cout << "  B <= 0.0\n";
    return false;
  }

  return true;
#
}
//****************************************************************************80

double von_mises_circular_variance ( double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_CIRCULAR_VARIANCE returns the circular variance of the von Mises PDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    02 December 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, double VON_MISES_CIRCULAR_VARIANCE, the circular variance of the PDF.
//
{
  double value;

  value = 1.0 - bessel_i1 ( b ) / bessel_i0 ( b );

  return value;
}
//****************************************************************************80

double von_mises_mean ( double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_MEAN returns the mean of the von Mises PDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    17 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, double VON_MISES_MEAN, the mean of the PDF.
//
{
  double mean;

  mean = a;

  return mean;
}
//****************************************************************************80

double von_mises_pdf ( double x, double a, double b )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_PDF evaluates the von Mises PDF.
//
//  Discussion:
//
//    PDF(A,B;X) = EXP ( B * COS ( X - A ) ) / ( 2 * PI * I0(B) )
//
//    where:
//
//      I0(*) is the modified Bessel function of the first
//      kind of order 0.
//
//    The von Mises distribution for points on the unit circle is
//    analogous to the normal distribution of points on a line.
//    The variable X is interpreted as a deviation from the angle A,
//    with B controlling the amount of dispersion.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    27 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Jerry Banks, editor,
//    Handbook of Simulation,
//    Engineering and Management Press Books, 1998, page 160.
//
//    D J Best, N I Fisher,
//    Efficient Simulation of the von Mises Distribution,
//    Applied Statistics,
//    Volume 28, Number 2, pages 152-157.
//
//    Kanti Mardia, Peter Jupp,
//    Directional Statistics,
//    Wiley, 2000, QA276.M335
//
//  Parameters:
//
//    Input, double X, the argument of the PDF.
//    A - PI <= X <= A + PI.
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Output, double VON_MISES_PDF, the value of the PDF.
//
{
  double pdf;
  const double r8_pi = 3.14159265358979323;

  if ( x < a - r8_pi )
  {
    pdf = 0.0;
  }
  else if ( x <= a + r8_pi )
  {
    pdf = exp ( b * cos ( x - a ) ) / ( 2.0 * r8_pi * bessel_i0 ( b ) );
  }
  else
  {
    pdf = 0.0;
  }

  return pdf;
}
//****************************************************************************80

double von_mises_sample ( double a, double b, int &seed )

//****************************************************************************80
//
//  Purpose:
//
//    VON_MISES_SAMPLE samples the von Mises PDF.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    17 October 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    D J Best, N I Fisher,
//    Efficient Simulation of the von Mises Distribution,
//    Applied Statistics,
//    Volume 28, Number 2, pages 152-157.
//
//  Parameters:
//
//    Input, double A, B, the parameters of the PDF.
//    -PI <= A <= PI,
//    0.0 < B.
//
//    Input/output, int &SEED, a seed for the random number generator.
//
//    Output, double VON_MISES_SAMPLE, a sample of the PDF.
//
{
  double c;
  double f;
  const double r8_pi = 3.14159265358979323;
  double r;
  double rho;
  double tau;
  double u1;
  double u2;
  double u3;
  double x;
  double z;

  tau = 1.0 + sqrt ( 1.0 + 4.0 * b * b );
  rho = ( tau - sqrt ( 2.0 * tau ) ) / ( 2.0 * b );
  r = ( 1.0 + rho * rho ) / ( 2.0 * rho );

  for ( ; ; )
  {
    u1 = r8_uniform_01 ( seed );
    z = cos ( r8_pi * u1 );
    f = ( 1.0 + r * z ) / ( r + z );
    c = b * ( r - f );

    u2 = r8_uniform_01 ( seed );

    if ( u2 < c * ( 2.0 - c ) )
    {
      break;
    }

    if ( c <= log ( c / u2 ) + 1.0 )
    {
      break;
    }

  }

  u3 = r8_uniform_01 ( seed );

  x = a + r8_sign ( u3 - 0.5 ) * acos ( f );

  return x;
}
//****************************************************************************80
