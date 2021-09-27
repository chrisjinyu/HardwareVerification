//////////////////////////////////////////////
//   Shift Left
//////////////////////////////////////////////
module shft_left
   #(
      parameter BITWIDTH_IN = 10,
      parameter BITWIDTH_OUT = 8,
      parameter MAX_SHFT = 4,
      parameter SHFT_REG = 0
   )
   (
      input clk, reset_n,
      input [BITWIDTH_IN-1:0] shft_in,
      input [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1:0):0] shft_amt,
      input act_en, 
      output [BITWIDTH_OUT-1:0] shft_out
   );
   wire [BITWIDTH_IN+MAX_SHFT-1:0] shft_int;
   reg [BITWIDTH_OUT-1:0] shft_trunc;

   //generate
   //   if(SHFT_REG) begin : gen_shft_reg
   //      reg [BITWIDTH_IN-1:0] shft_val;
   //      always @(posedge clk or negedge reset_n) begin
   //         if(~reset_n) begin
   //            shft_val <= 0;
   //         end else begin
   //            if(act_en)
   //               shft_val <= shft_in << shft_amt;
   //         end
   //      end
   //      assign shft_int = shft_val;
   //   end
   //   else begin : gen_shft_noreg
   //      assign shft_int = act_en ? shft_in << shft_amt : 0;
   //   end
   //endgenerate

   // Pad on the right
   assign shft_int = {shft_in, {MAX_SHFT{1'b0}}};
   always @(*) begin
      // Shift left
      if (shft_amt < 5) begin
         shft_trunc = shft_int[MAX_SHFT+BITWIDTH_OUT-shft_amt-1 -: BITWIDTH_OUT];
      end
      // Shift right
      else if (shft_amt < 7) begin
         shft_trunc = shft_int[MAX_SHFT+BITWIDTH_OUT+shft_amt-5 -: BITWIDTH_OUT];
      end
      // 7 - no shift
      else begin
         shft_trunc = shft_int[MAX_SHFT+BITWIDTH_OUT-1 -: BITWIDTH_OUT];
      end
   end

   assign shft_out = shft_trunc;

endmodule
