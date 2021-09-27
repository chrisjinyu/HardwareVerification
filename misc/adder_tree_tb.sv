//	@author christian yu
//`timescale 1ns/1ps
`define TCLK 40
`define NUM_ADD 45
`define SUM_LEN 32
`define ADD_LEN 16


//CLOCK GENERATE
module clkgen(output clk);
  reg clk;
  always begin
    #`TCLK
    clk = ~clk;
  end
  initial
    clk = 1'b0;
endmodule

///////////////////////////////////////////
///////////////////////////////////////////
///////////////////////////////////////////

module adder_tree_tb();

///////////////////////////////////////////
//	variable declarations
///////////////////////////////////////////
  wire clock;
  reg reset;
  
  wire [`SUM_LEN-1:0] sum;
  reg [`ADD_LEN*`NUM_ADD-1:0] inputs;
  
///////////////////////////////////////////
//	Module Declaration
///////////////////////////////////////////
  clkgen clkgen0(clock);		//clk
  
  adder_tree #(					//adder
    .ADD_LENGTH(`ADD_LEN),
    .SUM_LENGTH(`SUM_LEN),
    .NUM_ADDEND(`NUM_ADD))
  adder (
    .addends(inputs),
    .sum(sum),
    .clk(clock), .rst(reset)
  );

///////////////////////////////////////////
//	TESTING STIMULUS
///////////////////////////////////////////
  initial begin
    $display(adder.stage_cnt);
    $display(adder.mod_addend);
    $display(adder.reg_length);
    $displayb(adder.reg_pipeline[0]);
    reset = 1'b1;
    inputs = 0;
    #(`TCLK * 2 * adder.mod_addend)
    reset = 1'b0;
    #(`TCLK * 2 * adder.mod_addend)
    for(int i = 0; i < adder.reg_length; i=i+1)
      begin
      if((i+1)%adder.mod_addend == 0)
        $display(adder.reg_pipeline[i]);
      else
        $write(adder.reg_pipeline[i]);
    end
    $write("\n\n");
    #1
    inputs = {16'b1000000000000001, 
              16'b1000000000000010, 
              16'b1000000000000100,
              16'b1000000000001000,
              16'b1000000000010000,
              16'b1000000000100000,
              16'b1000000001000000,
              16'b1000000010000000,
              16'b1000000100000000,
              16'b1000001000000000,
              16'b1000010000000000,
              16'b1000100000000000,
              16'b1001000000000000,
              16'b1000000000000000,
              16'b1110000000000000,
              16'b1000000000000001, 
              16'b1000000000000010, 
              16'b1000000000000100,
              16'b1000000000001000,
              16'b1000000000010000,
              16'b1000000000100000,
              16'b1000000001000000,
              16'b1000000010000000,
              16'b1000000100000000,
              16'b1000001000000000,
              16'b1000010000000000,
              16'b1000100000000000,
              16'b1001000000000000,
              16'b1000000000000000,
              16'b1110000000000000,
              16'b1000000000000001, 
              16'b1000000000000010, 
              16'b1000000000000100,
              16'b1000000000001000,
              16'b1000000000010000,
              16'b1000000000100000,
              16'b1000000001000000,
              16'b1000000010000000,
              16'b1000000100000000,
              16'b1000001000000000,
              16'b1000010000000000,
              16'b1000100000000000,
              16'b1001000000000000,
              16'b1000000000000000,
              16'b1110000000000000
             };

    //$displayb(inputs);
    #(`TCLK * 2 * adder.mod_addend)
    
    for(int i = 0; i < adder.reg_length; i=i+1)
    begin
      if((i+1)%adder.mod_addend == 0)
        $display(adder.reg_pipeline[i]);
      else
        $write(adder.reg_pipeline[i]);
    end
    
    $write("\n\n");
    $displayb(sum);
    $display(sum);
    $dumpfile("dump.vcd");
    $dumpvars;
    $finish;
  end
endmodule