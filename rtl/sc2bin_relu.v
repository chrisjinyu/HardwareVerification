//////////////////////////////////////////////
//   Rectified Linear Units
//      - Negative values zero'd out
//////////////////////////////////////////////
module relu
   #(
      parameter BITWIDTH = 8,
      parameter RELU_REG = 0
   )
   (
      input clk, reset_n,
      input [BITWIDTH-1:0] relu_in,
      input act_en, 
      output [BITWIDTH-1:0] relu_out
   );
   

   generate
      if(RELU_REG) begin : gen_relu_reg
         reg [BITWIDTH:0] relu_val;
         always @(posedge clk or negedge reset_n) begin
            if(~reset_n) begin
               relu_val <= 0;
            end
            else begin
               relu_val <= (relu_in[BITWIDTH-1] == 0) & act_en ? relu_in[BITWIDTH-1:0] : 0;
            end
         end
         assign relu_out = relu_val;
      end
      else begin : gen_relu_noreg
         assign relu_out = (relu_in[BITWIDTH-1] == 0) & act_en ? relu_in[BITWIDTH-1:0] : 0;
      end
   endgenerate
endmodule
