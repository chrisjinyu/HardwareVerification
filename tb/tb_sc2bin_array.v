//  @author christian yu
//

module tb_sc2bin_array;

////////////////////////////////////////////////
//   PARAMETERS   
////////////////////////////////////////////////

parameter TCLK = 5;     //200MHz

parameter BITWIDTH = 8;
parameter MAX_SHFT = 4;

parameter COL = 1;
parameter ROW = 1;

parameter SUBT_REG = 0;
parameter RELU_REG = 0;
parameter SHFT_REG = 0; //disable registers

parameter REPORT_ALL = 0;

parameter SEED = 1;
parameter NO_SNG = 4;   //number of signals each SNG block will be generating

parameter RUNS = 10;

////////////////////////////////////////////////
//   TESTBENCH VARIABLES
////////////////////////////////////////////////

reg clk;
reg reset_n;

reg sng_en;
reg cnt_en;
reg act_en;
reg reg_push;

reg [(MAX_SHFT>0 ? $clog2(MAX_SHFT+1)-1 : 0):0] shft_amt;

reg [ROW*COL*NO_SNG*BITWIDTH-1:0] bin_in;
wire [ROW*COL*NO_SNG*BITWIDTH/2-1:0] pos_bin;
wire [ROW*COL*NO_SNG*BITWIDTH/2-1:0] neg_bin;
wire [ROW*COL*BITWIDTH-1:0] pos1_bin, pos2_bin;
wire [ROW*COL*BITWIDTH-1:0] neg1_bin, neg2_bin;

wire [NO_SNG*ROW*COL - 1:0] sc_vals;

reg [ROW*COL*BITWIDTH-1:0] ref_val;             //reference table

wire [(BITWIDTH)*COL-1:0] bin_out;

reg [ROW*COL*BITWIDTH-1:0] bin_out_table;       //output table


////////////////////////////////////////////////
//  MODULE INSTANTIATION
////////////////////////////////////////////////
genvar i;
genvar j;

assign pos_bin = bin_in[ROW*COL*NO_SNG*BITWIDTH-1:ROW*COL*NO_SNG*BITWIDTH/2];
assign neg_bin = bin_in[ROW*COL*NO_SNG*BITWIDTH/2-1:0];

generate
for(i = 0; i < ROW; i = i+1) begin
   for(j = 0; j < COL; j = j+1) begin
      assign pos1_bin[(BITWIDTH)*(i*COL + j) +: BITWIDTH] = pos_bin[(NO_SNG/2*BITWIDTH)*(i*COL + j) + BITWIDTH - 1:(NO_SNG/2*BITWIDTH)*(i*COL + j)];
      assign pos2_bin[(BITWIDTH)*(i*COL + j) +: BITWIDTH] = pos_bin[(NO_SNG/2*BITWIDTH)*(i*COL + j + 1)-1:(NO_SNG/2*BITWIDTH)*(i*COL + j) + BITWIDTH];
      assign neg1_bin[(BITWIDTH)*(i*COL + j) +: BITWIDTH] = neg_bin[(NO_SNG/2*BITWIDTH)*(i*COL + j) + BITWIDTH - 1:(NO_SNG/2*BITWIDTH)*(i*COL + j)];
      assign neg2_bin[(BITWIDTH)*(i*COL + j) +: BITWIDTH] = neg_bin[(NO_SNG/2*BITWIDTH)*(i*COL + j + 1)-1:(NO_SNG/2*BITWIDTH)*(i*COL + j) + BITWIDTH];
   end
end
endgenerate

//sng_block #(                          //DO NOT USE, causes last sc2bin module to fail
//   .BITWIDTH(BITWIDTH),
//   .NO_SNG(NO_SNG*ROW*COL),
//   .SEED(SEED))
//sc_gen (
//   .clk(clk), .reset_n(reset_n),
//   .en(sng_en),
//   .bin_vals(bin_in),
//   .sc_vals(sc_vals)
//);

generate
for(i = 0; i < ROW; i = i+1) begin
   for(j = 0; j < COL; j = j+1) begin
      sc_sng_block #(
         .BITWIDTH(BITWIDTH),
         .NO_SNG(NO_SNG),
         .SEED(SEED))
      sc_gen(
         .clk(clk), .reset_n(reset_n),
         .sng_en(sng_en),
         .bin_vals(bin_in[(NO_SNG*BITWIDTH)*(i*COL + j) +: NO_SNG*BITWIDTH]),
         .sc_vals(sc_vals[(NO_SNG)*(i*COL + j) +: NO_SNG])
      );
   end
end
endgenerate

sc2bin_array #(
   .BITWIDTH(BITWIDTH),
   .MAX_SHFT(MAX_SHFT),
   .COL(COL), .ROW(ROW),
   .SUBT_REG(SUBT_REG),
   .RELU_REG(RELU_REG),
   .SHFT_REG(SHFT_REG))
sc2bin_array (
   .clk(clk), .reset_n(reset_n),
   .sc_pos(sc_vals[NO_SNG*ROW*COL-1:NO_SNG*ROW*COL/2]),         //first half +, second half -
   .sc_neg(sc_vals[NO_SNG*ROW*COL/2 - 1:0]),
   .cnt_en(cnt_en),
   .act_en(act_en),
   .reg_push(reg_push),
   .shft_amt(shft_amt),
   .bin_out(bin_out)
);

always begin
#TCLK clk = !clk;
end

////////////////////////////////////////////////
//  TESTING STIMULUS
////////////////////////////////////////////////

integer seed = SEED;
integer k, z, l;
integer int_ref_val [ROW*COL-1:0];
integer error;

//always @(negedge reset_n) begin
//   if(~reset_n) begin
//      for(k = 0; k < ROW*COL*NO_SNG*BITWIDTH; k = k+1)
//         bin_in[k] = 0;
//      for(k = 0; k < ROW*COL*BITWIDTH; k = k+1)
//         ref_val[k] = 0;
//      for(k = 0; k < ROW*COL*BITWIDTH; k = k+1)
//         bin_out_table[k] = 0;
//   end
//end

initial begin
   clk = 0;
   reset_n = 0;
   bin_in = 0;
   reg_push = 0;
   cnt_en = 0;
   act_en = 0;
   sng_en = 0;

   #1

   for(l = 0; l < RUNS; l = l+1) begin
      #(TCLK*4)
      for(k = 0; k < ROW*COL; k = k+1) begin                     //generate random binary inputs
         #1
         bin_in = bin_in << NO_SNG*BITWIDTH;
         bin_in[NO_SNG*BITWIDTH-1:0] = $random(seed);
      end

      shft_amt = {$random(seed)}%(MAX_SHFT+1);

      //shft_amt = 0;

      for(k = 0; k < ROW*COL; k = k+1) begin
         #1
         int_ref_val[k] = pos1_bin[(BITWIDTH)*k +:BITWIDTH] + pos2_bin[(BITWIDTH)*k +:BITWIDTH] - neg1_bin[(BITWIDTH)*k +:BITWIDTH] - neg2_bin[(BITWIDTH)*k +:BITWIDTH];
         ref_val[(BITWIDTH)*k +:BITWIDTH] = int_ref_val[k] < 0 ? 0 : int_ref_val[k];
      end
      
      //reset_n = 1;
      sng_en = 1;

      #(TCLK*ROW*COL)
      
      reset_n = 1;
      cnt_en = 1;
      act_en = 0;

      #(2*TCLK * 2**(BITWIDTH - shft_amt))

      cnt_en = 0;
      act_en = 1;
      sng_en = 0;

      #(TCLK * 4)
      $display("\n\nRUN #: %d",l);
      $display("Shift Amount: %d", shft_amt);
      $display("\nPushed final decimal register values in order (Bottom to top):");
      //act_en = 0;
      //$monitor("%b",bin_out);
      k = 0;
      z = 0;
      reg_push = 1;
      #(2*TCLK*ROW)
      
      reg_push = 0;
      act_en = 0;
      #(2*TCLK*ROW)
      reset_n = 0;
      k = 0;
      z = 0;

      //for(k = 0; k < ROW; k = k+1) begin                 //display table results
      //   $write("\t\t");
      //   for(z = 0; z < COL; z = z+1) begin
      //      $write("%0d\t",bin_out_table[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
      //   end
      //   $display("");
      //end


      $display("Corresponding decimal reference values:");
      for(k = 0; k < ROW; k = k+1) begin
         $write("\t\t");
         for(z = 0; z < COL; z = z+1) begin
            $write("%d\t",ref_val[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
         end
         $display("");
      end

      $display("Absolute error between decimal and reference values:");
      for(k = 0; k < ROW; k = k+1) begin
         $write("\t\t");
         for(z = 0; z < COL; z = z+1) begin
            error = bin_out_table[(BITWIDTH)*(k*COL+z) +: BITWIDTH] - ref_val[(BITWIDTH)*(k*COL+z) +: BITWIDTH];
            $write("%0d\t",error);
         end
         $display("");
      end


      if(REPORT_ALL) begin
         $display("\n\nCorresponding positive decimal value, 1st stream");
         for(k = ROW-1; k > -1; k = k-1) begin
            $write("\t\t");
            for(z = 0; z < COL; z = z+1) begin
               $write("%d\t",pos1_bin[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
            end
            $display("");
         end
         
         $display("Corresponding positive decimal value, 2nd stream");
         for(k = ROW-1; k > -1; k = k-1) begin
            $write("\t\t");
            for(z = 0; z < COL; z = z+1) begin
               $write("%d\t",pos2_bin[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
            end
            $display("");
         end

         $display("Corresponding negative decimal value, 1st stream");
         for(k = ROW-1; k > -1; k = k-1) begin
            $write("\t\t");
            for(z = 0; z < COL; z = z+1) begin
               $write("%d\t",neg1_bin[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
            end
            $display("");
         end
         
         $display("Corresponding negative decimal value, 2nd stream");
         for(k = ROW-1; k > -1; k = k-1) begin
            $write("\t\t");
            for(z = 0; z < COL; z = z+1) begin
               $write("%d\t",neg2_bin[(BITWIDTH)*(k*COL+z) +: BITWIDTH]);
            end
            $display("");
         end

         $display("Corresponding integer subtraction values");
         for(k = ROW-1; k > -1; k = k-1) begin
            $write("\t\t");
            for(z = 0; z < COL; z = z+1) begin
               $write("%0d\t",int_ref_val[k*COL + z]);
            end
            $display("");
         end
      end
      //reset_n = 1;
   end

   $finish;
end

always @(posedge clk) begin: bin_out_read             //bin_out read block
   if(reg_push) begin
      $write("TIME: %0t\t", $time);
      for(z = 0; z < COL; z = z+1) begin
         $write("%d\t", bin_out[(BITWIDTH)*z +: BITWIDTH]);          //display each cycle
         bin_out_table[(BITWIDTH)*(k*COL + z) +: BITWIDTH] = bin_out[(BITWIDTH)*z +: BITWIDTH];
      end
      k = k+1;
      $display("");
   end
end

endmodule
