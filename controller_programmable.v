`include "./config.h"
module controller_programmable #(
//-------------------Instruction Parameters
   parameter NUM_INSTRUCTION=`NUM_INSTRUCTION_CONFIG, //ischanged next line should change
   parameter PC_WIDTH=`PC_WIDTH_CONFIG,         //$ceil($clog2(NUM_INSTRUCTION)),
   parameter OPERATION_WIDTH=`OPERATION_WIDTH_CONFIG,  //for ALU with two operations
   parameter SRC_WIDTH=3,
   parameter SHIFT_CONDITION_WIDTH=3,// if changed, need change in constant defention, look for SHIFT_CONDITION_WIDTHi
   parameter PC_NEXT_CONDITION_WIDTH=3, 
   parameter NUM_OF_COL_IN_ROW=64,
   parameter NUM_ROW_IN_SUBARRAY=1024,
   parameter NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD=9,
    
   parameter WAIT_CYCLE_WIDTH=4,   //$ceil($clog2(NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD)),
   parameter COL_COUNTER_WIDTH=6,  //$ceil($clog2(NUM_OF_COL_IN_ROW)),
   parameter ROW_ADR_WIDTH=10,     //$ceil($clog2(NUM_ROW_IN_SUBARRAY)),
   
   parameter COMMAND_WIDTH=4, 
   parameter GOLOBAL_DATA_BUS_WIDTH=`GOLOBAL_DATA_BUS_WIDTH_CONFIG,
   parameter REG_TRANS_SRC_WIDTH=`REG_TRANS_SRC_WIDTH_CONFIG,
   parameter REG_TRANS_DST_WIDTH=`REG_TRANS_DST_WIDTH_CONFIG,
//--------------------------COMMAND ENCODNG
   parameter COMMAND_CODE_RECORD_ROW1_ADR_START=4'b0000,
   parameter COMMAND_CODE_RECORD_ROW2_ADR_START=4'b0001,
   parameter COMMAND_CODE_RECORD_ROW3_ADR_START=4'b0010,
   parameter COMMAND_CODE_RECORD_ROW1_ADR_END=4'b0011,
   parameter COMMAND_CODE_RECORD_ROW2_ADR_END=4'b0100,
   parameter COMMAND_CODE_RECORD_ROW3_ADR_END=4'b0101,
   parameter COMMAND_CODE_RECORD_REG_TEMP_A=4'b0110,
   parameter COMMAND_CODE_RECORD_REG_TEMP_B=4'b0111,
   parameter COMMAND_CODE_RECORD_REG_TEMP_C=4'b1000,
   parameter COMMAND_CODE_LOAD_INSTRUCTION_BUFFER=4'b1001,
   parameter COMMAND_CODE_SET_STEP=4'b1010,   // added for SUPER_FIMD 

   
   
//------------------------STEP ENCODING for SuperFIM
   parameter STEP_LENGTH=3, //if you change this you need to change the folloing as well
   parameter STEP_CODE_INVALID=3'b000,
   parameter STEP_CODE_OFFSET_LENGTH_VALUE_PACKING=3'b001, 
   parameter STEP_CODE_COLUMN_PROCESSSING=3'b010,
   parameter STEP_CODE_DISPATCHING=3'b011,
   parameter STEP_CODE_RECIEVED_PROCESSING=3'b100,
   parameter STEP_CODE_APPLYING=3'b101,
   parameter STEP_CODE_ROADCASTING=3'b110,

//-----------------TODO: configurabke indirect access masking,  could become configurable using temp registers
  
   parameter INDIRECT_ACCESS_MASK_WIDTH= GOLOBAL_DATA_BUS_WIDTH-ROW_ADR_WIDTH,
   parameter INDIRECT_ACCESS_MASK={{ROW_ADR_WIDTH{1'b1}},{INDIRECT_ACCESS_MASK_WIDTH{1'b0}}},

 
//------Start locations-------------

   parameter PC_NEXT1_START=0,                          
   parameter PC_NEXT1_END=PC_NEXT1_START+PC_WIDTH-1,	//2

   parameter PC_NEXT2_START=PC_NEXT1_END,               
   parameter PC_NEXT2_END=PC_NEXT2_START+PC_WIDTH-1,	//4


   parameter OPCODE1_START=PC_NEXT1_END+1,              
   parameter OPCODE1_END=OPCODE1_START+OPERATION_WIDTH-1, //8

   parameter OPCODE2_START=OPCODE1_END+1,              
   parameter OPCODE2_END=OPCODE2_START+OPERATION_WIDTH-1, //12

   parameter SRC1_OP1_START=OPCODE2_END+1,             
   parameter SRC1_OP1_END=SRC1_OP1_START+SRC_WIDTH-1, //15

   parameter SRC2_OP1_START=SRC1_OP1_END+1,	          
   parameter SRC2_OP1_END=SRC2_OP1_START+SRC_WIDTH-1, //18

   parameter SRC1_OP2_START=SRC2_OP1_END+1,	          
   parameter SRC1_OP2_END=SRC1_OP2_START+SRC_WIDTH-1, //21

   parameter SRC2_OP2_START=SRC1_OP2_END+1,	         
   parameter SRC2_OP2_END=SRC2_OP2_START+SRC_WIDTH-1, //24

   parameter SHIFT_COND1_START=SRC2_OP2_END+1,      
   parameter SHIFT_COND1_END=SHIFT_COND1_START+SHIFT_CONDITION_WIDTH-1, //27

   parameter SHIFT_COND2_START=SHIFT_COND1_END+1,    
   parameter SHIFT_COND2_END=SHIFT_COND2_START+SHIFT_CONDITION_WIDTH-1, //30

   parameter SHIFT_COND3_START=SHIFT_COND2_END+1,   
   parameter SHIFT_COND3_END=SHIFT_COND3_START+SHIFT_CONDITION_WIDTH-1, //33

   parameter SHIFT_DIR1_START=SHIFT_COND3_END+1,   
   parameter SHIFT_DIR1_END=SHIFT_DIR1_START+1-1, //34

   parameter SHIFT_DIR2_START=SHIFT_DIR1_END+1,     
   parameter SHIFT_DIR2_END=SHIFT_DIR2_START+1-1, //35

   parameter SHIFT_DIR3_START=SHIFT_DIR2_END+1,	   
   parameter SHIFT_DIR3_END=SHIFT_DIR3_START+1-1, //36
  

   parameter REG_TRANS_SRC_START=SHIFT_DIR3_END+1,		    
   parameter REG_TRANS_SRC_END=REG_TRANS_SRC_START+REG_TRANS_SRC_WIDTH-1, //39
  
   parameter REG_TRANS_DST_START=REG_TRANS_SRC_END+1,		    
   parameter REG_TRANS_DST_END=REG_TRANS_DST_START+REG_TRANS_DST_WIDTH-1, //41
   
   //TODO: add INDIRECT ACCESS SRC and DSTss
   
   
`ifdef SUPPORT_REPEAT_CONFIG 

   parameter NUMBER_OF_REPEAT_START=REG_TRANS_DST_END+1,	 
   //-LPGG
   parameter NUMBER_OF_REPEAT_END=NUMBER_OF_REPEAT_START+COL_COUNTER_WIDTH-1, //44
`else
   //-LPGG
   parameter NUMBER_OF_REPEAT_END=REG_TRANS_DST_END, 

`endif

   parameter PC_NEXT_CONDITION_START=NUMBER_OF_REPEAT_END+1, 
   parameter PC_NEXT_CONDITION_END=PC_NEXT_CONDITION_START+PC_NEXT_CONDITION_WIDTH-1,
   
   //parameter INSTRUCTION_LENGTH= ROW_ADR_WIDTH+GOLOBAL_DATA_BUS_WIDTH,
   parameter INSTRUCTION_LENGTH= PC_NEXT_CONDITION_END+1,

//-------------------STATE PARAMETER
   parameter STATE_SIZE = 2,
//------STATE ENCODING/
   parameter STATE_COMPUTE    = 2'd0, 
   parameter STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1 = 2'd1, 
   parameter STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2 = 2'd2,
   parameter STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3 = 2'd3,  
 //-------------------SHIFT CONDITION ENCODING, SHIFT_CONDITION_WIDTH
   parameter NEVER_SHIFT=3'd0,
   parameter ALWAYS_SHIFT=3'd1,
   parameter IF_EQUAL_SHIFT=3'd2,
   parameter IF_NOT_EQUAL_SHIFT=3'd3,
   parameter IF_LESS_SHIFT=3'd4,
   parameter IF_GREAT_SHIFT=3'd5,
//-----------------PC_NEXT_CONDITION_ ENCODING
   parameter ALWAYS_NEXT=3'd0,
   parameter IF_EQUAL_NEXT=3'd1,
   parameter IF_LESS_NEXT=3'd2,
   parameter IF_GREAT_NEXT=3'd3,
   parameter IF_ROW_ENDS_NEXT=3'd4, 
   //-------------Extra parameters to be removed ----------------------
   parameter addedToKeepCommaLess=0
)(
   //-------------Input Ports-----------------------------
   input logic clk,           // clock
   input logic reset,         // Active high, syn reset
   input logic start,
   input logic valid_command, // Request 0
   input logic [ ROW_ADR_WIDTH-1:0] row_addr,
   input logic [ COMMAND_WIDTH-1:0] command,
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] global_data_bus,
   input logic adder_equal_flag,
   input logic adder_less_flag,
    //two input port added for SuperFIMD
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] walker1Out,
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] walker2Out,
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] walker3Out,
   input logic sub_clk,
  
   //-------------Output Ports----------------------------
   output logic  shift1,
   output logic  shift2,
   output logic  shift3,
   output logic  shiftDir1_read_or_write,
   output logic  shiftDir2_read_or_write,
   output logic  shiftDir3_read_or_write,
   output logic [OPERATION_WIDTH-1:0] opCode1,
   output logic [OPERATION_WIDTH-1:0] opCode2,
   output logic [SRC_WIDTH-1:0] src1Op1,
   output logic [SRC_WIDTH-1:0] src2Op1,
   output logic [SRC_WIDTH-1:0] src1Op2,
   output logic [SRC_WIDTH-1:0] src2Op2,
   output logic read_or_write,
   output logic row1_active,
   output logic row2_active,
   output logic row3_active,
   output logic load_temp_regA,
   output logic load_temp_regB,
   output logic load_temp_regC,
   output logic [PC_WIDTH-1:0] pc,
   output logic [`REG_TRANS_SRC_WIDTH_CONFIG-1:0] regTransferSrc,
   output logic [`REG_TRANS_DST_WIDTH_CONFIG-1:0] regTransferDst,
   // output ports added for SuperFIMD
   output logic endOfStep, //TODO: put value for this
   //output logic [1:0] numSubClockShiftWalker1,
   //output logic [1:0] numSubClockShiftWalker2,	
   //output logic [1:0] numSubClockShisftWalker3,
   //output logic  sub_shift1,
   output logic  sub_shift2,
   output logic  sub_shift3
   
   //output logic  sub_shiftDir1,
   //output logic  sub_shiftDir2,
   //output logic  sub_shiftDir3
   );

//-- Internal counters
   //--col counters
   logic [COL_COUNTER_WIDTH-1:0] colCounter1;
   logic [COL_COUNTER_WIDTH-1:0] colCounter2;
   logic [COL_COUNTER_WIDTH-1:0] colCounter3;
   logic [COL_COUNTER_WIDTH-1:0] nxtColCounter1;
   logic [COL_COUNTER_WIDTH-1:0] nxtColCounter2;
   logic [COL_COUNTER_WIDTH-1:0] nxtColCounter3;
   logic [COL_COUNTER_WIDTH-1:0] instructionRepeatCounter;
   //--row counters
   logic [ ROW_ADR_WIDTH-1:0] row1_counter;
   logic [ ROW_ADR_WIDTH-1:0] row2_counter;
   logic [ ROW_ADR_WIDTH-1:0] row3_counter;
   //--wait counter
   logic [WAIT_CYCLE_WIDTH-1:0] wait_counter;

   logic [ ROW_ADR_WIDTH-1:0] row1_start;
   logic [ ROW_ADR_WIDTH-1:0] row1_end;
   logic [ ROW_ADR_WIDTH-1:0] row2_start;
   logic [ ROW_ADR_WIDTH-1:0] row2_end;
   logic [ ROW_ADR_WIDTH-1:0] row3_start;
   logic [ ROW_ADR_WIDTH-1:0] row3_end;
  
   //logic [ROW_ADR_WIDTH-1:0 ] indirectAccessRegWalker1; //not used 
   logic [ROW_ADR_WIDTH-1:0 ] indirectRowAddressRegWalker2; //TODO: assign value to it
   logic [ROW_ADR_WIDTH-1:0 ] indirectRowAddressRegWalker3; //TODO: sassign value to it
   logic [COL_COUNTER_WIDTH-1:0]  indirectColAddressWalker2;
   logic [COL_COUNTER_WIDTH-1:0] indirectColAddressWalker3;
   logic [1:0] Mode3Calculator; //we need mode three calculator for  the cases that value, column offset and its length are packed

//-------------Internal Variables---------------------------
  logic [STATE_SIZE-1:0]  state        ;// Seq part of the FSM
  logic [STATE_SIZE-1:0]  next_state   ;// combo part of FSM
  logic [0:0] endOfProcess; ///apaarently not used , check if needs to be deleted

  logic [INSTRUCTION_LENGTH-1:0] instructionBuffer [NUM_INSTRUCTION-1:0];
  logic [INSTRUCTION_LENGTH-1:0] instructionCurr ;
//--------------
  logic [STEP_LENGTH-1:0] stepRegister; // representing steps in SuperFIMD

//--Signals Mapped From Pre-generated signals

  logic [PC_WIDTH-1:0] pc_next1;
  logic [PC_WIDTH-1:0] pc_next2;
  logic [PC_WIDTH-1:0] actual_pc_next;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond1;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond2;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond3;
  logic [0:0] shiftDir1;
  logic [0:0] shsiftDir2;
  logic [0:0] shiftDir3;
  //logic [REG_TRANS_SRC_WIDTH-1:0] regTransferSrc;
  logic [COL_COUNTER_WIDTH-1:0] number_of_repeat;
  logic [PC_NEXT_CONDITION_WIDTH-1:0] pc_next_condition;
  //--------------------
  


assign pc_next1 =instructionCurr[PC_NEXT1_END:PC_NEXT1_START]; 
assign pc_next2 =instructionCurr[PC_NEXT2_END:PC_NEXT2_START]; 

always @ (posedge clk or posedge reset) begin : PC_MAINTAIN
	if (reset) begin
		pc <= 2'd0;
   end else  begin
   	if(next_state==STATE_COMPUTE) begin //TODO: check timing for this
			pc <= actual_pc_next;
   		end
   end
end
 
always_comb begin
  instructionCurr <= instructionBuffer[pc];
end

always @ (posedge clk) begin : FILLING_INSTRUCTION_BUFFER
  	if((valid_command==1) & (command==COMMAND_CODE_RECORD_REG_TEMP_A))
      //TODO: add checking that if instruction length is greater than bus_width we should  	
	   instructionBuffer[pc]={{global_data_bus},{row_addr}};
end

//-----------------------------Assigning indirect register values

always @ (posedge clk or posedge reset) begin : Mode_3_MAINTENANCE
	if (reset) begin
		Mode3Calculator<=2'b00;
	end else begin
		if (Mode3Calculator==2'b10) begin
			Mode3Calculator<=2'b00;
		end else begin
			if(shift2) begin
				Mode3Calculator<=Mode3Calculator+1;
			end
		end 
	end		
end

assign indirectRowAddressRegWalker2 = walker1Out[GOLOBAL_DATA_BUS_WIDTH-1: INDIRECT_ACCESS_MASK_WIDTH] ;//walker 2 is indirectly accessed by value in walker 1 always
assign indirectRowAddressRegWalker3 =  walker2Out[GOLOBAL_DATA_BUS_WIDTH-1: INDIRECT_ACCESS_MASK_WIDTH] ;//walker 3 is indirectly accessed by value in walker 2s always
assign indirectColAddressWalker2 = walker1Out[COL_COUNTER_WIDTH-1:0];
assign indirectColAddressWalker3 = walker2Out[COL_COUNTER_WIDTH-1:0];

assign sub_shift2=(colCounter2==indirectColAddressWalker2) ? 1'b0 : 1'b1; 
assign sub_shift3=(colCounter3==indirectColAddressWalker3 ) ? 1'b0 : 1'b1; 

//assign sub_shiftDir2=(colCounter2>indirectColAddressWalker2) ? 1'b1 : 1'b0; //TDOD: check if the direction is correct
//assign sub_shiftDir3=(colCounter3>indirectColAddressWalker3 ) ? 1'b1 : 1'b0; //TDOD: check if the direction is correct

//-------------
assign nxtColCounter1=colCounter1+1;
assign nxtColCounter2=colCounter2+1;
assign nxtColCounter3=colCounter3+1;

//------------
/*

// TODO: change this commented section to implement configurable indirect access masking
assign indirectRowAddressRegWalker2 = (walker1Out & INDIRECT_ACCESS_MASK )[GOLOBAL_DATA_BUS_WIDTH-1: INDIRECT_ACCESS_MASK_WIDTH] ;//walker 2 is indirectly accessed by value in walker 1 always
assign indirectRowAddressRegWalker3 =  (walker2sOut & INDIRECT_ACCESS_MASK )[GOLOBAL_DATA_BUS_WIDTH-1: INDIRECT_ACCESS_MASK_WIDTH] ;//walker 3 is indirectly accessed by value in walker 2s always
always @ (posedge clk or posedge reset) begin : INDIRECT_REG2_MAINTENANCE

	if ( (stepRegister==STEP_CODE_OFFSET_LENGTH_VALUE_PACKING)  |(stepRegister==STEP_CODE_RECIEVED_PROCESSING)  | (stepRegister==STEP_CODE_APPLYING)  ) begin
		if(colCounter2[1]) begin
			
		end
		
	end else begin
		if (stepRegister==STEP_CODE_COLUMN_PROCESSSING)begin
			if (Mode3Calculator==2'b10) begin
				indirectRowAddressRegWalker2 <= (walker1Out & INDIRECT_ACCESS_MASK )[GOLOBAL_DATA_BUS_WIDTH-1: INDIRECT_ACCESS_MASK_WIDTH] ;//walker 2 is indirectly accessed by value in walker 1 always
			end
		end
		
	end
	
end


always @ (posedge clk or posedge reset) begin : INDIRECT_REG3_MAINTENANCE
	if (stepRegister==STEP_CODE_COLUMN_PROCESSSING)begin // in STEP_CODE_COLUMN_PROCESSSING step we use output of second walker for 
		if (colCounter2[0]) begin                  // only for odd words we need assignments
			indirectRowAddressRegWalker3 <=	;//
		end
	end
end

end
*/
//------------------------------------------
//-- Assignment of instructions to signals

assign opCode1   = instructionCurr[OPCODE1_END:OPCODE1_START];
assign opCode2   = instructionCurr[OPCODE2_END:OPCODE2_START];
assign src1Op1   = instructionCurr[SRC1_OP1_END:SRC1_OP1_START];
assign src2Op1   = instructionCurr[SRC2_OP1_END:SRC2_OP1_START];
assign src1Op2   = instructionCurr[SRC1_OP2_END:SRC1_OP2_START];
assign src2Op2   = instructionCurr[SRC2_OP2_END:SRC2_OP2_START];
assign shiftCond1= instructionCurr[SHIFT_COND1_END:SHIFT_COND1_START];
assign shiftCond2= instructionCurr[SHIFT_COND2_END:SHIFT_COND2_START];
assign shiftCond3= instructionCurr[SHIFT_COND3_END:SHIFT_COND3_START];
assign shiftDir1 = instructionCurr[SHIFT_DIR1_END:SHIFT_DIR1_START];
assign shiftDir2 = instructionCurr[SHIFT_DIR2_END:SHIFT_DIR2_START];
assign shiftDir3 = instructionCurr[SHIFT_DIR3_END:SHIFT_DIR3_START];
assign number_of_repeat = instructionCurr[NUMBER_OF_REPEAT_END:NUMBER_OF_REPEAT_START];
//assign actual_pc_next   = command==COMMAND_CODE_LOAD_INSTRUCTION_BUFFER ? (pc+2'd1): 
//                          number_of_repeat==instructionRepeatCounter    ?  pc_next : pc;
assign regTransferSrc= instructionCurr[REG_TRANS_SRC_END:REG_TRANS_SRC_START]; 
assign regTransferDst=instructionCurr[REG_TRANS_DST_END:REG_TRANS_DST_START];

assign pc_next_condition= instructionCurr[PC_NEXT_CONDITION_END:PC_NEXT_CONDITION_START];

always_comb begin
  if (command==COMMAND_CODE_LOAD_INSTRUCTION_BUFFER) begin
        actual_pc_next<=pc+2'd1;
 end else begin
	if( number_of_repeat==instructionRepeatCounter) begin
		actual_pc_next<=pc_next2;
	end else begin

	    case(pc_next_condition)
    		  ALWAYS_NEXT      : actual_pc_next<=pc_next1;
    		  IF_EQUAL_NEXT    : actual_pc_next<=adder_equal_flag ? pc_next1:pc_next2 ;
    		  IF_LESS_NEXT     : actual_pc_next<=adder_less_flag ?pc_next1:pc_next2 ;
    		  IF_GREAT_NEXT    : actual_pc_next<=(!adder_less_flag & !adder_equal_flag) ? pc_next1:pc_next2 ;
   		 default           : actual_pc_next<=pc;
   	    endcase
       end
  end
end
//-- Assign outputs 

assign load_temp_regA = ((valid_command) & (command==COMMAND_CODE_RECORD_REG_TEMP_A));
assign load_temp_regB = ((valid_command) & (command==COMMAND_CODE_RECORD_REG_TEMP_B));
assign load_temp_regC = ((valid_command) & (command==COMMAND_CODE_RECORD_REG_TEMP_C));


//-----------------------Command for filling the start and he end of addresses-----------------------
always @ (posedge clk or posedge reset ) begin : RECORD_ADR
   if (reset) begin
   	row1_start <= 10'h0;
   	row1_end   <= 10'h0;
   	row2_start <= 10'h0;
   	row2_end   <= 10'h0;
   	row3_start <= 10'h0;
   	row3_end   <= 10'h0;
   end else begin
	   if(valid_command) begin
		   case (command)
            //----------
			   COMMAND_CODE_RECORD_ROW1_ADR_START: row1_start<= row_addr;
			   COMMAND_CODE_RECORD_ROW1_ADR_END  : row1_end <= row_addr;
            //----------
			   COMMAND_CODE_RECORD_ROW2_ADR_START: row2_start <= row_addr;
			   COMMAND_CODE_RECORD_ROW2_ADR_END  : row2_end <= row_addr;
            //------------
			   COMMAND_CODE_RECORD_ROW3_ADR_START: row3_start <= row_addr;
			   COMMAND_CODE_RECORD_ROW3_ADR_END  : row3_end <= row_addr;
		   endcase
     end
   end 
end
//---------------------record step register for SuperFIMD---
//------------------------we capture part of the global bus as the value of
//localparam [31:0] ZERO_CONST=0;
//the step register
always @ (posedge clk or posedge reset ) begin : RECORD_STEP_REG
   if (reset) begin
   	//stepRegiste<= ZERO_CONST[STEP_LENGTH-1:0]; //we defined ZERO_CONST only for configurabilty of the length, //TODO:do the same for all other variables
   	stepRegister <= 3'b000; 
   end else begin
	   if((valid_command) &  (command==COMMAND_CODE_SET_STEP))begin 
		stepRegister<=global_data_bus[STEP_LENGTH-1:0];
		    
     	    end
   end 
end
//-----------------------------
always @(posedge clk or posedge reset) begin : STATE_MAINTAIN
	if (reset) state <=STATE_COMPUTE;
	else       state <=next_state;
end

//------------------------------------------------
always_comb begin : NEXT_STATE_MAINTAIN
  if((colCounter1==NUM_OF_COL_IN_ROW-1 ) & (row1_counter!=row1_end))  
 	      	next_state <= STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1;
  else if( (colCounter2==NUM_OF_COL_IN_ROW-1) & (row2_counter!=row2_end))
		next_state <= STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2;
 else if( (colCounter3==NUM_OF_COL_IN_ROW-1) & (row3_counter!=row3_end))
               next_state <= STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3;
 else 
	      next_state <=STATE_COMPUTE;
end

//--------------------------------------------------------
//-------------------------------------------------------

//-------------------------------------Shift Signals
always_comb begin
   if(next_state!=STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1 ) begin //TODO: check the timing for this 
	  case(shiftCond1) 
	    NEVER_SHIFT       : shift1<=1'b0;
	    ALWAYS_SHIFT      : shift1<=1'b1;
	    IF_EQUAL_SHIFT    : shift1<=adder_equal_flag;
	    IF_NOT_EQUAL_SHIFT: shift1<=!adder_equal_flag;
	    IF_LESS_SHIFT     : shift1<=adder_less_flag;
	    IF_GREAT_SHIFT    : shift1<=!adder_less_flag & !adder_equal_flag;
	    default           : shift1<=1'b0;
   	  endcase
   end 

end
always_comb begin
	if(next_state!=STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2) begin  //TODO: check the timing for this v
	  case(shiftCond2) 
	    NEVER_SHIFT       : shift2<=1'b0;
	    ALWAYS_SHIFT      : shift2<=1'b1;
	    IF_EQUAL_SHIFT    : shift2<=adder_equal_flag;
	    IF_NOT_EQUAL_SHIFT: shift2<=!adder_equal_flag;
	    IF_LESS_SHIFT     : shift2<=adder_less_flag;
	    IF_GREAT_SHIFT    : shift2<=!adder_less_flag & !adder_equal_flag;
	    default           : shift2<=1'b0;
	   endcase
	end
end
always_comb begin
	if(next_state!=STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3 ) begin //TODO: check the timing for this 
	  case(shiftCond3) 
	    NEVER_SHIFT       : shift3<=1'b0;
	    ALWAYS_SHIFT      : shift3<=1'b1;
	    IF_EQUAL_SHIFT    : shift3<=adder_equal_flag;
	    IF_NOT_EQUAL_SHIFT: shift3<=!adder_equal_flag;
	    IF_LESS_SHIFT     : shift3<=adder_less_flag;
	    IF_GREAT_SHIFT    : shift3<=!adder_less_flag & !adder_equal_flag;
	    default           : shift3<=1'b0;
	   endcase
	end
end
//-----------------------------------Sub_shift handling

//-----------------------------------
always @(posedge clk or posedge reset) begin : WAIT_COUNTER_HANDLING
   if (reset) wait_counter<=0;
   else begin
    	if((state==STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1 ) | 
         (state==STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2 ) |
         (state==STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3 )) begin
 			wait_counter<=wait_counter+1;
			if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) wait_counter<=0;
    	end
   end
end

always @ (posedge clk or posedge reset) begin : ROW_COUNTER_HANDLING
   if (reset) begin
      row1_counter<=row1_start;
      row2_counter<=row2_start;
      row3_counter<=row3_start;
    end else begin
       	case (state)   
	   	 	STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1: begin // The first walker is the reading sequential data walker, so it is always incrmented 
		 		  if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) begin
					  row1_counter<=row1_counter+1;	
				   end
		   	end
		 	STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2: begin	// the second walker in three cases is the walker that might be accessed with indirect access register 
	        	  	  if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) begin
				  	if ((stepRegister==STEP_CODE_OFFSET_LENGTH_VALUE_PACKING) | (stepRegister==STEP_CODE_COLUMN_PROCESSSING ) |(stepRegister==STEP_CODE_RECIEVED_PROCESSING)  | (stepRegister==STEP_CODE_APPLYING)  ) begin
						row2_counter<=indirectRowAddressRegWalker2;  
					 end else begin
						row2_counter<=row2_counter+1;
					 end
			     	
				   end
		    	end
		 	STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3: begin /// the third walker only for COLUMN_PROCESSSING is used for indirect access
				if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) begin 
					if ((stepRegister==STEP_CODE_OFFSET_LENGTH_VALUE_PACKING) | (stepRegister==STEP_CODE_COLUMN_PROCESSSING ) |(stepRegister==STEP_CODE_RECIEVED_PROCESSING)  | (stepRegister==STEP_CODE_APPLYING)  ) begin
						row3_counter<=indirectRowAddressRegWalker3;
					end else begin		
			     			row3_counter<=row3_counter+1;
					end 
				end
	   		end
    	endcase //end of outer case 
    end //end of else
end  //end of always

always @ (posedge clk or posedge reset) begin : COL_COUNTER_HANDLING
   if (reset) begin
      colCounter1<=NUM_OF_COL_IN_ROW-1;
      colCounter2<=NUM_OF_COL_IN_ROW-1;
      colCounter3<=NUM_OF_COL_IN_ROW-1;
      instructionRepeatCounter<=0;
    end else begin
    	if(start) begin
      		instructionRepeatCounter<=instructionRepeatCounter+1;
      			if(instructionRepeatCounter==number_of_repeat)
           			instructionRepeatCounter<='h0;
			if(stepRegister==STEP_CODE_OFFSET_LENGTH_VALUE_PACKING| stepRegister==STEP_CODE_COLUMN_PROCESSSING | stepRegister==STEP_CODE_RECIEVED_PROCESSING | stepRegister==STEP_CODE_APPLYING  ) begin			
				if(sub_shift2)begin
					colCounter2<=nxtColCounter2;
				end
				if (sub_shift3 & stepRegister==STEP_CODE_COLUMN_PROCESSSING )begin
					colCounter3<=nxtColCounter3;
				end 
			end else begin		
				if(shift1)
						colCounter1<=nxtColCounter1;
				if(shift2)
						colCounter2<=nxtColCounter2;
				if(shift3)
	           			colCounter3<=nxtColCounter3;
			end
      	end
    end
end


assign read_or_write =  (( state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1) & shiftDir1) | (( state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2)& shiftDir2) | (( state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3) & shiftDir3);
assign row1_active = (state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW1);
assign row2_active = (state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW2);
assign row3_active = (state == STATE_WAIT_FOR_ROW_READ_OR_WRITE_ROW3);
assign shiftDir1_read_or_write=shiftDir1;
assign shiftDir2_read_or_write=shiftDir2;
assign shiftDir3_read_or_write=shiftDir3;



endmodule
