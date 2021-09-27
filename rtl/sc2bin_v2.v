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
module sc2bin_v2
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

   parameter BITWIDTH_INT = 10;      //output bitwidth
   parameter BITWIDTH_OUT = 8;      //output bitwidth
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
   output [BITWIDTH_OUT-1:0] bin_out;  //binary result, output of shift

//INTERNAL
   wire [1:0] subt_out;
   wire subt;
   wire [BITWIDTH_INT-1:0] cnt_out;   //subtractor value
   wire [BITWIDTH_INT-1:0] relu_out;  //ReLU output

   subtractor_v2 #(.BITWIDTH(BITWIDTH_INT),
                .SUBT_REG(SUBT_REG))
   subtractor(
      .in_pos(sc_pos),
      .in_neg(sc_neg),
      .clk(clk), 
      .reset_n(reset_n),
      .cnt_en(cnt_en),
      .subt_out(subt_out),
      .subt(subt));

   cnt_up_v2 #(.BITWIDTH(BITWIDTH_INT))
   cnt_up(
      .sc(subt_out),
      .subt(subt),
      .cnt_en(cnt_en),
      .clk(clk),
      .reset_n(reset_n),
      .clr(clr),
      .cnt_out(cnt_out));

   relu #(.BITWIDTH(BITWIDTH_INT),
          .RELU_REG(RELU_REG))   //ReLU
   rect_lin(
      .relu_in(cnt_out),
      .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .relu_out(relu_out));


   shft_left #(.BITWIDTH_IN(BITWIDTH_INT),   //shifter
               .BITWIDTH_OUT(BITWIDTH_OUT),
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
///////////////////////////////////////////////
module cnt_up_v2
   #(
      parameter BITWIDTH = 8
   )
   (
      input [1:0] sc,
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
module subtractor_v2
   #(
      parameter BITWIDTH = 8,
      parameter SUBT_REG = 0
   )
   (
      input clk, reset_n,
      input [1:0] in_pos, in_neg,
      input cnt_en, 
      output [1:0] subt_out,
      output subt
   );
   
   wire [1:0] pos;
   wire [1:0] neg;

   assign pos = in_pos[0] + in_pos[1];
   assign neg = in_neg[0] + in_neg[1];

   generate
      if(SUBT_REG) begin : gen_subt_reg
         reg[1:0] subt_val;
         always @(posedge clk or negedge reset_n) begin
            if(~reset_n) begin
               subt_val <= 0;
            end
            else begin
               subt_val <= (cnt_en) ? (pos > neg ? pos - neg : neg - pos) : 0;
            end
         end
         assign subt_out = subt_val;
      end // gen_subt_reg
      else begin : gen_subt_noreg
         assign subt_out =  (cnt_en) ? (pos > neg ? pos - neg : neg - pos) : 0;
      end
   endgenerate
   assign subt = neg > pos;
endmodule
