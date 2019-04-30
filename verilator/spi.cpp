void run_tick_sclk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->spi_clk_i = 1;
    tb->eval();
    main_time += SCLK_DELAY /2;
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    tb->spi_clk_i = 0;
    tb->eval();
    main_time += SCLK_DELAY /2;
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    main_time++;
}

bool spi_load_hex(Vpulpino_top *top, VerilatedVcdC *tfp, const char *filepath)
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
    top->eval();
    main_time+=10;
#ifdef VM_TRACE
            printf("cs=0 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif

    spi_send_cmd_addr(top, tfp, 0x2, data[0]->addr);
    spi_old_addr = data[0]->addr - 4;
    for (int i=0; i < data.size(); i++) {
        if (data[i]->addr != (spi_old_addr + 4)) {
            printf("[SPI] prev address %x current addr %x\n", spi_old_addr, data[i]->addr);
            printf("[SPI] Loading Data RAM\n");
            top->spi_cs_i = 1;
            top->eval();
            main_time+=10;
#ifdef VM_TRACE
            printf("cs=1 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
            top->spi_cs_i = 0;
            top->eval();
            main_time+=10;
#ifdef VM_TRACE
            printf("cs=0 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
            spi_send_cmd_addr(top, tfp, 0x2, data[i]->addr);
        }
        spi_send_data(top, tfp, data[i]->data);
        spi_old_addr = data[i]->addr;
    }
    fclose(fp);
    top->spi_cs_i = 1;
    top->eval();
    main_time+=10;
#ifdef VM_TRACE
            printf("cs=1 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif

    printf("[SPI] Checking Instruction RAM\n");
    top->spi_cs_i = 0;
    top->eval();
    main_time+=10;
#ifdef VM_TRACE
            printf("cs=0 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    spi_send_cmd_addr(top, tfp, 0xb, data[0]->addr);
    spi_old_addr = data[0]->addr - 4;
    for (int i=33; i >=0; i--) {
        run_tick_sclk(top, tfp);
    }
    for (int i=0; i < data.size(); i++) {
        if (data[i]->addr != (spi_old_addr + 4)) {
            printf("[SPI] prev address %x current addr %x\n", spi_old_addr, data[i]->addr);
            printf("[SPI] Checking Data RAM\n");
            top->spi_cs_i = 1;
            top->eval();
            main_time+=10;
#ifdef VM_TRACE
            printf("cs=1 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
            top->spi_cs_i = 0;
            top->eval();
            main_time+= 10;
#ifdef VM_TRACE
            printf("cs=0 @%d\n", main_time);
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
            spi_send_cmd_addr(top, tfp, 0xb, data[i]->addr);
        }
        uint32_t recv = spi_recv_data(top, tfp);
        if (recv != data[i]->data) {
            printf("[SPI] Readback has failed, expected %x, got %x\n", data[i]->data, recv);
#ifdef VM_TRACE
            tfp->dump(static_cast<vluint64_t>(main_time));
#endif
            return false;
        }
        spi_old_addr = data[i]->addr;
        free(data[i]);
    }
    top->spi_cs_i = 1;
    top->eval();
    main_time+= 10;
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    return true;
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
