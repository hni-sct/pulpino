// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

  logic [31:0]     data_mem[];  // this variable holds the whole memory content
  logic [31:0]     instr_mem[]; // this variable holds the whole memory content
  event            event_mem_load;

  const integer      numWordAddr = 13;
  const integer      numCMAddr = 4;
  const integer      numWord = 8192;
  reg [13:0] w;
  reg [8:0] row;
  reg [3:0] col;

  task mem_preload;
    integer      addr;
    integer      mem_addr;
    integer      bidx;
    integer      instr_size;
    integer      data_size;
    logic [31:0] data;
    string       l2_imem_file;
    string       l2_dmem_file;
    begin
      $display("Preloading memory");

      instr_size   = 32768;
      data_size   = 32768;

      instr_mem = new [instr_size/4];
      data_mem  = new [data_size/4];

      if(!$value$plusargs("l2_imem=%s", l2_imem_file))
         l2_imem_file = "slm_files/l2_stim.slm";

      $display("Preloading instruction memory from %0s", l2_imem_file);
      $readmemh(l2_imem_file, instr_mem);

      if(!$value$plusargs("l2_dmem=%s", l2_dmem_file))
         l2_dmem_file = "slm_files/tcdm_bank0.slm";

      $display("Preloading data memory from %0s", l2_dmem_file);
      $readmemh(l2_dmem_file, data_mem);


      // preload data memory
      for (w = 0; w < numWord; w = w + 1) begin
          {row, col} = w;
          tb_wrap.top_i.top_i.core_region_i.data_mem.sram_ip.MEMORY[row][col] = data_mem[w];
      end
      // preload instruction memory
      for (w = 0; w < numWord; w = w + 1) begin
          {row, col} = w;
          tb_wrap.top_i.top_i.core_region_i.instr_mem.sp_ram_wrap_i.sram_ip.MEMORY[row][col] = instr_mem[w];
      end
    end
  endtask
