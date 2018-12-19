
/* a program that simulates agents with expectations moving in a landscape
 * with resource heterogeneity.
 * the landscape is discrete space, agents move in continuous space
 * agent position is rounded to discrete space
 * individuals begin with an intrinsic expectation,
 * individuals appear on a grid tile,
 * individuals sample the grid tile (with some error?),
 * individuals compare grid value with intrinsic expectation,
 * individuals update their expectation based on what they find
 * if higher, consume unit resource, check if grid now lower than expectation
 * if lower, move to a random patch
 *
 * MOVEMENT RULES OR PATCH LEAVING RULES
*/

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

std::mt19937_64 rng;

using namespace std;

#include "prob.hpp" //provides the von Mises distribution

//system params
const int nAgents = 20; //how many Birds
const int gridSize = 100; //grid size
//const double dIntake = 0.1; //intake rate per unit time is constant
const double maxStepLength = 3.5; //max dist (in grid cells) a Bird can move; can be double
const int nSims = 1;
const int nIterations = 60 * 13; //minutes in a tidal interval
const double unitstepLength = 0.0; //currently no travel cost

//set up random number generator
chrono::high_resolution_clock::time_point tp =
                        chrono::high_resolution_clock::now();
unsigned seed = static_cast<unsigned> (tp.time_since_epoch().count());
int vmSeed = static_cast<int> (seed);

//init a grid landscape of n^2 cells
vector<vector<double> > landscape (gridSize, vector<double> (gridSize));

//initialise landscape with double value from 0 - 1, mean of 0.5
//each cell has a random value
void readLandscape(vector<vector<double> > &landscape)
{
    //open input stream
    ifstream ifs("../movement_model/landscape.csv");
    if(!ifs.is_open()){
            cerr << "error: unable to open input stream\n";
            exit(EXIT_FAILURE);
        }
        else
            cout << "input stream opened" << endl;
    for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          ifs >> landscape[i][j];
        }
      }
      //close input stream
      ifs.close();
      cout << "input read and stream closed...\n";

}

void writeLandscape(vector<vector<double> > &landscape)
{
    //open out stream
    ofstream ofs_landscape("../movement_model/landscape_after_forage.csv");
    //ifstream ifs("../cri_2018/landscape.csv");
    if(!ofs_landscape.is_open()){
            cerr << "error: unable to open input stream\n";
            exit(EXIT_FAILURE);
        }
        else
            cout << "landscape output after foraging opened" << endl;
    for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          ofs_landscape << landscape[i][j];
        }
      }
      //close input stream
      ofs_landscape.close();
      cout << "landscape foraged and stream closed...\n";

}

//create indivs class
class Bird //changed from Bird to Bird
{
private:

public:
    //these vars need to be made private!
    //write Bird pos function needs to be fixed
    int x; int y;
    int xPast; int yPast;
    double totalIntake;
    double sample; double expec;
    double stepLength;
    double angle; //changing from angle to angle
    //int behavType; //removing behav type to focus on initial expectation & landscape autocorr.
    //public functions to init sample, update expec, consume, move (if needed)
    void initBird();
    void sampleLandscape();
    void updateExpectation();
    void consumeFood();
    void moveBird();
    void writePos();
};

//write class functions
//read in ofstreams
//func to initialise 20 Birds at random points
void Bird::initBird()
{
    //pick a start location and expectation
    uniform_int_distribution<int> xPicker (0, gridSize - 1); //position x
    uniform_int_distribution<int> yPicker (0, gridSize - 1); //position y
    uniform_real_distribution<double> expectPicker (0.0, 1.0); //expectn. distr.

    x = xPicker(rng); y = yPicker(rng); expec = expectPicker(rng);
    xPast = x; yPast = y; stepLength = 0; angle = 0;
    //removed behavioural type picker
}

//func to sample landscape
void Bird::sampleLandscape()
{
    sample = landscape[x][y];
}

//function to update expectation
void Bird::updateExpectation()
{
    expec = ((expec + sample)/2.0) - (unitstepLength * stepLength);
}

//function to consume food
void Bird::consumeFood()
{
    double dIntake = landscape[x][y] * 0.1;
    totalIntake = totalIntake  + dIntake -
            (unitstepLength * stepLength);
    landscape[x][y] -= dIntake;
}

//function to decide to move
void Bird::moveBird()
{
    double diff = expec - landscape[x][y];
    xPast = x; yPast = y;
    //define move condition and process
    if(diff > 0)
    {
        //pick an angle of travel from von Mises distr
        angle = von_mises_sample(0.0, diff, vmSeed);

        //pick a distance between 0 and max steplength
        exponential_distribution <double> distPicker ((1 - diff) * maxStepLength);
        stepLength = distPicker(rng);

        //get continuous position
        x = (x + stepLength * cos(angle)); y = (y + stepLength * sin(angle));
        //get discrete posn and handle boundaries
        x = static_cast<int> (round(x)) % gridSize; y = static_cast<int> (round(y)) % gridSize;

    }
    else
        consumeFood();

}

//make population
vector<Bird> population (nAgents);

//main func
int main()
{
    //read landscape
    readLandscape(landscape);

        //write seed to log
        clog << "random seed : " << seed << "\n";
        //create rng and assign seed
        rng.seed(seed);


    //open ofstream
    ofstream ofs;
    ofs.open("../movement_model/data_sim.csv");
    //column names
    ofs << "sim, iteration, id, behav, x, y, stepLength, direction, expectation, sample, totalIntake"
        << endl;
    for(int sim = 0; sim < nSims; ++sim)
    {
        //init Birds
        for(int i = 0; i < nAgents; i++)
        {
            population[i].initBird();
        }
        cout << "simulation run..." << sim << endl;
        //open ofstream

        //loop through iterations
        for(int it = 0; it < nIterations; ++it)
        {
            cout << "sim... " << sim << " iteration... " << it << endl;
            for(int i = 0; i < nAgents; ++i)
            {
                Bird BirdNow = population[i];

                population[i].sampleLandscape();
                population[i].updateExpectation();
                population[i].moveBird();
                //print to file
                ofs << sim << "," << it << "," << i << ","
                    << BirdNow.x << ","
                    << BirdNow.y << ","
                    << BirdNow.stepLength << ","
                    << BirdNow.angle << ","
                    << BirdNow.expec << ","
                    << BirdNow.sample << ","
                    << BirdNow.totalIntake << endl;
                //ofs << endl;
                //cout << "printed it " << it << " indiv " << i << endl;

            }
            //ofs << endl;

        }
        //ofs << endl;

    }
    return 0;

    ofs.close();

    writeLandscape(landscape);

}



//void Bird::writePos()
//{
//    ofstream ofs("../cri_2018/data_sim.csv", ofstream::out|ofstream::app);
//    ofs << "," << behavType << ","
//        //<< x << "," << y << "," << stepLength << "," << angle << ","
//        //<< expec << "," << sample << ","
//        << totalIntake
//        << endl;
//}
