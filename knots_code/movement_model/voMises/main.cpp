// -*- mode: C++; c-indent-level: 4; c-basic-offset: 4;  tab-width: 8; -*-
//
// Simple example showing how to do the standard 'hello, world' using embedded R
//
// Copyright (C) 2009 Dirk Eddelbuettel
// Copyright (C) 2010 Dirk Eddelbuettel and Romain Francois
//
// GPL'ed

#include <RInside.h>                    // for the embedded R via RInside
#include <Rcpp.h>
#include <iostream>
                   // for the embedded R via RInside

using namespace std;

int main(int argc, char *argv[]) {

    RInside R(argc, argv);              // create an embedded R instance

    std::string cmd1 = "library(circular)";
    R.parseEval(cmd1); 		        // eval the init string, ignoring any returns

    string cmd2 = "rvonmises(1, 0, 5)";
    for(int i = 0; i < 1e2; i++){
        const double a = R.parseEval(cmd2);
        std::cout << "a = " << a << "\n";
    }
    exit(0);
}
