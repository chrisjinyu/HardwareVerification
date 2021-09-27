//   @author christian yu
//   testbench for sc2bin module
//   NEEDS CLEANING

module tb_sc2bin;

////////////////////////////////////////////////
//   PARAMETERS   
////////////////////////////////////////////////

// Testcase
   parameter TESTCASE                       = "default";
   parameter TCLK      = 5;
   parameter BITWIDTH   = 8;
   parameter MAX_SHFT   = 4;
   parameter NO_SNG   = 4;
   parameter SEED     = 16;
   parameter RUNS     = 1000;

   parameter READABLE = 0;

////////////////////////////////////////////////
//   INTERMEDIATES
////////////////////////////////////////////////

   reg clk;
   reg cnt_en, act_en;    //remember to use these as wires for cnt module
   reg reset_n;
   reg [$clog2(MAX_SHFT+1)-1:0] shft_amt;
   reg [BITWIDTH-1:0] ref_val;
   real ref_sc_val;
    
   wire [BITWIDTH-1:0] bin_out_v1;
   wire [BITWIDTH-1:0] bin_out_v2;
   wire [NO_SNG-1:0] sc_vals;
    
   reg [NO_SNG*BITWIDTH-1:0] bin_in;
   //wire is_negative;      //flags when subtraction is negative i.e. ReLU
   //real [NO_SNG-1:0] sc_in;     systemverilog

integer                                   resf;
string                                    resf_name = {"./sim_output/tb_sc2bin:",TESTCASE,".res"};
////////////////////////////////////////////////
//  MODULE DECLARATION
////////////////////////////////////////////////

   sng_block #(
      .BITWIDTH(BITWIDTH),
      .NO_SNG(NO_SNG),
      .SEED(SEED))
   sc_gen (
      .clk(clk), .reset_n(reset_n), .en(cnt_en),
      .bin_vals(bin_in),
      .sc_vals(sc_vals)
   );
    
   sc2bin_v1 #(
      .BITWIDTH(BITWIDTH),
      .MAX_SHFT(MAX_SHFT))
   sc2bin_v1 (
      .sc_pos(sc_vals[3:2]), .sc_neg(sc_vals[1:0]),
      .cnt_en(cnt_en), .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .shft_amt(shft_amt),
      .bin_out(bin_out_v1)
   );

   sc2bin_v2 #(
      .BITWIDTH(BITWIDTH),
      .MAX_SHFT(MAX_SHFT))
   sc2bin_v2 (
      .sc_pos(sc_vals[3:2]), .sc_neg(sc_vals[1:0]),
      .cnt_en(cnt_en), .act_en(act_en),
      .clk(clk), .reset_n(reset_n),
      .shft_amt(shft_amt),
      .bin_out(bin_out_v2)
   );

   always
      #TCLK clk = !clk;
    
////////////////////////////////////////////////
//  TESTING STIMULUS
////////////////////////////////////////////////
   integer i, actual_val, diff_1, diff_2, n_diff;
   integer pos1, pos2, neg1, neg2;

   integer seed = SEED;

   // WJR: this won't work if there's a register between them
   //assign is_negative = sc_to_bin.relu_out != sc_to_bin.subt_out;

   initial begin
      //$monitor(i, "%b, %b", sc_to_bin.subt_out, sc_to_bin.relu_out);
      //$dumpfile("sc2bin.vcd");
      //$dumpvars(1,sc_to_bin);

      clk = 0;
      reset_n = 0;
      bin_in = 0;

      //shft_amt = 2;   //CONFIGURE

      #(TCLK * 2)

      $display("\nRuns: %0d", RUNS);
      $display("Max shift: %0d", MAX_SHFT);
      $display("Seed: %0d\n", SEED);
      //$display("Current shift: %0d", shft_amt);

      if(~READABLE)
         $display("\nRUN# \t TIME \t SHFT# \t SC+ \t SC- \t SUBT \t ReLU \t SHFT1 \t SHFT2 \t REF \t DIFF1 \t DIFF2 \t v1_v2_ERR");

      for(i = 0; i < RUNS; i = i+1)
      begin
         if(READABLE & i%50 == 0)
            $display("\nRUN# \t TIME \t\t SHFT#  \t SC+ \t SC- \t SUBT \t ReLU \t SHFT1 \t SHFT2 \t REF \t DIFF1 \t DIFF2 \t v1_v2_ERR");
         #(TCLK * 10)
         reset_n = 1;
         shft_amt = {$random(seed)}%(MAX_SHFT+1);
         bin_in =    $random(seed);   //$random 32bits, need change based on bitwidth
         
         pos1 = bin_in[31:24];
         pos2 = bin_in[23:16];
         neg1 = bin_in[15:8];
         neg2 = bin_in[7:0];

         //$display("%d \t %d \t %d \t %d \t %d \t %d", pos1,pos2,neg1,neg2,pos1+pos2,neg1+neg2);

         actual_val = pos1 + pos2 - neg1 - neg2; #1
         ref_val = (actual_val<0) ? 0 : actual_val;

         //sc_val[i] = actual_val[(i+1)*BITWIDTH-1:i*BITWIDTH]/(2.0**BITWIDTH);
         //actual_sc_val = sc_val[31:24] + sc_val[23:16] - sc_val[15:8] - sc_val[7:0];
         // WJR: what is this?
         //ref_sc_val = ref_val*(2**shft_amt)/(2.0**(BITWIDTH*shft_amt));
 
         cnt_en = 1;
         act_en = 0;

         // WJR: Stream lengths should depend on shift. In practice, we're only using shift when streams are longer
         // This should take care of your overflow issues also. And if we do that, shifter output can be reduced
         // to just "BITWIDTH" and not "BITWIDTH+MAXSHIFT"
         #(2*TCLK * 2**(BITWIDTH-shft_amt))
 
         cnt_en = 0;
         act_en = 1;
 
         #(TCLK * 4)
         //act_en = 0;

         diff_1 = bin_out_v1>ref_val ? bin_out_v1-ref_val : ref_val - bin_out_v1;
         diff_2 = bin_out_v2>ref_val ? bin_out_v2-ref_val : ref_val - bin_out_v2;

         n_diff = bin_out_v1 == bin_out_v2;

         if(READABLE) begin
         if($time > 99999)
            $display("%0d\t %0t \t %d \t %0d \t %0d \t %0d  \t %d \t %d \t %d \t %d \t %0d \t %0d \t %0d",
                  i, 
                  $time , 
                  shft_amt, 
                  pos1 + pos2, 
                  neg1 + neg2, 
                  sc2bin_v1.subt_out, 
                  sc2bin_v1.relu_out, 
                  bin_out_v1, 
                  bin_out_v2,
                  ref_val, 
                  diff_1, 
                  diff_2, 
                  n_diff);
         else
            $display("%0d\t %0t \t \t %d \t %0d \t %0d \t %0d \t %d \t %d \t %d \t %d \t %0d \t %0d \t %0d",
                  i, 
                  $time , 
                  shft_amt, 
                  pos1 + pos2, 
                  neg1 + neg2, 
                  sc2bin_v1.subt_out, 
                  sc2bin_v1.relu_out, 
                  bin_out_v1,
                  bin_out_v2,
                  ref_val, 
                  diff_1, 
                  diff_2, 
                  n_diff);
         end else begin
             $display("%0d\t %0t \t    %0d \t %0d \t %0d \t  %0d \t %0d \t %0d \t %0d \t %0d \t %0d \t %0d \t %0d",
                  i, 
                  $time , 
                  shft_amt, 
                  pos1 + pos2, 
                  neg1 + neg2, 
                  sc2bin_v1.subt_out, 
                  sc2bin_v1.relu_out, 
                  bin_out_v1,
                  bin_out_v2,
                  ref_val, 
                  diff_1, 
                  diff_2, 
                  n_diff);
         end

         /*$display("Subtractor output: %d", sc2bin_v1.subt_out);
         $display("ReLU output: %d", sc2bin_v1.relu_out);
         //$display("ReLU SC: %f, $bitstoreal(sc2bin_v1.relu_out)/(2.0**BITWIDTH));
         $display("Shifted by %d bits: %d", shft_amt, bin_out);
 
         $display("Expected real value: %d", actual_val);
         $display("Expected SC value: %f", actual_sc_val);*/

         //$dumpall;
         #(TCLK * 2)
         reset_n = 0;
      end

      resf = $fopen(resf_name);
      $fwrite(resf,"PASSED");
      $fclose(resf);
      //$dumpflush;
      
      $finish;
   end
endmodule
