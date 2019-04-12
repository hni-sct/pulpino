#include <stdlib.h>
#include "Vpulpino_top.h"
#include "verilated.h"

static vluint64_t main_time = 0;

double sc_time_stamp () {
    return main_time;
}

int main(int argc, char **argv) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // Create an instance of our module under test
    Vpulpino_top *tb = new Vpulpino_top;
    tb->rst_n = 0;
    tb->eval();
    main_time++;
    tb->rst_n = 1;
    tb->eval();
    main_time++;
    // Tick the clock until we are done
    for (int i =0; i < 100; i++) {
        tb->clk = 1;
        tb->eval();
        tb->clk = 0;
        tb->eval();
        main_time++;
    } exit(EXIT_SUCCESS);
}
