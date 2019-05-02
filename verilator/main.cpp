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

#define CLK_DELAY 40 // ns
#define SCLK_DELAY 50 // ns
#define JCLK_DELAY 40 // ns

#define VM_TRACE

static vluint64_t main_time = 0;

double sc_time_stamp () {
    return main_time;
}

/*
 * Hacky UART receiver:
 *     it is coupled to 40ns clk period as I don't know yet how to sample
 *     uart_tx asynchronously.
 */

uint32_t last_tx=1;
bool uart_falling_edge(uint32_t tx) {
    if (last_tx == 1 && tx == 0) {
        last_tx = 0;
        return true;
    }
    return false;
}

void uart_rising_edge(uint32_t tx) {
    if (last_tx == 0 && tx == 1) {
        last_tx = 1;
    }
}

bool start_reading = false;
uint32_t uart_bit_idx=0;
int64_t ticks=0;
uint8_t uart_byte=0;

void uart_recv_bit(Vpulpino_top *top)
{
    if (ticks > 3) {
        uart_byte |= (top->uart_tx << uart_bit_idx);
        uart_bit_idx++;
        ticks=0;
    }
}

void uart_print_byte(uint8_t byte) {
    printf("%c", byte);
    start_reading = false;
}

void update_uart(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    if (uart_falling_edge(top->uart_tx)) {
        /* HACK: The start bit is active for 3 clock periods
         * the other bits are active for 2 clock periods.
         */
        ticks = -3;
        uart_byte=0;
        uart_bit_idx = 0;
        start_reading = true;
    }

    if (start_reading) {
        uart_recv_bit(top);
        if (uart_bit_idx > 7) {
            uart_print_byte(uart_byte);
        }
        ticks++;
    } else {
        uart_rising_edge(top->uart_tx);
    }
}

void run_tick_clk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->clk = 1;
    tb->eval();
    main_time += CLK_DELAY /2;
    update_uart(tb, tfp);
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    tb->clk = 0;
    tb->eval();
    main_time += CLK_DELAY /2;
    update_uart(tb, tfp);
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
}

typedef struct {
    uint32_t addr;
    uint32_t data;
} HexData;


void preload_hex(Vpulpino_top *top, VerilatedVcdC *tfp, const char *filepath)
{
    FILE *fp = fopen(filepath, "r");
    char buf[255];
    uint32_t spi_old_addr=0;
    uint32_t mem_start=0;
    std::vector<HexData*> data;

    while (fgets(buf, 255, (FILE*) fp)) {
        char *ptr;
        HexData *elm = (HexData*)malloc(sizeof(HexData));
        ptr = strtok(buf, "_");
        elm->addr = (uint32_t)strtol(ptr, NULL, 16);
        ptr = strtok(NULL, "_");
        elm->data = (uint32_t)strtol(ptr, NULL, 16);
        data.push_back(elm);
    }
    printf("Preloading Instruction RAM\n");
    spi_old_addr = data[0]->addr - 4;
    for (uint64_t i=0; i < data.size(); i++) {
        if (data[i]->addr != (spi_old_addr + 4)) {
            printf("prev address %x current addr %x\n", spi_old_addr, data[i]->addr);
            printf("Preloading Data RAM\n");
            mem_start = i;
        }
        if (mem_start == 0) {
            top->pulpino_top__DOT__core_region_i__DOT__instr_mem__DOT__sp_ram_wrap_i__DOT__sp_ram_i__DOT__mem[i] = data[i]->data;
        } else {
            top->pulpino_top__DOT__core_region_i__DOT__data_mem__DOT__sp_ram_i__DOT__mem[i - mem_start] = data[i]->data;
        }
        spi_old_addr = data[i]->addr;
    }
    fclose(fp);
}

void reset(Vpulpino_top *top, VerilatedVcdC *tfp)
{
    top->testmode_i = 0;
    top->clk_sel_i = 0;
    top->spi_cs_i = 1;
    top->rst_n = 1;
    top->scan_enable_i = 0;
    top->fetch_enable_i = 0;
    top->scl_pad_i = 0;
    top->eval();
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    main_time += 10;
    top->rst_n = 0;
    top->eval();
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif

    for(int i = 0; i < 100; i++) {
        run_tick_clk(top, tfp);
    }
    top->rst_n = 1;
    top->eval();
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
}

int main(int argc, char **argv) {

#ifdef VM_TRACE
    FILE *vcdfile = NULL;
#endif

    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // Create an instance of our module under test
    Vpulpino_top *top = new Vpulpino_top;

#ifdef VM_TRACE
    VerilatedVcdC* tfp = NULL;
    Verilated::traceEverOn(true);  // Verilator must compute traced signals
    VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");  // Open the dump file
#endif

    reset(top, tfp);
    preload_hex(top, tfp, "sw/helloworld.hex");

    /* start fetchin instructions and run the test */
    top->fetch_enable_i = 1;
    do {
        run_tick_clk(top, tfp);
    } while ((top->gpio_out & (1 << 8)) == 0);

#ifdef VM_TRACE
    if (tfp)
        tfp->close();
    if (vcdfile)
        fclose(vcdfile);
#endif

    exit(EXIT_SUCCESS);
}
