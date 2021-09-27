///////////////////////////////////////////////////////////////
// Module name: sc2bin_array
// Author: Christian Yu, Wojciech Romaszkan
// Description: Array of stochastic to binary converters
// UCLA ECE Department, NanoCAD Laboratory
///////////////////////////////////////////////////////////////

module sc2bin_array(
   clk,
   reset_n,
   clr,
   row_mask,      // I: Masking whole rows
   act_mask,      // I: Masking individual counters
   sc_pos,      //positive stochastic stream
   sc_neg,      //negative stochastic stream
   cnt_en,      //counter enable
   act_en,      //subt,ReLU,shft enable
   reg_push,    //enables clocked register push to output
   shft_amt,    //indicated shift amount
   bin_out
   );

// PARAMETERS

parameter BITWIDTH_INT = 10; //width of individual sc2bin inputs
parameter BITWIDTH_OUT = 8; //width of individual sc2bin inputs
parameter MAX_SHFT = 4; //maximum supported shift

parameter COL = 32;      //ROW x COL array of sc2bin modules
parameter ROW = 3;

parameter SUBT_REG = 0; //optional register generation switches
parameter RELU_REG = 0;
parameter SHFT_REG = 0;

// I/O
input clk,
      reset_n,
      clr;

input [ROW-1:0]       row_mask;
input [COL-1:0]       act_mask;

input [2*ROW*COL-1:0] sc_pos;   //positive stochastic stream
input [2*ROW*COL-1:0] sc_neg;   //negative stochastic stream

input cnt_en;           //counter enable
input act_en;           //subt,ReLU,shft enable

input reg_push;         //enables clocked register push to output

input [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1:0):0] shft_amt;        //indicated shift amount

output [(BITWIDTH_OUT)*COL-1:0] bin_out;           //output at last register

// GENERATES
genvar i;
genvar j;
genvar k;
reg [BITWIDTH_OUT-1:0] sc2bin_reg [ROW-1:0][COL-1:0];       //internal array register values

wire [BITWIDTH_OUT-1:0] sc2bin_out [ROW-1:0][COL-1:0];
// Enable/mask vector
wire sc2bin_cnt_en  [ROW-1:0][COL-1:0];
wire sc2bin_act_en  [ROW-1:0][COL-1:0];

// LOGIC
generate
   for(i = 0; i < ROW; i = i + 1) begin : gen_rows
      for(j = 0; j < COL; j = j + 1) begin : gen_cols
         // Generate enable signals
         assign sc2bin_cnt_en[i][j] = cnt_en & row_mask[i] & act_mask[j];
         assign sc2bin_act_en[i][j] = act_en & row_mask[i] & act_mask[j];
         //wire [BITWIDTH-1:0] sc2bin_out;
         sc2bin_v2 #(.BITWIDTH_INT(BITWIDTH_INT),
                  .BITWIDTH_OUT(BITWIDTH_OUT),
                  .MAX_SHFT(MAX_SHFT),
                  .SUBT_REG(SUBT_REG),
                  .RELU_REG(RELU_REG),
                  .SHFT_REG(SHFT_REG))
         sc2bin  (.clk(clk),
                  .reset_n(reset_n),
                  .clr(clr),
                  .sc_pos(sc_pos[2*(i*COL + j) +: 2]),   //selects every 2 from the stream 
                  .sc_neg(sc_neg[2*(i*COL + j) +: 2]),
                  .cnt_en(sc2bin_cnt_en[i][j]),
                  .act_en(sc2bin_act_en[i][j]),
                  .shft_amt(shft_amt),
                  .bin_out(sc2bin_out[i][j]));
         if ( i == ROW-1) begin : gen_last_row
            always @(posedge clk or negedge reset_n) begin
               if(~reset_n) begin
                  sc2bin_reg[i][j] <= 0;
               end
               else begin
                  sc2bin_reg[i][j] <= sc2bin_out[i][j];
               end 
            end
         end
         else begin : gen_rows
            always @(posedge clk or negedge reset_n) begin
               if(~reset_n) begin
                  sc2bin_reg[i][j] <= 0;
               end
               else begin
                  sc2bin_reg[i][j] <= ~reg_push ? sc2bin_out[i][j] : sc2bin_reg[i+1][j];
               end
            end
         end
      end // gen_cols
   end // gen_rows
endgenerate

//assign bin_out = sc2bin_reg[ROW*(BITWIDTH)*COL-1:(ROW-1)*(BITWIDTH)*COL];
generate
   for (k = 0; k<COL; k = k + 1) begin : flat_out
      assign bin_out[BITWIDTH_OUT*(k+1)-1:BITWIDTH_OUT*k] = sc2bin_reg[0][k];
   end
endgenerate

endmodule
