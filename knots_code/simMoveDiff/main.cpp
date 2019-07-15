
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
const int nAgents = 200;
const int tMax = 1e2;
const int rep = 100;

//uniform distr of move probs and scales
std::uniform_real_distribution<double> probPicker (0.f, 1.f);

//class agent
class agent
{
public:
    double xRw = 0.0, yRw = 0.0, xLf = 0.0, yLf = 0.0;
    //pick a constant movement probability from a uniform distr div 10
    double moveProb = probPicker(rng);

    //dec levy movement params
    double scale = static_cast<double>(moveProb * 10.0);
};

// make agent vec
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

    for(int time = 0; time < tMax; time++)
    {
        //get probabilistic movement
        for(int i = 0; i < nAgents; i++)
        {
            //confirm entry
            //std::cout << "time = " << time << " agent = " << i << endl;

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

            //write to file
            ofs << 1 << ","
                << time << ","
                << i << ","
                << pop[i].moveProb << ","
                << pop[i].xRw << "," << pop[i].yRw
                << pop[i].scale << ","
                << pop[i].xLf << "," << pop[i].yLf
                << endl;
        }

    }
    //close ofs
    ofs.close();
    gsl_rng_free (r);

    std::cout << "done with sims, move to R for analysis" << endl;
    return 0;
}
