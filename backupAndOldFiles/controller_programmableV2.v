module controller_programmable #(
//-------------------Instruction Parameters
   parameter NUM_INSTRUCTION=4, //ischanged next line should change
   parameter PC_WIDTH=2,         //$ceil($clog2(NUM_INSTRUCTION)),
   parameter OPERATION_WIDTH=1,  //for ALU with two operations
   parameter SRC_WIDTH=2,
   parameter SHIFT_CONDITION_WIDTH=3,// if changed, need change in constant defention, look for SHIFT_CONDITION_WIDTH
   parameter NUM_OF_COL_IN_ROW=64,
   parameter NUM_ROW_IN_SUBARRAY=1024,
   parameter NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD=9,
    
   parameter WAIT_CYCLE_WIDTH=4,   //$ceil($clog2(NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD)),
   parameter COL_COUNTER_WIDTH=6,  //$ceil($clog2(NUM_OF_COL_IN_ROW)),
   parameter ROW_ADR_WIDTH=10,     //$ceil($clog2(NUM_ROW_IN_SUBARRAY)),
   
   parameter COMMAND_WIDTH=4,
   parameter GOLOBAL_DATA_BUS_WIDTH=32,
   parameter OUT_SRC_WIDTH=1,
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
//------Start locations-------------

   parameter PC_NEXT_START=0,                          //2
   parameter PC_NEXT_END=PC_NEXT_START+PC_WIDTH-1,

   parameter OPCODE1_START=PC_NEXT_END+1,              //3
   parameter OPCODE1_END=OPCODE1_START+OPERATION_WIDTH-1,

   parameter OPCODE2_START=OPCODE1_END+1,              //5
   parameter OPCODE2_END=OPCODE2_START+OPERATION_WIDTH-1,

   parameter SRC1_OP1_START=OPCODE2_END+1,             //7
   parameter SRC1_OP1_END=SRC1_OP1_START+SRC_WIDTH-1,

   parameter SRC2_OP1_START=SRC1_OP1_END+1,	          //9
   parameter SRC2_OP1_END=SRC2_OP1_START+SRC_WIDTH-1,

   parameter SRC1_OP2_START=SRC2_OP1_END+1,	          //11
   parameter SRC1_OP2_END=SRC1_OP2_START+SRC_WIDTH-1,

   parameter SRC2_OP2_START=SRC1_OP2_END+1,	         //13
   parameter SRC2_OP2_END=SRC2_OP2_START+SRC_WIDTH-1,

   parameter SHIFT_COND1_START=SRC2_OP2_END+1,       //16
   parameter SHIFT_COND1_END=SHIFT_COND1_START+SHIFT_CONDITION_WIDTH-1,

   parameter SHIFT_COND2_START=SHIFT_COND1_END+1,    //19
   parameter SHIFT_COND2_END=SHIFT_COND2_START+SHIFT_CONDITION_WIDTH-1,

   parameter SHIFT_COND3_START=SHIFT_COND2_END+1,   //22
   parameter SHIFT_COND3_END=SHIFT_COND3_START+SHIFT_CONDITION_WIDTH-1,

   parameter SHIFT_DIR1_START=SHIFT_COND3_END+1,    //25
   parameter SHIFT_DIR1_END=SHIFT_DIR1_START+1-1,

   parameter SHIFT_DIR2_START=SHIFT_DIR1_END+1,     //26
   parameter SHIFT_DIR2_END=SHIFT_DIR2_START+1-1,

   parameter SHIFT_DIR3_START=SHIFT_DIR2_END+1,	    //27
   parameter SHIFT_DIR3_END=SHIFT_DIR3_START+1-1,
  

   parameter OUT_SRC_START=SHIFT_DIR3_END+1,		    //28
   parameter OUT_SRC_END=OUT_SRC_START+OUT_SRC_WIDTH-1,
 
   parameter NUMBER_OF_REPEAT_START=OUT_SRC_END+1,	 //34
   //-LPGG
   parameter NUMBER_OF_REPEAT_END=NUMBER_OF_REPEAT_START+COL_COUNTER_WIDTH-1,
   
   //parameter INSTRUCTION_LENGTH= ROW_ADR_WIDTH+GOLOBAL_DATA_BUS_WIDTH,
   parameter INSTRUCTION_LENGTH= NUMBER_OF_REPEAT_END+1,

//-------------------STATE PARAMETER
   parameter STATE_SIZE = 3,
//------STATE ENCODING
   parameter IDLE    = 3'd0,
   parameter COMPUTE = 3'd1 , 
   parameter WAIT_FOR_ROW_READ_OR_WRITE_ROW1 = 3'd2, 
   parameter WAIT_FOR_ROW_READ_OR_WRITE_ROW2 = 3'd3,
   parameter WAIT_FOR_ROW_READ_OR_WRITE_ROW3 = 3'd4,  
 //-------------------SHIFT CONDITION ENCODING, SHIFT_CONDITION_WIDTH
   parameter NEVER_SHIFT=3'd0,
   parameter ALWAYS_SHIFT=3'd1,
   parameter IF_EQUAL_SHIFT=3'd2,
   parameter IF_NOT_EQUAL_SHIFT=3'd3,
   parameter IF_LESS_SHIFT=3'd4,
   parameter IF_GREAT_SHIFT=3'd5,
 
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
   output logic outShiftValueSrc
   

   );

//-- Internal counters
   //--col counters
   logic [COL_COUNTER_WIDTH-1:0] colCounter1;
   logic [COL_COUNTER_WIDTH-1:0] colCounter2;
   logic [COL_COUNTER_WIDTH-1:0] colCounter3;
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

//-------------Internal Variables---------------------------
  logic [STATE_SIZE-1:0]  state        ;// Seq part of the FSM
  logic [STATE_SIZE-1:0]  next_state   ;// combo part of FSM
  logic [0:0] endOfProcess;

  logic [INSTRUCTION_LENGTH-1:0] instructionBuffer [NUM_INSTRUCTION-1:0];
  logic [INSTRUCTION_LENGTH-1:0] instructionCurr ;

//--Signals Mapped From Pre-generated signals

  logic [PC_WIDTH-1:0] pc_next;
  logic [PC_WIDTH-1:0] actual_pc_next;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond1;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond2;
  logic [SHIFT_CONDITION_WIDTH-1:0] shiftCond3;
  logic [0:0] shiftDir1;
  logic [0:0] shiftDir2;
  logic [0:0] shiftDir3;
  logic [OUT_SRC_WIDTH-1:0] outShiftValueSrc;
  logic [COL_COUNTER_WIDTH-1:0] number_of_repeat;


assign pc_next =instructionCurr[PC_NEXT_END:PC_NEXT_START]; 

always @ (posedge clk or posedge reset) begin : PC_MAINTAIN
   if (reset) pc <= 2'd0;
   else       pc <= pc_next;
end
 
always_comb begin
  instructionCurr <= instructionBuffer[pc];
end

always @ (posedge clk) begin : FILLING_INSTRUCTION_BUFFER
  	if((valid_command==1) & (command==COMMAND_CODE_RECORD_REG_TEMP_A))
      //TODO: add checking that if instruction length is greater than bus_width we should  	
	   instructionBuffer[pc]={{global_data_bus},{row_addr}};
end

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
assign actual_pc_next   = command==COMMAND_CODE_LOAD_INSTRUCTION_BUFFER ? (pc+2'd1): 
                          number_of_repeat==instructionRepeatCounter    ?  pc_next : pc;
assign outShiftValueSrc= instructionCurr[OUT_SRC_END:OUT_SRC_START]; 

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

always @(posedge clk or posedge reset) begin : STATE_MAINTAIN
	if (reset) state <=IDLE;
	else       state <=next_state;
end

//------------------------------------------------
always @ (posedge clk or posedge reset) begin : NEXT_STATE_MAINTAIN
   if (reset) next_state <=  IDLE;
   else begin
      if((state==IDLE) & (start==1)) next_state<=COMPUTE; 
		else begin
 	      if((colCounter1==NUM_OF_COL_IN_ROW-1 ) & (row1_counter!=row1_end))  
 	      	next_state <= WAIT_FOR_ROW_READ_OR_WRITE_ROW1;
         else if( (colCounter2==NUM_OF_COL_IN_ROW-1) & (row2_counter!=row2_end))
				next_state <= WAIT_FOR_ROW_READ_OR_WRITE_ROW2;
			else if( (colCounter3==NUM_OF_COL_IN_ROW-1) & (row3_counter!=row3_end))
			   next_state <= WAIT_FOR_ROW_READ_OR_WRITE_ROW3;
			else begin
			   if(endOfProcess) next_state <=IDLE;
				else next_state <=COMPUTE;
			end
		end 
	end
end

//--------------------------------------------------------
//-------------------------------------------------------

//-------------------------------------Shift Signals
always_comb begin
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
always_comb begin
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
always_comb begin
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

always @(posedge clk or posedge reset) begin : WAIT_COUNTER_HANDLING
   if (reset) wait_counter<=0;
   else begin
    	if((state==WAIT_FOR_ROW_READ_OR_WRITE_ROW1 ) | 
         (state==WAIT_FOR_ROW_READ_OR_WRITE_ROW2 ) |
         (state==WAIT_FOR_ROW_READ_OR_WRITE_ROW3 )) begin
 			wait_counter<=wait_counter+1;
			if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) wait_counter<=0;
    	end
   end
end

always @ (posedge clk or posedge reset) begin : COUNTER_HANDLING
   if (reset) begin
      row1_counter<=row1_start;
      row2_counter<=row2_start;
      row3_counter<=row3_start;
      colCounter1<=NUM_OF_COL_IN_ROW;
      colCounter2<=NUM_OF_COL_IN_ROW;
      colCounter3<=NUM_OF_COL_IN_ROW;
      instructionRepeatCounter<=0; 
    end else begin
    	case(state)
         IDLE : begin
	     	end
	     	COMPUTE: begin 
	     		instructionRepeatCounter<=instructionRepeatCounter+1;
	     		if(instructionRepeatCounter==number_of_repeat)
	     		   instructionRepeatCounter<='h0;
				if(shift1)
					colCounter1<=colCounter1+1;
				if(shift2)
					colCounter2<=colCounter2+1;
				if(shift3) 
					colCounter3<=colCounter3+1;
       	 end
	   	 WAIT_FOR_ROW_READ_OR_WRITE_ROW1: begin
		 		if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD)       
	            row1_counter<=row1_counter+1;
		    end
		    WAIT_FOR_ROW_READ_OR_WRITE_ROW2: begin
	          if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD)
			     	row2_counter<=row2_counter+1;
		    end
		    WAIT_FOR_ROW_READ_OR_WRITE_ROW3: begin
				if(wait_counter==NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD) 
			     	row3_counter<=row3_counter+1;
	   	end
    	endcase
    end
end

assign read_or_write =  (( state == WAIT_FOR_ROW_READ_OR_WRITE_ROW1) & shiftDir1) | (( state == WAIT_FOR_ROW_READ_OR_WRITE_ROW2)& shiftDir2) | (( state == WAIT_FOR_ROW_READ_OR_WRITE_ROW3) & shiftDir3);
assign row1_active = (state == WAIT_FOR_ROW_READ_OR_WRITE_ROW1);
assign row2_active = (state == WAIT_FOR_ROW_READ_OR_WRITE_ROW2);
assign row3_active = (state == WAIT_FOR_ROW_READ_OR_WRITE_ROW3);
assign shiftDir1_read_or_write=shiftDir1;
assign shiftDir2_read_or_write=shiftDir2;
assign shiftDir3_read_or_write=shiftDir3;


endmodule
