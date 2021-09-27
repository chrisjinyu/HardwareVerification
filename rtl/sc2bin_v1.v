///////////////////////////////////////////////////////////////////////////////
// Module name: sc2bin
// Author: Christian Yu
// Affiliation: NanoCAD Laboratory, ECE, UCLA
////////////////////////////////////////////////
//   Stochastic to Binary Conversion Module
//      - split-unipolar inputs
//      - configurable shift
//      - parameterizeable pipelining
////////////////////////////////////////////////
module sc2bin_v1
   (
      clk,
      reset_n,
      clr,
      cnt_en,           //enables counter
      act_en,           //enables subtractor, ReLU, left shift
      sc_pos,           //incoming + stochastic # stream
      sc_neg,           //incoming - stochastic # stream
      shft_amt,         //amount to shift
      bin_out           //output binary value
   );

   parameter BITWIDTH = 8;      //output bitwidth
   parameter MAX_SHFT = 4;      //Maximum supported shift value

   parameter SUBT_REG = 0;      //optional register generation switches
   parameter RELU_REG = 0;
   parameter SHFT_REG = 0;

//INPUTS
   input clk;
   input reset_n;
   input clr;

   input cnt_en;      //counter enable
   input act_en;      //subtractor, ReLU, shift enable

   input [1:0] sc_pos,   //positive stochastic stream
               sc_neg;   //negative stochastic stream

   input [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1:0):0] shft_amt;  //indicated shift amount

//OUTPUTS
   output [BITWIDTH-1:0] bin_out;  //binary result, output of shift

//INTERNAL
   wire [BITWIDTH:0]   pos_out,    //positive SC counter
                       neg_out;    //negative SC counter
   wire [BITWIDTH+1:0] subt_out;   //subtractor value
   wire [BITWIDTH:0]   relu_out;   //ReLU output

   wire cnt_out;
   assign cnt_out = 1'bx;

   cnt_up #(.BITWIDTH(BITWIDTH))   //positive sc counter
   pos_cnt(
      .sc(sc_pos),
      .cnt_en(cnt_en),
      .clk(clk), .reset_n(reset_n), .clr(clr),
      .cnt_out(pos_out));

   cnt_up #(.BITWIDTH(BITWIDTH))   //negative sc counter
   neg_cnt(
      .sc(sc_neg),
      .cnt_en(cnt_en),
      .clk(clk), .reset_n(reset_n), .clr(clr),
      .cnt_out(neg_out));

   subtractor #(.BITWIDTH(BITWIDTH),
                .SUBT_REG(SUBT_REG))   //subtractor
   subt(
      .in_a(pos_out),
      .in_b(neg_out),
      .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .subt_out(subt_out));

   relu #(.BITWIDTH(BITWIDTH),
          .RELU_REG(RELU_REG))   //ReLU
   rect_lin(
      .relu_in(subt_out),
      .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .relu_out(relu_out));


   shft_left #(.BITWIDTH(BITWIDTH),   //shifter
               .MAX_SHFT(MAX_SHFT),
               .SHFT_REG(SHFT_REG))
   shft(
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
module cnt_up
   #(
      parameter BITWIDTH = 8
   )
   (
      input [1:0] sc,
      input cnt_en, clk, reset_n,
      input clr,
      output [BITWIDTH:0] cnt_out
   );

   reg [BITWIDTH:0] cnt_val;
   assign cnt_out = cnt_val;

   always @(posedge clk or negedge reset_n) begin
      if(~reset_n) begin
         cnt_val <= 0;
      end else begin
         if (clr) begin
            cnt_val <= 0;
         end
         else if(cnt_en) begin
            cnt_val <= cnt_val + sc[0] + sc[1];
         end
      end
   end
endmodule

///////////////////////////////////////////////
//   Subtractor module for counters
///////////////////////////////////////////////
module subtractor
   #(
      parameter BITWIDTH = 8,
      parameter SUBT_REG = 0
   )
   (
      input clk, reset_n,
      input [BITWIDTH:0] in_a, in_b,
      input act_en, 
      output [BITWIDTH + 1:0] subt_out
   );
   
   generate
      if(SUBT_REG) begin : gen_subt_reg
         reg[BITWIDTH + 1:0] subt_val;
         always @(posedge clk or negedge reset_n) begin
            if(~reset_n)
               subt_val <= 0;
            else
               subt_val <= (act_en) ? in_a - in_b : 0;
         end
         assign subt_out = subt_val;
      end
      else begin : gen_subt_noreg
         assign subt_out = (act_en) ? in_a - in_b : 0;
      end
   endgenerate
endmodule
