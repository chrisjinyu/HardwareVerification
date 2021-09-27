///////////////////////////////////////////////////////////////////////////////
// Module name : sc2bin_array_fc
// Created     : 07/31/2019   
// Author      : Wojciech Romaszkan
// Affiliation : NanoCAD Laboratory, ECE Department, UCLA
// Description : Stochastic to binary conversion for FC layers, with pseudo 
//               SIPO output.
//               
///////////////////////////////////////////////////////////////////////////////

module sc2bin_array_fc (
       clk,                   // I: Clock
       reset_n,               // I: Async reset
       clr,                   // I: Counter clear
       cnt_en,                // I: Counter enable
       act_en,                // I: Activation enable
       reg_push,              // I: Output buffer push
       sc_in_pos,             // I: Positive SC streams
       sc_in_neg,             // I: Negative SC streams
       shft_amt,              // I: Shift amount
       bin_out                // I: Output activation vector
);

////////////////////////////////////////
// Params
// Activation bitwidth
parameter BITWIDTH_INT = 10; //width of individual sc2bin inputs
parameter BITWIDTH_OUT = 8; //width of individual sc2bin inputs
// Maximum shift value
parameter                     MAX_SHFT = 4;
// Register stages
parameter                     SUBT_REG = 0;
parameter                     RELU_REG = 0;
parameter                     SHFT_REG = 0;
// Rows per kernel
parameter                     ROWS_P_KERN = 3;
// Number of outputs computed 
parameter                     NO_OUT = 2;
// Number of parallel outputs
parameter                     NO_OUT_PAR = 32;

////////////////////////////////////////
// Inputs
// Clock
input                         clk;
// Async reset
input                         reset_n;
// Counter/buffer clear
input                         clr;
// Counter enable
input                         cnt_en;
// Activation enable
input                         act_en;
// Output register push
input                         reg_push;
// Positive/negative streams
input    [NO_OUT*ROWS_P_KERN-1:0] sc_in_pos;
input    [NO_OUT*ROWS_P_KERN-1:0] sc_in_neg;
// Output shift amount
input [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1:0):0] shft_amt;

////////////////////////////////////////
// Outputs
// Binary output vector
output   [NO_OUT_PAR*BITWIDTH_OUT-1:0] bin_out;

////////////////////////////////////////
// Wires/registers
// Remapped for fc layers
wire                          sc_out_pos_fc_red [NO_OUT-1:0];
wire                          sc_out_neg_fc_red [NO_OUT-1:0];
// FC Layer outputs ("serial")
wire    [NO_OUT*BITWIDTH_OUT-1:0] fc_bin_out;

////////////////////////////////////////
// Modules 

///////////////////
// FC layer reduction across rows 
generate 
   genvar r;
   for (r = 0; r < NO_OUT; r = r + 1) begin : gen_fc_act
      sc_out_mapper_fc #(
         .IN_WIDTH(ROWS_P_KERN))  sc_out_mapper_fc (
         .sc_in_pos(sc_in_pos[r*ROWS_P_KERN +: ROWS_P_KERN]),
         .sc_in_neg(sc_in_neg[r*ROWS_P_KERN +: ROWS_P_KERN]),
         .sc_out_pos(sc_out_pos_fc_red[r]),
         .sc_out_neg(sc_out_neg_fc_red[r])
      );
      sc2bin_fc #(
         .BITWIDTH_INT(BITWIDTH_INT),
         .BITWIDTH_OUT(BITWIDTH_OUT),
         .MAX_SHFT(MAX_SHFT),
         .SUBT_REG(SUBT_REG),
         .RELU_REG(RELU_REG),
         .SHFT_REG(SHFT_REG)) sc2bin_fc (
         .clk(clk),
         .reset_n(reset_n),
         .clr(clr),
         .cnt_en(cnt_en),
         .act_en(act_en),
         .sc_pos(sc_out_pos_fc_red[r]),
         .sc_neg(sc_out_neg_fc_red[r]),
         .shft_amt(shft_amt),
         .bin_out(fc_bin_out[r*BITWIDTH_OUT +: BITWIDTH_OUT])
      );
   end
endgenerate

///////////////////
// Output SIPO buffer
sc_fc_out_buffer #(
   .BITWIDTH(BITWIDTH_OUT),
   .NO_ACT_IN(NO_OUT),
   .NO_ACT_OUT(NO_OUT_PAR)) sc_fc_out_buffer (
   .clk(clk),
   .reset_n(reset_n),
   .en(reg_push),
   .act_in(fc_bin_out),
   .clr(clr),
   .act_out(bin_out)
);

////////////////////////////////////////
// Logic

endmodule // modulename
