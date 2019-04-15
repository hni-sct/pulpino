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

#define JTAG_INSTR_WIDTH 4

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


void run_tick_jtag_clk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->tck_i = 1;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    tb->tck_i = 0;
    tb->eval();
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;
}

void jtag_reset(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->tms_i   = 0;
    top->tck_i   = 0;
    top->trstn_i = 0;
    top->tdi_i   = 0;
    top->eval();
    main_time++;
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    top->trstn_i = 1;
    top->eval();
}

void jtag_softreset(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->tms_i = 1;
    top->trstn_i = 1;
    top->tdi_i = 0;
    for(int i = 0; i < 5; i++) {
        run_tick_jtag_clk(top, tfp);
    }
    top->tms_i = 0;
    run_tick_jtag_clk(top, tfp);
}

void jtag_goto_SHIFT_IR(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->trstn_i = 1;
    top->tdi_i = 0;
    top->tms_i = 1;
    for(int i = 0; i < 2; i++) {
        run_tick_jtag_clk(top, tfp);
    }
    top->tms_i = 0;
    for(int i = 0; i < 2; i++) {
        run_tick_jtag_clk(top, tfp);
    }
}

void jtag_shift_SHIFT_IR(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->trstn_i = 1;
    top->tms_i = 0;
    for (int i = 0; i < JTAG_INSTR_WIDTH; i++) {
        if (i == JTAG_INSTR_WIDTH -1) {
            top->tms_i = 1;
        }
        top->tdi_i = 0;
        run_tick_jtag_clk(top, tfp);
    }
}

void jtag_idle(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->trstn_i = 1;
    top->tms_i = 1;
    top->tdi_i = 0;
    run_tick_jtag_clk(top, tfp);
    top->tms_i = 0;
    run_tick_jtag_clk(top, tfp);
}

void jtag_init(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    jtag_goto_SHIFT_IR(top, tfp);
    jtag_shift_SHIFT_IR(top, tfp);
    jtag_idle(top, tfp);
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

void spi_send_data(Vpulpino_top *top, VerilatedVcdC *tfp, uint32_t data)
{
    for (int i = 31; i >=0; i--) {
        top->spi_sdi0_i = (data & (1 << i)) >> i;
        run_tick_sclk(top, tfp);
    }
}

uint32_t spi_recv_data(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    uint32_t res = 0;
    for (int i = 31; i >=0; i--) {
        res |= top->spi_sdo0_o << i;
        run_tick_sclk(top, tfp);
    }
    return res;
}


void spi_load_hex(Vpulpino_top *top, VerilatedVcdC *tfp, const char *filepath)
{
    FILE *fp = fopen(filepath, "r");
    char buf[255];
    uint32_t spi_old_addr=0;
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
    printf("[SPI] Loading Instruction RAM\n");
    top->spi_cs_i = 0;
    spi_send_cmd_addr(top, tfp, 0x2, data[0]->addr);
    spi_old_addr = data[0]->addr - 4;
    for (int i=0; i < data.size(); i++) {
        if (data[i]->addr != (spi_old_addr + 4)) {
            printf("[SPI] prev address %x current addr %x\n", spi_old_addr, data[i]->addr);
            printf("[SPI] Loading Data RAM\n");
            top->spi_cs_i = 1;
            top->eval();
            main_time++;
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
            top->spi_cs_i = 0;
            top->eval();
            main_time++;
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
            spi_send_cmd_addr(top, tfp, 0x2, data[i]->addr);
        }
        spi_send_data(top, tfp, data[i]->data);
        spi_old_addr = data[i]->addr;
    }
    top->spi_cs_i = 1;
    top->eval();
    main_time++;
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif

    printf("[SPI] Checking Instruction RAM\n");
    top->spi_cs_i = 0;
    spi_send_cmd_addr(top, tfp, 0xb, data[0]->addr);
    spi_old_addr = data[0]->addr - 4;
    for (int i=0; i < data.size(); i++) {
        if (data[i]->addr != (spi_old_addr + 4)) {
            printf("[SPI] prev address %x current addr %x\n", spi_old_addr, data[i]->addr);
            printf("[SPI] Checking Data RAM\n");
            top->spi_cs_i = 1;
            top->eval();
            main_time++;
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
            top->spi_cs_i = 0;
            top->eval();
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
            spi_send_cmd_addr(top, tfp, 0xb, data[i]->addr);
        }
        uint32_t recv = spi_recv_data(top, tfp);
        if (recv != data[i]->data) {
            printf("[SPI] Readback has failed, expected %x, got %x\n", data[i]->data, recv);
            exit(1);
        }
        spi_old_addr = data[i]->addr;
    }
    top->spi_cs_i = 1;
    top->eval();
    main_time++;
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    fclose(fp);
}

void reset(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->testmode_i = 0;
    top->clk_sel_i = 0;
    top->spi_cs_i = 1;
    top->rst_n = 0;
    top->eval();
#ifdef VM_TRACE
      tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    top->rst_n = 1;
    top->eval();
#ifdef VM_TRACE
      tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;

//    jtag_reset(top, tfp);
//    jtag_softreset(top, tfp);
//    jtag_init(top, tfp);

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

    reset(tb, tfp);
    spi_load_hex(tb, tfp, "sw/spi_stim.txt");
    // Tick the clock until we are done
    tb->fetch_enable_i = 1;
    for (int i =0; i < 1; i++) {
        run_tick_clk(tb, tfp);
        if (tb->gpio_out & (1 << 8) != 0) {
            printf("Exit");
            break;
        }
    }
#ifdef VM_TRACE
    if (tfp)
        tfp->close();
    if (vcdfile)
        fclose(vcdfile);
#endif

    exit(EXIT_SUCCESS);
}
