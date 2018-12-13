// Example program
#include <iostream>
#include <string>
#include <chrono>
#include <vector>		// for vector related commands
#include <random>		//random number generation, necessary?
//#include "pch.h"

using namespace std;


std::mt19937 rng(static_cast<unsigned>(std::chrono::high_resolution_clock::now().time_since_epoch().count()));





class Patch {
public:
        Patch(const int row, const int col, double host1, double host2, double par) : xcoor{ row }, ycoor{ col },
                m_Host1{ host1 }, m_Host2{ host2 }, m_Par{ par }   {}

        double host1() { return m_Host1; }

        double host2() { return m_Host2; }

        double par() { return m_Par; }

        void updateH1(double change) {
                m_Host1 += change;
        }
        void updateH2(double change) {
                m_Host2 += change;
        }
        void updateP(double change) {
                m_Par += change;
        }

        void growth(double fecund1, double fecund2) {

                double Par_temp = m_Host1 * (1 - exp(-m_Par)) + m_Host2 * (1 - exp(-m_Par));

                m_Host1 = fecund1 * m_Host1 * exp(-m_Par);
                m_Host2 = fecund2 * m_Host2 * exp(-m_Par);

                        m_Par = Par_temp;
        }

        double dispersal1(double rateH1) {

                double disp = m_Host1 * rateH1;

                m_Host1 -= disp;

                return(disp);
        }

        double dispersal2(double rateH2) {

                double disp = m_Host2 * rateH2;

                m_Host2 -= disp;

                return(disp);
        }

        double dispersal3(double rateP) {

                double disp = m_Par * rateP;

                m_Par -= disp;

                return(disp);
        }
private:
        double m_Host1;
        double m_Host2;
        double m_Par;
        int xcoor;
        int ycoor;
};

///
class landscape
{
public:
        landscape(std::vector<Patch> cells, int ndims) : m_cells{ cells },
                m_dims{ ndims } {}
        const Patch& operator()(int x, int y) const
        {
                int pos_x = (x + m_dims) % m_dims;
                int pos_y = (y + m_dims) % m_dims;

                return m_cells[pos_y * m_dims + pos_x];
        }
        Patch& operator()(int x, int y) {

                int pos_x = (x + m_dims) % m_dims;
                int pos_y = (y + m_dims) % m_dims;

                return m_cells[pos_y * m_dims + pos_x];
        }

        Patch& operator()(int n) {

                return m_cells[n];
        }

        int size() const { return static_cast<int>(m_cells.size()); }
        int xsize() const { return m_dims; }
        int ysize() const { return m_dims; }

private:
        std::vector<Patch> m_cells;
        int m_dims;
};




landscape create_landscape(const int n_dims)
{

        std::uniform_real_distribution<double> dist1(0.00, 4.00); // Equilibrium values
        std::uniform_real_distribution<double> dist2(0.00, 4.00); // Equilibrium values
        std::uniform_real_distribution<double> dist3(0.00, 4.00); // Equilibrium values



        //X-Y-ordered
        std::vector<Patch> Patches;
        //landscape my_landscape(std::vector<plot>(n_rows * n_cols), n_cols);
        for (int row = 0; row != n_dims; ++row)
        {
                for (int col = 0; col != n_dims; ++col)
                {

                        double Host1 = dist1(rng);
                        double Host2 = dist2(rng);
                        double Par = dist3(rng);

                        Patch singleplot(row, col, Host1, Host2, Par);

                        Patches.push_back(singleplot);
                }
        }
        landscape my_landscape(Patches, n_dims);
        return my_landscape;
}




int main()
{

        double fecund1 = 0.01;
        double fecund2 = 0.01;
        double dispH1 = 0.01;
        double dispH2 = 0.01;
        double dispP = 0.01;

        int stepsize = 1;
        const int lat_size = 10;


        landscape Landscape1= create_landscape(lat_size);
        // random initialization of patches
        //edge effects


        double disp_matrixH1[lat_size][lat_size];
        double disp_matrixH2[lat_size][lat_size];
        double disp_matrixP[lat_size][lat_size];


        for (int t = 0; t < 10; ++t) {



                for (int i = 0; i < lat_size; ++i) {

                        for (int j = 0; j < lat_size; ++j) {


                                //careful: populations are not grown at the same time
                                Landscape1(i, j).growth(fecund1, fecund2);

                        }
                }

                for (int i = 0; i < lat_size; ++i) {

                        for (int j = 0; j < lat_size; ++j) {

                                //Dispersal
                                double DH1 = Landscape1(i, j).dispersal1(dispH1);
                                double DH2 = Landscape1(i, j).dispersal2(dispH2);
                                double DP = Landscape1(i, j).dispersal3(dispP);

                                for (int sx = -stepsize; sx < stepsize; ++sx) {
                                        for (int sy = -stepsize; sy < stepsize; ++sy) {
                                                disp_matrixH1[i + sx][sy + j] += DH1 / (2 * stepsize + 1);
                                                disp_matrixH2[i + sx][sy + j] += DH2 / (2 * stepsize + 1);
                                                disp_matrixP[i + sx][sy + j] += DP / (2 * stepsize + 1);

                                        }
                                }

                                for (int i = 0; i < lat_size; ++i) {

                                        for (int j = 0; j < lat_size; ++j) {


                                                Landscape1(i, j).updateH1(disp_matrixH1[i][j]);
                                                Landscape1(i, j).updateH2(disp_matrixH2[i][j]);
                                                Landscape1(i, j).updateP(disp_matrixP[i][j]);

                                                disp_matrixH1[i][j] = 0.00;
                                                disp_matrixH2[i][j] = 0.00;
                                                disp_matrixP[i][j] = 0.00;

                                        }

                                }
                        }
                }


        }

        std::string name;
        std::cout << "What is your name? ";
        getline(std::cin, name);
        std::cout << "Hello, " << name << "!\n";




}
