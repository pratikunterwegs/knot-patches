/* header file defining von Mises distribution */

double von_mises_cdf ( double x, double a, double b );
double von_mises_cdf_inv ( double cdf, double a, double b );
void von_mises_cdf_values ( int &n_data, double &a, double &b, double &x,
  double &fx );
bool von_mises_check ( double a, double b );
double von_mises_mean ( double a, double b );
double von_mises_pdf ( double x, double a, double b );
double von_mises_sample ( double a, double b, int &seed );
double von_mises_circular_variance ( double a, double b );
