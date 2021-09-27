//	@author christian yu

//////////////////////////////////////////////////////
//	Adder Tree Module
//		N-bit addend binary adder tree
//		Parametrizable number of inputs
//////////////////////////////////////////////////////
module adder_tree
 #(	parameter ADD_LENGTH = 16,
   	parameter SUM_LENGTH = 32,
   	parameter NUM_ADDEND = 15)
  
  (	input [ADD_LENGTH*NUM_ADDEND-1:0] addends,	//Total indices: addend length * number of addends
   	output [SUM_LENGTH-1:0] sum,				//SUM_LENGTH indices
  	input clk, rst);
  
//////////////////////////////////////////////////////
//	Variables
//	Considerations:
//		potential decrementing of indices?
//		use of conditional generates
//////////////////////////////////////////////////////
  parameter stage_cnt  = $clog2(NUM_ADDEND);
  parameter mod_addend = (NUM_ADDEND%2==0) ? NUM_ADDEND : NUM_ADDEND+1; //force even parameter
  
  parameter reg_length = mod_addend*(stage_cnt+1)-1;	//total_sum calculates total sum, added to initial NUM_ADDEND for total pipeline indeces
  genvar i;
  
  reg [SUM_LENGTH - 1:0] reg_pipeline [reg_length:0];	//pipeline, first NUM_ADDEND indeces are loaded directly from input, rest are sums from tree
  
  assign sum = reg_pipeline[reg_length - mod_addend + 1];	//summation of the two
  
//////////////////////////////////////////////////////
//  Generate Loop - Initialize pipeline
//////////////////////////////////////////////////////
  generate
    for (i = 0; i < NUM_ADDEND; i=i+1) begin: init_pipe
      always @(posedge clk) begin
        reg_pipeline[i] <= addends[ADD_LENGTH*(i) +: ADD_LENGTH];
      end
    end
  endgenerate
  
//////////////////////////////////////////////////////
// 	Notes on indexing
//		Indices for each tree level mod mod_addend go from 0 to mod_addend - 1
//		Square indexing
//		Sum every 2 and place at next level
//
//		TODO:
//			- check synthesis
//////////////////////////////////////////////////////
  
  generate
    for(i = 0; i < stage_cnt*mod_addend; i=i+2)
   	begin: all_sums
      always @(posedge clk or posedge rst) begin
        if(rst) begin
          reg_pipeline[i] 	<= 0;
          reg_pipeline[i+1] <= 0;
        end
        else
          reg_pipeline[i + mod_addend - (i%mod_addend)/2] <= reg_pipeline[i] + reg_pipeline[i+1];
      end
    end
  endgenerate
  
endmodule
//////////////////////////////////////////////////////
//	Auxiliary Modules and Functions
//////////////////////////////////////////////////////