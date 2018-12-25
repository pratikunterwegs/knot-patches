
/* a program that simulates agents with expectations moving in a landscape
 * with resource heterogeneity.
 * individuals begin with an intrinsic expectation,
 * individuals appear on a grid tile,
 * individuals sample the grid tile (with some error?),
 * individuals compare grid value with intrinsic expectation,
 * individuals update their expectation based on what they find
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

//init the rng
std::mt19937_64 rng;

using namespace std;

//system params
const int nAgents = 20;                         //how many Birds
const int gridSize = 100;                       //grid size
const double maxStepLength = 50.0;               //max dist (in grid cells) a Bird can move; can be double
const int nSims = 1;
const double posPerHour = 60;                      //how many locations per hour? ATLAS provides 3600 (1 Hz), 900 (.25 Hz)
                                                //here we use only 60 per hour (0.0167 Hz)
const double tidalCycle = 13;
const double iNtidalCycles = 10; //duration in hours of the tidal cycle = mean time between 2 high/low tides
const double maxWaterHeight = 0.9;              //the max height of landscape covered by water; the high tide contour

const int nIterations = posPerHour * tidalCycle * iNtidalCycles; //positions per indiv in a tidal cycle
//const double tidalTimeIncrement = (1.0 / static_cast<double> (nIterations));

const double Pi = 3.142;

//set up random number generator
chrono::high_resolution_clock::time_point tp =
                        chrono::high_resolution_clock::now();
unsigned seed = static_cast<unsigned> (tp.time_since_epoch().count());
int vmSeed = static_cast<int> (seed);

// DEFINE MUDFLAT CLASS - THIS IS THE LANDSCAPE
//a simple class to hold landscape values and determine whether the cell is exposed or not
class Mudflat
{
public:
    double food;                                //the resource value
    double height;                              //the elevation, determines covered by water or no
    bool open;                        //ease or prob of finding food in a grid cell
};

//init a grid landscape of n^2 cells
vector<vector<Mudflat> > landscape (gridSize, vector<Mudflat> (gridSize));

// FUNCTION TO READ THE FOOD LANDSCAPE
void readFoodLandscape(vector<vector<Mudflat> > &landscape, string &file)
{
    //open input stream
    ifstream ifs(file.c_str());
    if(!ifs.is_open()){
            cerr << "error: unable to open food landscape input stream\n";
            exit(EXIT_FAILURE);
        }
     else
        cout << "food landscape input stream opened" << endl;
    for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          ifs >> landscape[i][j].food;
        }
      }
      //close input stream
      ifs.close();
      cout << "food landscape input read and stream closed...\n";

}

// FUNCTION TO READ THE TIDAL LANSDCAPE
void readTideLandscape(vector<vector<Mudflat> > &landscape)
{
    //open input stream
    ifstream ifs("../movement_model/tide_landscape.csv");
    if(!ifs.is_open()){
            cerr << "error: unable to open tide landscape input stream\n";
            exit(EXIT_FAILURE);
        }
     else
        cout << "tide landscape input stream opened" << endl;

    for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          ifs >> landscape[i][j].height;

          //set food at cells with height > 0.8 = 0
          if(landscape[i][j].height >= 0.8) landscape[i][j].food = 0;
        }
      }
      //close input stream
      ifs.close();
      cout << "tide landscape input read and stream closed...\n";

}

// DEFINE CLASS BIRD - THESE ARE AGENTS
class Bird //changed from bird to Bird
{
private:
    int x; int y;                       //coordinates
    double totalIntake;                 //total 'energy' level
    double sample; double expec;        //sample from the landscape; intrinsic expectation value
    double stepLength;                     //distance travelled
    int angle;                          //not really an angle! a direction 0 - 7
    double height;                      //elevation at which bird is

public:
    //public functions to init, sample, update expec, consume, move (if needed)
    void initBird();
    void sampleLandscape();
    void updateExpectation();
    void consumeFood();
    void moveBird();
    void writePos();
};

//write class functions
//func to initialise 20 Birds at random points
void Bird::initBird()
{
    //pick a start location and expectation
    uniform_int_distribution<int> xPicker (0, gridSize - 1); //position x
    uniform_int_distribution<int> yPicker (0, gridSize - 1); //position y
    uniform_real_distribution<double> expectPicker (0.0, 1.0); //expectn. distr.

    x = xPicker(rng); y = yPicker(rng); expec = expectPicker(rng);
    stepLength = 0; angle = 0;
    height = landscape[x][y].height;
    //removed behavioural type picker
}

//func to sample landscape
void Bird::sampleLandscape()
{
    //reduce some intake as constant
    totalIntake -= 0.01;
    //sample landscape cell for food and height
    sample = landscape[x][y].food;

    height = landscape[x][y].height;
}

//function to update expectation
void Bird::updateExpectation()
{
    expec = (expec * 0.5 + 0.5 * sample);
}

//function to consume food
void Bird::consumeFood()
{
    //consume n % of food - implements diminishing absolute return
    double dIntake = landscape[x][y].food * 0.1;
    //add consumed food to 'energy' reserves
    totalIntake = totalIntake  + dIntake;
    //reduce landscape value by consumed food value
    landscape[x][y].food -= dIntake;
}

//function to decide to move
void Bird::moveBird()
{
    //if the landscape is covered by water, set diff = expec, bird should then move
    double diff = landscape[x][y].open == false ? expec : expec - landscape[x][y].food;
    //define move condition and process
    if(diff > 0)
    {
        //choose a new location until land is found
        do{
            //determine whether to pick a new angle: low diff = higher prob of new angle
            normal_distribution <double> dirChanger(0.5, 0.2);

            if(dirChanger(rng) > diff)
            {
                //pick an direction of travel: 0 - 7
                uniform_int_distribution <int> anglePicker(0,7);
                angle = anglePicker(rng);
            }

            //pick a distance between 0 and max steplength
            //exponential_distribution <double> distPicker (1 - diff);
            //stepLength = distPicker(rng);
            int distance = 1;

            //get new position
            switch (angle) {
            //0 = y+1, x+0
            case 0: y = (y + distance) % gridSize ; break;
                //1 =
            case 1: x = (x + distance) % gridSize; y = (y + distance) % gridSize; break;
            case 2: x = (x + distance) % gridSize; break;
            case 3: x = (x + distance) % gridSize; y = (y - distance + gridSize) % gridSize; break;
            case 4: y = (y + distance) % gridSize; break;
            case 5: x = (x - distance + gridSize) % gridSize; y = (y - distance + gridSize) % gridSize; break;
            case 6: x = (x - distance + gridSize) % gridSize; break;
            case 7: x = (x - distance + gridSize) % gridSize; y = (y + distance + gridSize) % gridSize; break;
            default: cerr << "could not choose a step direction!" << endl;
                exit(EXIT_FAILURE);
            }
            //bird loses some 'energy' when it moves
            //totalIntake = totalIntake - (0.001 * stepLength);
        }
        while( landscape[x][y].open == false );
    }
    else
        consumeFood();

}

void Bird::writePos()
{
    ofstream ofs("../movement_model/data_sim.csv", ofstream::out|ofstream::app);
    ofs << ","
        << x << "," << y << "," << height << "," << landscape[x][y].open << ","
        << stepLength << "," << angle << ","
        << expec << "," << sample << ","
        << totalIntake
        << endl;
}

//make population
vector<Bird> population (nAgents);

//main func
int main()
{
    cout << "opened main function" << endl;
    //define vector of water heights over nIterations. water reaches maxWaterHeight
    vector<double> waterHeight (nIterations);
    //get vector of water heights
    for(int tidalTime = 0; tidalTime < nIterations; ++tidalTime)
    {
        //double scaledTime = tidalTime/static_cast<double>(nIterations);

        waterHeight[tidalTime] = maxWaterHeight - (0.45 * cos(((2.0 * Pi)/780.0) * tidalTime ) + 0.45);

    }
    cout << "calculated water heights" << endl;

    //read tidal/bathymetric landscape
    readTideLandscape(landscape);
    cout << "read in the tidal landscape...\n" << endl;

    //write seed to log
    clog << "random seed : " << seed << "\n";
    //create rng and assign seed
    rng.seed(seed);


    //open ofstream
    ofstream ofs;
    ofs.open("../movement_model/data_sim.csv");
    //column names
    ofs << "sim, land_autocorr, iteration, time, id, x, y, elev, landOpen, stepLength, direction, expectation, sample, totalIntake"
        << endl;
    ofs.close();


    //this level controls the autocorrelation level
    for(int sim = 0; sim < nSims; ++sim)
    {
        //set the filename for the food landscape
        string file ("../movement_model/food_landscape" + to_string(sim+2) + ".csv");

        cout << "read input food landscape as...\n" << file.c_str() << endl;

        //read food_landscape
        readFoodLandscape(landscape, file);
        cout << "read in the food landscape..." << endl;

        // this level controls the replicates
        for(int j = 0; j < 1; ++j)
        {
            //init Birds
            for(int i = 0; i < nAgents; ++i)
            {
                population[i].initBird();
            }
            cout << "simulation run..." << sim << endl;
            //open ofstream

            //LOOP THROUGH THE TIDAL CYCLE
            for(int it = 0; it < nIterations; ++it)
            {
                //get water height
                cout << "water height is..." << waterHeight[it] << endl;

                //change the value of landscape cells to closed if height < water height
                for(int gridRow = 0; gridRow < gridSize; ++gridRow)
                {
                    for(int gridCol = 0; gridCol < gridSize; ++gridCol)
                    {
                        landscape[gridRow][gridCol].open = landscape[gridRow][gridCol].height <
                                waterHeight[it] ? false : true;
                    }
                }

                //display which sim is being run
                cout << "sim... " << sim << " iteration... " << it << endl;
                for(int i = 0; i < nAgents; ++i)
                {
                    //print to file
                    ofs.open("../movement_model/data_sim.csv", ofstream::out|ofstream::app);
                    ofs << sim << "," << sim+2 << "," << j << "," << it << "," << i;
                    ofs.close();

                    //print to screen!
                    cout << sim << " " << j << " " << it << " " <<  i << endl;

                    population[i].sampleLandscape();
                    population[i].updateExpectation();
                    population[i].moveBird();


                    population[i].writePos();
                    ofs << endl;
                    //cout << "printed it " << it << " indiv " << i << endl;

                }


            }
            //ofs << endl;

        }
    }

    ofs.close();
    cout << "all sims run and complete...move to R script to run models and make plots\n\n";

    //cout << "\nwriting food landscape after foraging...\n\n";     //optional, write landscape after foraging
    //writeLandscape(food_landscape);

    return 0;

}




