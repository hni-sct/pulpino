#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <getopt.h>
#include <chrono>
#include <ctime>
#include <signal.h>
#include <unistd.h>

#include "Vpulpino_top.h"
#include "verilated_vcd_c.h"
#include "verilated.h"

#define VM_TRACE

static vluint64_t main_time = 0;

double sc_time_stamp () {
    return main_time;
}

void run_tick_clk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->clk = 1;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    tb->clk = 0;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;
}

void run_tick_sclk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->spi_clk_i = 1;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    tb->spi_clk_i = 0;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;
}




typedef struct SPIData {
    uint32_t addr;
    uint32_t data;
} SPIData;

void spi_send_cmd_addr(Vpulpino_top *top, VerilatedVcdC *tfp, uint8_t cmd, uint32_t spi_addr)
{
    for (int i = 7; i >=0; i--) {
        top->spi_sdi0_i = (cmd & (1 << i)) >> i;
        run_tick_sclk(top, tfp);
    }
    for (int i = 31; i >=0; i--) {
        top->spi_sdi0_i = (spi_addr & (1 << i)) >> i;
        run_tick_sclk(top, tfp);
    }

}

void spi_load_hex(Vpulpino_top *top, VerilatedVcdC *tfp, const char *filepath)
{
    FILE *fp = fopen(filepath, "r");
    char buf[255];
    std::vector<SPIData*> data;

    while (fgets(buf, 255, (FILE*) fp)) {
        char *ptr;
        uint32_t val;
        SPIData *elm = (SPIData*)malloc(sizeof(SPIData));
        ptr = strtok(buf, "_");
        elm->addr = (uint32_t)strtol(ptr, NULL, 16);
        ptr = strtok(NULL, "_");
        elm->data = (uint32_t)strtol(ptr, NULL, 16);
        data.push_back(elm);
    }
    spi_send_cmd_addr(top, tfp, 0x2, data[0]->addr);

    fclose(fp);
}

int main(int argc, char **argv) {

#ifdef VM_TRACE
    FILE *vcdfile = NULL;
    uint64_t start = 0;
#endif

    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // Create an instance of our module under test
    Vpulpino_top *tb = new Vpulpino_top;

#ifdef VM_TRACE
    VerilatedVcdC* tfp = NULL;
//    const char* flag = Verilated::commandArgsPlusMatch("trace");
//    if (flag && 0==strcmp(flag, "+trace")) {
        Verilated::traceEverOn(true);  // Verilator must compute traced signals
        VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
        tfp = new VerilatedVcdC;
        tb->trace(tfp, 99);  // Trace 99 levels of hierarchy
        Verilated::mkdir("logs");
        tfp->open("logs/vlt_dump.vcd");  // Open the dump file
//    }
#endif

    tb->rst_n = 0;
    tb->eval();
#ifdef VM_TRACE
      tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    tb->rst_n = 1;
    tb->eval();
#ifdef VM_TRACE
      tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;

    spi_load_hex(tb, tfp, "sw/spi_stim.txt");
    // Tick the clock until we are done
    for (int i =0; i < 100; i++) {
        run_tick_clk(tb, tfp);
    }
#ifdef VM_TRACE
    if (tfp)
        tfp->close();
    if (vcdfile)
        fclose(vcdfile);
#endif

    exit(EXIT_SUCCESS);
}
