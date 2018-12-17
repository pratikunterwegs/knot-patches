
/* a program that simulates agents with expectations moving in a landscape
 * with resource heterogeneity.
 * individuals begin with an intrinsic expectation,
 * individuals appear on a grid tile,
 * individuals sample the grid tile (with some error?),
 * individuals compare grid value with intrinsic expectation,
 * individuals update their expectation based on what they found
 * if higher, consume unit resource, check if grid now lower than expectation
 * if lower, move to a random patch
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

//system params
const int nAgents = 20; //how many birds
const int gridSize = 100; //grid size
const int nSims = 500;
const int nIterations = 500;
const double unitstepLength = 0.001;

//init a grid landscape of n^2 cells
vector<vector<double> > landscape (gridSize, vector<double> (gridSize));

//initialise landscape with double value from 0 - 1, mean of 0.5
//each cell has a random value
void readLandscape(vector<vector<double> > &landscape)
{
    //open input stream
    ifstream ifs("../cri_2018/landscape.csv");
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
    ofstream ofs_landscape("../cri_2018/landscape_after_forage.csv");
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
class bird
{
private:

public:
    int x; int y;
    int xPast; int yPast;
    double totalIntake;
    double sample; double expec;
    int stepLength;
    int travelDirection;
    int behavType;
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
//func to initialise 20 birds at random points
void bird::initBird()
{
    //pick a start location and expectation
    uniform_int_distribution<int> xPicker (0, gridSize - 1); //position x
    uniform_int_distribution<int> yPicker (0, gridSize - 1); //position y
    uniform_real_distribution<double> expectPicker (0.0, 1.0); //expectn. distr.

    x = xPicker(rng); y = yPicker(rng); expec = expectPicker(rng);
    xPast = x; yPast = y; stepLength = 0; travelDirection = 0;

    //pick a behavioural type
    uniform_int_distribution<int> behavPicker (0, 3);
    behavType = behavPicker(rng);
}

//func to sample landscape
void bird::sampleLandscape()
{
    sample = landscape[x][y];
}

//function to update expectation
void bird::updateExpectation()
{
    expec = ((expec + sample)/2.0) - (unitstepLength * stepLength);
}

//function to consume food
void bird::consumeFood()
{
    double dIntake = (landscape[x][y] / 10.0);
    totalIntake = totalIntake  + dIntake -
            (unitstepLength * stepLength);
    landscape[x][y] -= dIntake;
}

//function to decide to move
void bird::moveBird()
{
    double landscapeVal = landscape[x][y];
    double diff = expec - landscapeVal;
    double neutralDist;
    xPast = x; yPast = y;
    //define move condition and process
    if(diff > 0)
    {
        //should direction change?
        normal_distribution<double> directionSwitchPicker(0.5, 0.2);
        double directionSwitch = directionSwitchPicker(rng);

        double exponentPowerDiff;
        switch (behavType) {
        case 0: //random selection of direction and distance
            directionSwitch = 0.0; //reset direction choosing
            neutralDist = directionSwitchPicker(rng);
            break; //0 value is always low = random walk
        case 1: //updates only distance
            neutralDist = diff;
            directionSwitch = 0.0; //reset direction choosing
            break;
        case 2: //updates only direction -- already done
            neutralDist = directionSwitchPicker(rng);
            break; //0 value is always low = random walk
        case 3: //update both direction and distance
            neutralDist = diff;
            break; //0 value is always low = random walk
        default: cerr << "could not decide what to do for this bird..." << endl;
            exit(EXIT_FAILURE);
        }

        double meanNorm = neutralDist * 10.0;
        double sdNorm = 0.25 * 10.0 * neutralDist;
        normal_distribution<double> posPicker(meanNorm, sdNorm);
        stepLength = static_cast<int>(ceil( posPicker(rng) ));
        //if direction switch is less than 1 - difference expectation - reality
        if(directionSwitch < (1.0 - diff))
        {
            //pick a new direction and update the private variable
            uniform_int_distribution<int> directionPicker(0, 3);
            travelDirection = directionPicker(rng);

        }

        switch (travelDirection)
        {
        case 0: y = (y + stepLength) % gridSize; break;
        case 1: x = (x + stepLength) % gridSize; break;
        case 2: y = (y - stepLength + gridSize) % gridSize; break;
        case 3: x = (x - stepLength + gridSize) % gridSize; break;
        default: cerr << "could not choose a step...\n\n";
            exit(EXIT_FAILURE);
        }

    }
    else
        consumeFood();

}

//make population
vector<bird> population (nAgents);



//main func
int main()
{
    //read landscape
    readLandscape(landscape);
    //set up random number generator
        chrono::high_resolution_clock::time_point tp =
                            chrono::high_resolution_clock::now();
        unsigned seed = static_cast<unsigned> (tp.time_since_epoch().count());
        //write seed to log
        clog << "random seed : " << seed << "\n";
        //create rng and assign seed
        rng.seed(seed);


    //open ofstream
    ofstream ofs;
    ofs.open("../cri_2018/data_sim.csv");
    //column names
    ofs << "sim, iteration, id, behav, x, y, stepLength, direction, expectation, sample, totalIntake"
        << endl;
    for(int sim = 0; sim < nSims; ++sim)
    {
        //init birds
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
                bird birdNow = population[i];

                population[i].sampleLandscape();
                population[i].updateExpectation();
                population[i].moveBird();
                //print to file
                ofs << sim << "," << it << "," << i << ","
                    << birdNow.behavType << ","
                    << birdNow.x << ","
                    << birdNow.y << ","
                    << birdNow.stepLength << ","
                    << birdNow.travelDirection << ","
                    << birdNow.expec << ","
                    << birdNow.sample << ","
                    << birdNow.totalIntake << endl;
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



//void bird::writePos()
//{
//    ofstream ofs("../cri_2018/data_sim.csv", ofstream::out|ofstream::app);
//    ofs << "," << behavType << ","
//        //<< x << "," << y << "," << stepLength << "," << travelDirection << ","
//        //<< expec << "," << sample << ","
//        << totalIntake
//        << endl;
//}
