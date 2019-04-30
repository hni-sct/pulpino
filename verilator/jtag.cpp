void run_tick_jtag_clk(Vpulpino_top *tb, VerilatedVcdC *tfp)
{
    tb->tck_i = 1;
    tb->eval();
    main_time += JCLK_DELAY /2;
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
#endif
    tb->tck_i = 0;
    tb->eval();
    main_time += JCLK_DELAY /2;
#ifdef VM_TRACE
    tfp->dump(static_cast<vluint64_t>(main_time));
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
    main_time+=500;
#ifdef VM_TRACE
  tfp->dump(static_cast<vluint64_t>(main_time));
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

