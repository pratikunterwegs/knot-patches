
//include gsl for distributions
#include <stdio.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
//load libs
#include <iostream>
#include <fstream>
#include <vector>
#include <exception>
#include <cstdlib>
#include <random>
#include <chrono>
#include <algorithm>
#include <cmath>


//init the rng
std::mt19937_64 rng;

using namespace std;

//system parameters
const int nAgents = 100;
const int tMax = 1e3;
const int repMax = 20;

//levy flight params
double alpha = 2.0; //exponent of the levy-skew distr
double beta = 1.0; //skewness param

//uniform distr of move probs and scales
std::uniform_real_distribution<double> probPicker (0.0, 1.0);

//class agent
class agent
{
public:
    double xRw = 0.0, yRw = 0.0, xLf = 0.0, yLf = 0.0;
    //pick a constant movement probability from a uniform distr div 10
    double moveProb = probPicker(rng);

    //dec levy movement params
    double scale = (moveProb * 5.0);
};

// make agent vec, remains constant over replicates, but not b/w sims
std::vector<agent> pop (nAgents);

//run sim and get data
//over 100 replicates, 200 agents are examined at 10,000 timesteps
//at each timestep they have a pre-defined probability of moving
//
int main(void)
{
    // make a gsl rng
    const gsl_rng_type * T;
    gsl_rng * r;

    gsl_rng_env_setup();
    T = gsl_rng_default;
    r = gsl_rng_alloc (T);

    //open ofstream
    ofstream ofs;
    ofs.open("../simMoveDiff/dataSimMoveDiff.csv");

    std::cout << "opened output file..." << endl;

    //column names
    ofs << "replicate, time, id, moveProb, xRw, yRw, moveScale, xLf, yLf"
        << endl;

    for (int rep = 0; rep < repMax; rep++)
    {
        // clear agent positions
        for (int i = 0; i < nAgents; i++)
        {
            pop[i].xRw = pop[i].yRw = pop[i].xLf = pop[i].yLf = 0.0;
        }

        std::cout << "processing rep " << rep << endl;
        for(int time = 0; time < tMax; time++)
        {
            std::cout << "rep = " << rep << " time = " << time << endl;
            //get probabilistic movement
            for(int i = 0; i < nAgents; i++)
            {
                //confirm entry
                std::cout << "time = " << time << " agent = " << i << endl;

                //dec a bernoulli distribution with probability centred on moveprob
                std::bernoulli_distribution dBern (pop[i].moveProb);

                //random walk move or not? if move, update position
                if (dBern(rng))
                {
                    double dx, dy;
                    //pick a movement angle
                    gsl_ran_dir_2d(r, &dx, &dy);
                    pop[i].xRw += dx; pop[i].yRw += dy;
                }

                //levy flight movement as x and y + dx dy
                {
                    // change in x and y, distances of x and y displacement
                    double dx, dy, moveX, moveY;
                    // select a direction
                    gsl_ran_dir_2d(r, &dx, &dy);
                    // get a levy movement distance
                    moveX = gsl_ran_levy_skew(r, pop[i].scale, alpha, beta);
                    moveY = gsl_ran_levy_skew(r, pop[i].scale, alpha, beta);
                    pop[i].xLf += (dx*moveX); pop[i].yLf += (dy*moveY);

                }

                //write to file
                ofs << rep << ","
                    << time << ","
                    << i << ","
                    << pop[i].moveProb << ","
                    << pop[i].xRw << "," << pop[i].yRw << ","
                    << pop[i].scale << ","
                    << pop[i].xLf << "," << pop[i].yLf
                    << endl;
            }

        }
    }
        //close ofs
        ofs.close();
        gsl_rng_free (r);

    std::cout << "done with sims, move to R for analysis" << endl;
    return 0;
}
