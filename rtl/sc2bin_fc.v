///////////////////////////////////////////////////////////////////////////////
// Module name : sc2bin_fc 
// Created     : 07/29/2019
// Author      : Wojciech Romaszkan, Christian Yu
// Affiliation : NanoCAD Laboratory, ECE Department, UCLA
// Description : Stochastic to binary conversion module for FC layers
//               
///////////////////////////////////////////////////////////////////////////////

module sc2bin_fc (
   clk,              // I: Clock
   reset_n,          // I: Async reset
   clr,              // I: Counter clear
   cnt_en,           // I: Enables counter
   act_en,           // I: Enables subtractor, ReLU, left shift
   sc_pos,           // I: Incoming + stochastic # stream
   sc_neg,           // I: Incoming - stochastic # stream
   shft_amt,         // I: Amount to shift
   bin_out           // O: Output binary value
);

////////////////////////////////////////
// Params
// Output bitwidth
parameter BITWIDTH_INT = 10;      //output bitwidth
parameter BITWIDTH_OUT = 8;      //output bitwidth
// Maximum supported shift value
parameter            MAX_SHFT = 4;
// Optional register generation switches
parameter            SUBT_REG = 0;
parameter            RELU_REG = 0;
parameter            SHFT_REG = 0;

////////////////////////////////////////
// Inputs
input                clk;
input                reset_n;
input                clr;
// Counter enable
input                cnt_en;
// Subtractor, ReLU, shift enable
input                act_en;
// Positive stochastic stream
input                sc_pos;
// Negative stochastic stream
input                sc_neg;
// Indicated shift amount
input [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1:0):0] shft_amt;  

////////////////////////////////////////
// Outputs
// Binary result, output of shift
output [BITWIDTH_OUT-1:0] bin_out;

////////////////////////////////////////
// Wires/registers
wire                 subt_out;
wire                 subt;
wire [BITWIDTH_INT-1:0]  cnt_out;   //subtractor value
wire [BITWIDTH_INT-1:0]    relu_out;   //ReLU output

   subtractor_fc 
   subtractor_fc (
      .in_pos(sc_pos),
      .in_neg(sc_neg),
      .clk(clk), .reset_n(reset_n),
      .cnt_en(cnt_en),
      .subt_out(subt_out),
      .subt(subt));

   cnt_up_fc #(.BITWIDTH(BITWIDTH_INT))
   cnt_up_fc(
      .sc(subt_out),
      .subt(subt),
      .cnt_en(cnt_en),
      .clk(clk),
      .reset_n(reset_n),
      .clr(clr),
      .cnt_out(cnt_out));

   relu #(.BITWIDTH(BITWIDTH_INT),
          .RELU_REG(RELU_REG))   //ReLU
   rect_lin_fc (
      .relu_in(cnt_out),
      .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .relu_out(relu_out));


   shft_left #(.BITWIDTH_IN(BITWIDTH_INT),   //shifter
               .BITWIDTH_OUT(BITWIDTH_OUT),
               .MAX_SHFT(MAX_SHFT),
               .SHFT_REG(SHFT_REG))
   shft_fc(
      .shft_in(relu_out),
      .shft_amt(shft_amt),
      .act_en(act_en), .clk(clk), .reset_n(reset_n),
      .shft_out(bin_out));
endmodule

///////////////////////////////////////////////
//   Counter
//      +0 00
//      +1 01
//      +1 10
//      +2 11
///////////////////////////////////////////////
module cnt_up_fc
   #(
      parameter BITWIDTH = 8
   )
   (
      input       sc,
      input subt,
      input cnt_en, clk, reset_n,
      input clr,
      output [BITWIDTH-1:0] cnt_out
   );

   reg [BITWIDTH-1:0] cnt_val;
   assign cnt_out = cnt_val;

   always @(posedge clk or negedge reset_n) begin
      if(~reset_n) begin
         cnt_val <= 0;
      end 
      else begin
         if (clr) begin
            cnt_val <= 0;
         end
         else if(cnt_en) begin
            cnt_val <= subt ? (cnt_val - sc) : (cnt_val + sc);
         end
      end
   end
endmodule

///////////////////////////////////////////////
//   Subtractor module for counters
///////////////////////////////////////////////
module subtractor_fc
   (
      input clk, reset_n,
      input       in_pos, in_neg,
      input cnt_en, 
      output       subt_out,
      output subt
   );
   
   assign subt_out = in_pos ^ in_neg;
   assign subt = in_neg ;
endmodule

