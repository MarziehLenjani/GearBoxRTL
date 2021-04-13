`include "./config.h"
module subArray #(

//-------------------Shared Parameters with controller  
   parameter PC_WIDTH=`PC_WIDTH_CONFIG, 
   parameter OPERATION_WIDTH=`OPERATION_WIDTH_CONFIG,  //for ALU with two operations , changes opcode defintion
   parameter SRC_WIDTH=3, 
   parameter NUM_OF_COL_IN_ROW=64,
   parameter NUM_ROW_IN_SUBARRAY=1024,
   parameter ROW_CYCLE=50, //ns
   parameter SHIFT_CYCLE=6, //ns 
   parameter NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD=9,  //$ceil(ROW_CYCLE/SHIFT_CYCLE),
   parameter WAIT_CYCLE_WIDTH=4   ,        //$ceil($clog2(NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD)),
   parameter COL_COUNTER_WIDTH=6,      //$ceil($clog2(NUM_OF_COL_IN_ROW)),
   parameter ROW_ADR_WIDTH=10,// $ceil($clog2(NUM_ROW_IN_SUBARRAY)),
   parameter COMMAND_WIDTH=4,
   parameter GOLOBAL_DATA_BUS_WIDTH=32,
   
//----------------------
  
   
//------OPCODE ENCODING
  parameter ADD_OPCODE=`OPERATION_WIDTH_CONFIG'd 0,
  parameter MULT_OPCODE=`OPERATION_WIDTH_CONFIG'd 2,
  parameter XOR_OPCODE=`OPERATION_WIDTH_CONFIG'd 3,
  parameter NOR_OPCODE=`OPERATION_WIDTH_CONFIG'd 4,
  parameter AND_OPCODE=`OPERATION_WIDTH_CONFIG'd 5,
  parameter OR_OPCODE=`OPERATION_WIDTH_CONFIG'd 6,
  parameter SHIFT_OPCODE=`OPERATION_WIDTH_CONFIG'd 7,
  parameter FLOAT_MULT_OPCODE=`OPERATION_WIDTH_CONFIG'd 8,
  parameter FLOAT_ADD_OPCODE=`OPERATION_WIDTH_CONFIG'd 9,
  parameter FLOAT_SUB_OPCODE=`OPERATION_WIDTH_CONFIG'd 10, //TODO: implement
  parameter SUB_OPCODE=`OPERATION_WIDTH_CONFIG'd 11,  //TODO: implement
  parameter MIN_OPCODE=`OPERATION_WIDTH_CONFIG'd 12, //TODO: implement
  parameter FLOAT_MIN_OPCODE=`OPERATION_WIDTH_CONFIG'd 13, //TODO: COMPARE replaced by this, compared used to be an instruction that dose not change the output register but only sets,
  //in superFIMD we added a filed for register transfers , elimnating the need for COMPARE instruction, TODO: eimplement the register transfer instructions
  parameter PASS_INPUT_TO_REG_OPCODE=`OPERATION_WIDTH_CONFIG'd 14, //TODO: implement
  parameter NULL_OPCODE_KEEP_OUTPUT_OPCODE=`OPERATION_WIDTH_CONFIG'd 15, //TODO: implement
//-----------SRC SELCTION ENCODING
   parameter SRC_ROW1=0,
   parameter SRC_ROW2=1,
   parameter SRC_GLLOBAL_BUS=2,
   parameter SRC_TEMP_REG_A=3,
   parameter SRC_TEMP_REG_B=4,
   parameter SRC_TEMP_REG_C=5,
   parameter SRC_OPERATION1_OUTPUT1=6,
   parameter SRC_OPERATION2_OUTPUT1=7,
//---------------READ_WRITE_ENCODING
   parameter READ=0,
   parameter WRITE=1,
   //------------------------REG TRANSFER ENCODING
   parameter REG_TRANS_SRC_INVALID=`REG_TRANS_SRC_WIDTH_CONFIG'd 0,
   parameter REG_TRANS_SRC_OPERATION1=`REG_TRANS_SRC_WIDTH_CONFIG'd 1,
   parameter REG_TRANS_SRC_OPERATION2=`REG_TRANS_SRC_WIDTH_CONFIG'd 2,
   parameter REG_TRANS_SRC_WALKER1=`REG_TRANS_SRC_WIDTH_CONFIG'd 3,
   parameter REG_TRANS_SRC_WALKER2=`REG_TRANS_SRC_WIDTH_CONFIG'd 4,
   parameter REG_TRANS_SRC_MAX=`REG_TRANS_SRC_WIDTH_CONFIG'd 5,
   parameter REG_TRANS_SRC_MIN=`REG_TRANS_SRC_WIDTH_CONFIG'd 6,
   parameter REG_TRANS_SRC_BROADCASTED=`REG_TRANS_SRC_WIDTH_CONFIG'd 7,
   
	//----------------------------
	parameter REG_TRANS_DST_SHIFTED_WALKER=`REG_TRANS_DST_WIDTH_CONFIG'd 0, //TODO: not impelemnted in the new version yet, it is for sort or dichotoizing, it can be also both walker 1 and walker 2, whoever dose the shift will be the one who recieves itss
	parameter REG_TRANS_DST_WALKER2=`REG_TRANS_DST_WIDTH_CONFIG'd 1,
	parameter REG_TRANS_DST_WALKER3=`REG_TRANS_DST_WIDTH_CONFIG'd 2,
	parameter REG_TRANS_DST_REG_A=`REG_TRANS_DST_WIDTH_CONFIG'd 3,
	parameter REG_TRANS_DST_REG_REPEAT_REG=`REG_TRANS_DST_WIDTH_CONFIG'd 4, //
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
   input logic sub_clk,   //TODO: the sublock is introduced for SuperFIMD where we might need to uses subclock f segmented TSV for 
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] NOC_IN,
   //--------
   input logic [GOLOBAL_DATA_BUS_WIDTH-1:0] walker1Out,walker2Out,walker3Out,
   //--------
   output logic loadRow1,loadRow2,loadRow3,
   output logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  inputColumnToRowWides,
   output logic shift1,shift2,shift3,
   output logic shiftDir1_read_or_write,shiftDir2_read_or_write,shiftDir3_read_or_write, //0 read, write 1
   output logic endOfStep,   //added for SupeFIMD, TODO: put value for this
  // output logic  sub_shift1,
   output logic  sub_shift2,
   output logic  sub_shift3,
   //output logic  sub_shiftDir1,
   output logic  sub_shiftDir2,
   output logic  sub_shiftDir3,
   output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] NOC_OUT,
//-------
   output logic equalFlag,
   output logic greaterFlag,
   output logic lessFlag,
   output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] walker2In,walker3In
//output logic [NUM_OF_COL_IN_ROW-1:0]  [GOLOBAL_DATA_BUS_WIDTH-1:0]
//outputRow,
//output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] outputColumn
   );
	
//---------------------Internal Variables
   //Controller's ports
   //logic [0:0] shift1;
   //logic [0:0] shift2;
   //logic [0:0] shift3;
   //logic [0:0] shiftDir1_read_or_write;
   //logic [0:0] shiftDir2_read_or_write;
   //logic [0:0] shiftDir3_read_or_write;
   logic [OPERATION_WIDTH-1:0] opCode1;
   logic [OPERATION_WIDTH-1:0] opCode2;
   logic [SRC_WIDTH-1:0] src1Op1;
   logic [SRC_WIDTH-1:0] src2Op1;
   logic [SRC_WIDTH-1:0] src1Op2;
   logic [SRC_WIDTH-1:0] src2Op2;
   logic read_or_write;
   logic row1_active;
   logic row2_active;
   logic row3_active;

   logic load_temp_regA;
   logic load_temp_regB;
   logic load_temp_regC;
   
//Shift Registers signal
   logic [NUM_OF_COL_IN_ROW-1:0] [GOLOBAL_DATA_BUS_WIDTH-1:0] outputRow1;
   logic [NUM_OF_COL_IN_ROW-1:0] [GOLOBAL_DATA_BUS_WIDTH-1:0] outputRow2;
   logic [NUM_OF_COL_IN_ROW-1:0] [GOLOBAL_DATA_BUS_WIDTH-1:0] outputRow3;
//------------------temp registers
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  selectedForRegTransfer;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  temp_regA;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  temp_regB;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  temp_regC;

//---------------Adder  input signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] adder_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] adder_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] adder_output1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] signdInput1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] signdInput2;

//---------------------------------
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatMultiplier_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatMultiplier_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatMultiplier_output1;

   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatAdder_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatAdder_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] floatAdder_output1;
//------------------------------
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] shifter_input1;
   //logic [GOLOBAL_DATA_BUS_WIDTH-1:0] shifter_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] shifter_output1;
   logic sign_operation1_input2;
   logic sign_operation2_input2;
//------------------------------
   
   logic [PC_WIDTH-1:0] pc;
//--------------------------------
   logic integerAdderEqualFlag;
   logic integerAdderLessFlag;
//-------------------------
 //  logic [SRC_WIDTH-1:0] src1Adder;
 //  logic [SRC_WIDTH-1:0] src2Adder;
 //  logic [SRC_WIDTH-1:0] src1Multiplier;
  // logic [SRC_WIDTH-1:0] src2Multiplier;
//---------------Signals automatically generated by mpdole instanciation   
   //logic equalFlag;
   //logic lessFlag;
  

//--------------multiplier input signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] multiplier_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] multiplier_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] multiplier_output1;
//--------------------------------------
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] ander_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] ander_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] ander_output1 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] selectedInput2;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] signedInput2;
//--------------------------------------

   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] orer_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] orer_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] orer_output1;
//--------------------------------------Row signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] xorer_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] xorer_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] xorer_output1;
//--------------------------------------Row signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] norer_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] norer_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] norer_output1;
//--------------------------------------Row signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation1_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation1_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation1_output1;
//--------------------------------------Row signals
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation2_input1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation2_input2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] operation2_output1;
//--------------------------------------egister transfer signals

   //logic [GOLOBAL_DATA_BUS_WIDTH-1:0] inputColumnRow1;
   //logic [GOLOBAL_DATA_BUS_WIDTH-1:0] inputColumnRow2 ;
   //logic [GOLOBAL_DATA_BUS_WIDTH-1:0] inputColumnRow3;

   logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  outputColumnRow1;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] outputColumnRow2 ;
   logic [GOLOBAL_DATA_BUS_WIDTH-1:0] outputColumnRow3;
   //------------------
   logic [`REG_TRANS_SRC_WIDTH_CONFIG-1:0] regTransferSrc;
   logic [`REG_TRANS_DST_WIDTH_CONFIG-1:0] regTransferDst;
   //logic loadRow1;
   //logic loadRow2;
   //logic loadRow3;
//Signals added for SuperFIMD
   //logic [2:1] numSubClockShiftWalker1;
   //logic [2:1] numSubClockShiftWalker2;	
   //logic [2:1] numSubClockShisftWalker3;
   assign sub_clk=clk;

//------------------------------------

adder#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH)) 
 adder_instance1(
.input1(adder_input1),
.input2(adder_input2),
.output1(adder_output1),
.equalFlag(integerAdderEqualFlag),
.lessFlag(integerAdderLessFlag)
);
multiplier#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 multiplier_instance1(
.input1(multiplier_input1),
.input2(multiplier_input2),
.output1(multiplier_output1)
);
//assign rowToSubarray[1]=multiplier_output1; //debug line 
`ifdef BITWISE_ALU_SUPPORT_CONFIG
ander#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 ander_instance1(
.input1(ander_input1),
.input2(ander_input2),
.output1(ander_output1)
);
shifter#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 shifter_instance1(
.input1(shifter_input1),
.output1(shifter_output1)
);

orer#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 orer_instance1(
.input1(orer_input1),
.input2(orer_input2),
.output1(orer_output1)
);
xorer#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 xorer_instance1(
.input1(xorer_input1),
.input2(xorer_input2),
.output1(xorer_output1)
);
norer#(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH))
 norer_instance1(
.input1(norer_input1),
.input2(norer_input2),
.output1(norer_output1)
);
`endif
//assign rowToSubarray[1]=multiplier_output1; //debug line 
//--------------------------------------
//----------------------
`ifdef FLOAT_ALU_SUPPORT_CONFIG
`ifdef FLOAT_MULTIPLIER_SUPPORT_CONFIG
floatMultiplier  
floatMultiplier_instance1(  
.a(floatMultiplier_input1),
.b(floatMultiplier_input2),
.out(floatMultiplier_output1)
);
`endif
`ifdef FLOAT_ADDER_SUPPORT_CONFIG
floatAdder
floatAdder_instance1(
.a(floatAdder_input1),
.b(floatAdder_input2),
.out(floatAdder_output1));
//
`endif
`endif
always_comb begin //TODO: check timing fo this assuming sign is ready is the same cycle
	if(reset) begin
		equalFlag<=1'b0;
	    greaterFlag<=1'b0;
		lessFlag<=1'b0;	
	end else begin
		if(opCode1==SUB_OPCODE |opCode2==SUB_OPCODE ) begin
			equalFlag<=integerAdderEqualFlag;	
			lessFlag<=integerAdderLessFlag;	
			greaterFlag<=~integerAdderLessFlag;
		end
`ifdef FLOAT_ALU_SUPPORT_CONFIG
`ifdef FLOAT_ADDER_SUPPORT_CONFIG
		else begin
			if(opCode1==FLOAT_SUB_OPCODE |opCode2==FLOAT_SUB_OPCODE ) begin
				equalFlag<=(floatAdder_output1=='b0);	
				lessFlag<=floatAdder_output1 [`GOLOBAL_DATA_BUS_WIDTH_CONFIG-1:`GOLOBAL_DATA_BUS_WIDTH_CONFIG-1];	
				greaterFlag<=(~lessFlag) & (~equalFlag);
			end else begin 
				equalFlag<=equalFlag; // TOD: make sure it is synthesizable (it is latch )
				greaterFlag<=greaterFlag;
				lessFlag<=lessFlag;		
			end
		end
		
			
`endif
`else
		else begin
			equalFlag<=equalFlag; // TOD: make sure it is synthesizable (it is latch )
			greaterFlag<=greaterFlag;
			lessFlag<=lessFlag;			
		end

`endif				
	end
		
end	
//assign rowToSubarray[2]=multiplier_output1; //debug line
//-----------------------------------------------------
controller_programmable#(
  .OPERATION_WIDTH(OPERATION_WIDTH),  //for ALU with two operations
  .SRC_WIDTH(SRC_WIDTH), 
   .NUM_OF_COL_IN_ROW(NUM_OF_COL_IN_ROW),
   .NUM_ROW_IN_SUBARRAY(NUM_ROW_IN_SUBARRAY),
   .NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD(NUMBER_OF_WAIT_CYCLE_FOR_ROW_LOAD),
   .WAIT_CYCLE_WIDTH(WAIT_CYCLE_WIDTH),
   .COL_COUNTER_WIDTH(COL_COUNTER_WIDTH),
   .ROW_ADR_WIDTH(ROW_ADR_WIDTH),
   .COMMAND_WIDTH(COMMAND_WIDTH),
   .GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH)
)
 controller_instance1
(
   .clk(clk), 
   .reset(reset), .start(start),.valid_command(valid_command),   
   .row_addr(row_addr),
   .command(command),
   .global_data_bus(global_data_bus), //TODO: implement systolic GDls here
  .adder_equal_flag(equalFlag),
   .adder_less_flag(lessFlag),
   .walker1Out(walker1Out), //new inputs for SuperFIMD
   .walker2Out(walker2Out),
   .walker3Out(walker3Out),
   .sub_clk(sub_clk),
   
//---------------------
   .shift1(shift1),
   .shift2(shift2),
   .shift3(shift3),
   .shiftDir1_read_or_write(shiftDir1_read_or_write),
   .shiftDir2_read_or_write(shiftDir2_read_or_write),
   .shiftDir3_read_or_write(shiftDir3_read_or_write),
   .opCode1(opCode1),
   .opCode2(opCode2),
   .src1Op1(src1Op1),
   .src2Op1(src2Op1),
   .src1Op2(src1Op2),
   .src2Op2(src2Op2),
   .read_or_write(read_or_write),
   .row1_active(row1_active),
   .row2_active(row2_active),
   .row3_active(row3_active),
   .load_temp_regA(load_temp_regA),
   .load_temp_regB(load_temp_regB),
   .load_temp_regC(load_temp_regC),
   .pc(pc),
   .regTransferSrc(regTransferSrc),
   .regTransferDst(regTransferDst),
   .endOfStep(endOfStep),
   //.numSubClockShiftWalker1(numSubClockShiftWalker1),
   //.numSubClockShiftWalker2(numSubClockShiftWalker2),	
   //.numSubClockShisftWalker3(numSubClockShisftWalker3),
   //.sub_shift1(sub_shift1),
   .sub_shift2(sub_shift2),
   .sub_shift3(sub_shift3)
   //.sub_shiftDir1(sub_shiftDir1),
   //.sub_shiftDir2(sub_shiftDir2),
   //.sub_shiftDir3(sub_shiftDir3)
   );


/*
//-----------------------------------
row_wide_shifter #(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH),
.NUM_OF_COL_IN_ROW(NUM_OF_COL_IN_ROW)
)row_wide_shifter_instance1
(
.clk(clk),
.loadRow(loadRow1),
.inputRow(rowFromSubarray),
.inputColumn(inputColumnRow1),
.shiftSignal(shift1),
.shiftDir_read_or_write(shiftDir1_read_or_write), //1 right, 0 
//-------
.outputRow(outputRow1),
.outputColumn(outputColumnRow1)
);
//---------------------------------
row_wide_shifter #(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH),
.NUM_OF_COL_IN_ROW(NUM_OF_COL_IN_ROW)
)row_wide_shifter_instance2
(
.clk(clk),
.loadRow(loadRow2),
.inputRow(rowFromSubarray),
.inputColumn(inputColumnRow2),
.shiftSignal(shift2),
.shiftDir_read_or_write(shiftDir2_read_or_write), //read 0, write 1
//-------
.outputRow(outputRow2),
.outputColumn(outputColumnRow2)
);
//----------------------------------
row_wide_shifter #(
.GOLOBAL_DATA_BUS_WIDTH(GOLOBAL_DATA_BUS_WIDTH),
.NUM_OF_COL_IN_ROW(NUM_OF_COL_IN_ROW)
)row_wide_shifter_instance3
(
.clk(clk),
.loadRow(loadRow3),
.inputRow(rowFromSubarray),
.inputColumn(inputColumnRow3),
.shiftSignal(shift3),
.shiftDir_read_or_write(shiftDir3_read_or_write), //read 0, write 1
//-------
.outputRow(outputRow3),
.outputColumn(outputColumnRow3)
);
*/
//--------------------------------------Assigning input and output of signals
  //assign inputColumnToRowWides = outShiftValueSrc ? adder_output1:  multiplier_output1;
  //assign inputColumnRow2 = outShiftValueSrc ? adder_output1:  multiplier_output1;
  //assign inputColumnRow3 = outShiftValueSrc ? adder_output1:  multiplier_output1;
//-------------------------------------
   assign loadRow1 = row1_active & (read_or_write==READ);
   assign loadRow2 = row2_active & (read_or_write==READ);
   assign loadRow3 = row3_active & (read_or_write==READ);
//-------------------------------------
// the following lines are replaced by always_comb begin
   

   assign selectedInput2= (opCode1 == ADD_OPCODE |opCode1 ==  SUB_OPCODE )? operation1_input2 :operation2_input2;
   
   always_comb begin
	if(opCode1 ==  SUB_OPCODE | opCode2 ==  SUB_OPCODE) begin
		signedInput2<=~selectedInput2+1'b1; //TODO: make sure it generate 2's complement
	end else begin
		signedInput2<=selectedInput2;
	end
end
   `ifdef INTEGER_ADDER_SUPPORT_CONFIG

   assign adder_input1 = (opCode1 == ADD_OPCODE) ?  operation1_input1: ((opCode2 == ADD_OPCODE) ? operation2_input1:0); 
   assign adder_input2 = (opCode1 == ADD_OPCODE |opCode1 ==  SUB_OPCODE |opCode2 == ADD_OPCODE |opCode2 ==  SUB_OPCODE ) ?  signedInput2:0; 
//------------------


`endif 

`ifdef INTEGER_MULTIPLIER_SUPPORT_CONFIG

   assign multiplier_input1 = (opCode1 == MULT_OPCODE) ?  operation1_input1: ((opCode2 == MULT_OPCODE) ? operation2_input1:0); 
   assign multiplier_input2 = (opCode1 == MULT_OPCODE) ?  operation1_input2: ((opCode2 == MULT_OPCODE) ? operation2_input2:0); 
`endif
`ifdef FLOAT_ALU_SUPPORT_CONFIG
`ifdef FLOAT_MULTIPLIER_SUPPORT_CONFIG
		
   assign floatMultiplier_input1 = (opCode1 == FLOAT_MULT_OPCODE) ?  operation1_input1: ((opCode2 == FLOAT_MULT_OPCODE) ? operation2_input1:0); 
   assign floatMultiplier_input2 = (opCode1 == FLOAT_MULT_OPCODE) ?  operation1_input2: ((opCode2 == FLOAT_MULT_OPCODE) ? operation2_input2:0); 
//-----------------
`endif
`ifdef FLOAT_ADDER_SUPPORT_CONFIG
		
	assign sign_operation1_input2=(opCode1 == FLOAT_SUB_OPCODE)?~operation1_input2[GOLOBAL_DATA_BUS_WIDTH-1:GOLOBAL_DATA_BUS_WIDTH-1]:operation1_input2[GOLOBAL_DATA_BUS_WIDTH-1:GOLOBAL_DATA_BUS_WIDTH-1];
	assign sign_operation2_input2=(opCode2 == FLOAT_SUB_OPCODE)?~operation2_input2[GOLOBAL_DATA_BUS_WIDTH-1:GOLOBAL_DATA_BUS_WIDTH-1]:operation2_input2[GOLOBAL_DATA_BUS_WIDTH-1:GOLOBAL_DATA_BUS_WIDTH-1];
   	assign floatAdder_input1 = (opCode1 == FLOAT_ADD_OPCODE) ?  operation1_input1: ((opCode2 == FLOAT_ADD_OPCODE) ? operation2_input1:0); 
    assign floatAdder_input2 = (opCode1 == FLOAT_ADD_OPCODE|opCode2==FLOAT_SUB_OPCODE) ?  {{sign_operation1_input2},{operation1_input2[GOLOBAL_DATA_BUS_WIDTH-2:0]}}: ((opCode2 == FLOAT_ADD_OPCODE|opCode2 == FLOAT_SUB_OPCODE) ? {{sign_operation2_input2},{operation2_input2[GOLOBAL_DATA_BUS_WIDTH-2:0]}}:0); 

   `endif
`endif
//------------------
//------------------
//-----------------
`ifdef BITWISE_ALU_SUPPORT_CONFIG
   assign shifter_input1 = (opCode1 == SHIFT_OPCODE) ?  operation1_input1: ((opCode2 == SHIFT_OPCODE) ? operation2_input1:0);
   //---------
   assign xorer_input1 = (opCode1 == XOR_OPCODE) ?  operation1_input1: ((opCode2 == XOR_OPCODE) ? operation2_input1:0); 
   assign xorer_input2 = (opCode1 == XOR_OPCODE) ?  operation1_input2: ((opCode2 == XOR_OPCODE) ? operation2_input2:0); 
///-------------
   assign orer_input1 = (opCode1 == OR_OPCODE) ?  operation1_input1: ((opCode2 == OR_OPCODE) ? operation2_input1:0); 
   assign orer_input2 = (opCode1 == OR_OPCODE) ?  operation1_input2: ((opCode2 == OR_OPCODE) ? operation2_input2:0); 
//----------------
   assign ander_input1 = (opCode1 == AND_OPCODE) ?  operation1_input1: ((opCode2 == AND_OPCODE) ? operation2_input1:0); 
   assign ander_input2 = (opCode1 == AND_OPCODE) ?  operation1_input2: ((opCode2 == AND_OPCODE) ? operation2_input2:0); 
`endif
    
//--------------------
    
always_comb begin
	case (regTransferSrc)
		REG_TRANS_SRC_OPERATION1:begin
			selectedForRegTransfer<=operation1_output1;
		end
		REG_TRANS_SRC_OPERATION2:begin
			selectedForRegTransfer<=operation2_output1;
		end
		REG_TRANS_SRC_WALKER1:begin
			selectedForRegTransfer<=walker1Out;
		end
		REG_TRANS_SRC_WALKER2:begin
			selectedForRegTransfer<=walker2Out;
		end
		REG_TRANS_SRC_MAX:begin
			if( greaterFlag) begin //assuming opCode1 is SUB_OPCODE
				selectedForRegTransfer<=operation1_input1;
			end else begin
				selectedForRegTransfer<=operation1_input2;
			end
		end
		REG_TRANS_SRC_MIN:begin
			if(lessFlag ) begin //assuming opCode1 is SUB_OPCODE
				selectedForRegTransfer<=operation1_input1;
			end else begin
				selectedForRegTransfer<=operation1_input2;
			end
		end
		
		default:begin
			selectedForRegTransfer<=`GOLOBAL_DATA_BUS_WIDTH_CONFIG'd 0;
		end
		
	
	endcase;
end
//------------------
always_comb begin
  
  case(opCode1) 
`ifdef    FLOAT_ALU_SUPPORT_CONFIG
`ifdef FLOAT_ADDER_SUPPORT_CONFIG
    FLOAT_ADD_OPCODE:begin
		
   		operation1_output1<=floatAdder_output1;
    end
`endif
`ifdef FLOAT_MULTIPLIER_SUPPORT_CONFIG

    FLOAT_MULT_OPCODE:begin	
   		operation1_output1<=floatMultiplier_output1;
    end
`endif
`endif
`ifdef INTEGER_ADDER_SUPPORT_CONFIG
    ADD_OPCODE: begin
   		operation1_output1<=adder_output1;
    end	
`endif
`ifdef INTEGER_MULTIPLIER_SUPPORT_CONFIG
    MULT_OPCODE: begin
		operation1_output1<=multiplier_output1;
    end
`endif
`ifdef BITWISE_ALU_SUPPORT_CONFIG
    XOR_OPCODE: begin
		operation1_output1<=xorer_output1;
    end
    OR_OPCODE: begin
		operation1_output1<=orer_output1;
    end
    AND_OPCODE: begin
		operation1_output1<=ander_output1;
    end
    NOR_OPCODE: begin
	       operation1_output1<=norer_output1;
    end
    SHIFT_OPCODE: begin
	       operation1_output1<=shifter_output1;
    end
 `endif

     default:begin
                 operation1_output1<=0;
    end
    endcase;
  
end

always_comb begin
  
  case(opCode2) 
`ifdef FLOAT_ALU_SUPPORT_CONFIG
`ifdef FLOAT_ADDER_SUPPORT_CONFIG 
    FLOAT_ADD_OPCODE:begin
		
   		operation2_output1<=floatAdder_output1;
    end
`endif
`ifdef FLOAT_MULTIPLIER_SUPPORT_CONFIG
    FLOAT_MULT_OPCODE: begin
		
   		operation2_output1<=floatMultiplier_output1;
    end
`endif
`endif
`ifdef INTEGER_ADDER_SUPPORT_CONFIG
    ADD_OPCODE: begin
   		operation2_output1<=adder_output1;
    end	
`endif
`ifdef INTEGER_MULTIPLIER_SUPPORT_CONFIG
    MULT_OPCODE: begin
		operation2_output1<=multiplier_output1;
    end
`endif
`ifdef BITWISE_ALU_SUPPORT_CONFIG
    XOR_OPCODE: begin
		operation2_output1<=xorer_output1;
    end
    OR_OPCODE: begin
		operation2_output1<=orer_output1;
    end
    AND_OPCODE: begin
		operation2_output1<=ander_output1;
    end
    NOR_OPCODE: begin
	       operation2_output1<=norer_output1;
    end
    SHIFT_OPCODE: begin
	       operation2_output1<=shifter_output1;
    end
`endif

     default:begin
                 operation2_output1<=0;
    end
    endcase;
  
end
 
/* 
///-----------Multiplier
   assign multiplier_input1 = (opCode1 == MULT_OPCODE) ? operation1_input1 : 0; 
   assign multiplier_input2 = (opCode1 == MULT_OPCODE) ? operation1_input2 : 0;
   assign multiplier_input1 = (opCode2 == MULT_OPCODE) ? operation1_input1 : 0; 
   assign multiplier_input2 = (opCode2 == MULT_OPCODE) ? operation1_input2 : 0; 

    assign xorer_input1 = (opCode1 == XOR_OPCODE) ? operation1_input1 : 0; 
   assign xorer_input2 = (opCode1 == XOR_OPCODE) ? operation1_input2 : 0;
   assign xorer_input1 = (opCode2 == XOR_OPCODE) ? operation1_input1 : 0; 
   assign xorer_input2 = (opCode2 == XOR_OPCODE) ? operation1_input2 : 0; 

   assign ander_input1 = (opCode1 == AND_OPCODE) ? operation1_input1 : 0; 
   assign ander_input2 = (opCode1 == AND_OPCODE) ? operation1_input2 : 0;
   assign ander_input1 = (opCode2 == AND_OPCODE) ? operation1_input1 : 0; 
   assign ander_input2 = (opCode2 == AND_OPCODE) ? operation1_input2 : 0; 

   assign orer_input1 = (opCode1 == OR_OPCODE) ? operation1_input1 : 0; 
   assign orer_input2 = (opCode1 == OR_OPCODE) ? operation1_input2 : 0;
   assign orer_input1 = (opCode2 == OR_OPCODE) ? operation1_input1 : 0; 
   assign orer_input2 = (opCode2 == OR_OPCODE) ? operation1_input2 : 0; 

   assign norer_input1 = (opCode1 == NOR_OPCODE) ? operation1_input1 : 0; 
   assign norer_input2 = (opCode1 == NOR_OPCODE) ? operation1_input2 : 0;
   assign norer_input1 = (opCode2 == NOR_OPCODE) ? operation1_input1 : 0; 
   assign norer_input2 = (opCode2 == NOR_OPCODE) ? operation1_input2 : 0; 



*/
 //  assign src2Adder= (opCode1 == ADD_OPCODE) ? src2Op1 : src2Op2;
 //  assign src1Multiplier =(opCode1 == MULT_OPCODE) ? src1Op1 : src1Op2;
 //  assign src2Multiplier =(opCode1 == MULT_OPCODE) ? src2Op1 : src2Op2;
//------------------------------------
//assign rowToSubarray=read_or_write ?(row1_active ? (outputRow1):(row2_active ?outputRow2:outputRow3 )):(0); //debug commented
/*
always @(*) begin
  
  case({{read_or_write},{row1_active},{row1_active},{row1_active}})
     4'b1100:begin
   	rowToSubarray<=outputRow1;
     end
     4'b1010:begin
   	rowToSubarray<=outputRow2;
     end
     4'b1001:begin
   	 rowToSubarray<=outputRow3;
     end
     default:begin
         rowToSubarray<=0;
     end
    endcase;
  
end
*/
//------------------------
always_comb begin
  
  case(src1Op1) 
    SRC_ROW1: begin
   		operation1_input1<=outputColumnRow1;
    end	
    SRC_ROW2: begin
		operation1_input1<=outputColumnRow2;
    end
    SRC_GLLOBAL_BUS: begin
		operation1_input1<=global_data_bus;
    end
    SRC_TEMP_REG_A: begin
		operation1_input1<=temp_regA;
    end
    SRC_TEMP_REG_B: begin
		operation1_input1<=temp_regB;
    end
    SRC_TEMP_REG_C: begin
	       operation1_input1<=temp_regC;
    end
    SRC_OPERATION1_OUTPUT1: begin
		operation1_input1<=operation1_output1;
     end
    SRC_OPERATION2_OUTPUT1: begin
		operation1_input1<=operation2_output1;
     end
     default:begin
                 operation1_input1<=0;
    end
    endcase;
  
end

always_comb begin
  
  case(src2Op1) 
    SRC_ROW1: begin
   		operation1_input2<=outputColumnRow1;
    end	
    SRC_ROW2: begin
		operation1_input2<=outputColumnRow2;
    end
    SRC_GLLOBAL_BUS: begin
		operation1_input2<=global_data_bus;
    end
    SRC_TEMP_REG_A: begin
		operation1_input2<=temp_regA;
    end
    SRC_TEMP_REG_B: begin
		operation1_input2<=temp_regB;
    end
    SRC_TEMP_REG_C: begin
	       operation1_input2<=temp_regC;
    end
    SRC_OPERATION1_OUTPUT1: begin
		operation1_input2<=operation1_output1;
     end
    SRC_OPERATION2_OUTPUT1: begin
		operation1_input2<=operation2_output1;
     end
     default:begin
                 operation1_input2<=0;
    end
    endcase;
 
  
end
//--------------------

always_comb begin
  
  case(src1Op2) 
    SRC_ROW1: begin
   		operation2_input1<=outputColumnRow1;
    end	
    SRC_ROW2: begin
		operation2_input1<=outputColumnRow2;
    end
    SRC_GLLOBAL_BUS: begin
		operation2_input1<=global_data_bus;
    end
    SRC_TEMP_REG_A: begin
		operation2_input1<=temp_regA;
    end
    SRC_TEMP_REG_B: begin
		operation2_input1<=temp_regB;
    end
    SRC_TEMP_REG_C: begin
	       operation2_input1<=temp_regC;
    end
    SRC_OPERATION1_OUTPUT1: begin
		operation2_input1<=operation1_output1;
     end
    SRC_OPERATION2_OUTPUT1: begin
		operation2_input1<=operation2_output1;
     end
     default:begin
                 operation2_input1<=0;
    end
    endcase;
 
  
end
always_comb begin
  
  case(src1Op1) 
    SRC_ROW1: begin
   		operation2_input2<=outputColumnRow1;
    end	
    SRC_ROW2: begin
		operation2_input2<=outputColumnRow2;
    end
    SRC_GLLOBAL_BUS: begin
		operation2_input2<=outputColumnRow3;
    end
    SRC_TEMP_REG_A: begin
		operation2_input2<=temp_regA;
    end
    SRC_TEMP_REG_B: begin
		operation2_input2<=temp_regB;
    end
    SRC_TEMP_REG_C: begin
	       operation2_input2<=temp_regC;
    end
    SRC_OPERATION1_OUTPUT1: begin
	 	operation2_input2<=operation1_output1;
     end
    SRC_OPERATION2_OUTPUT1: begin
		operation2_input2<=operation2_output1;
     end
     default:begin
                 operation2_input2<=0;
    end
    endcase;
 
  
end

always @ (posedge clk or posedge reset ) begin : WALKER2_MAINTAINING
	if (reset) begin
		walker2In<=`GOLOBAL_DATA_BUS_WIDTH_CONFIG'd 0;
	end else begin
		if(regTransferDst==REG_TRANS_DST_WALKER2) begin
			walker2In<=selectedForRegTransfer;
		end
	end
end
always @ (posedge clk or posedge reset ) begin :WALKER3_MAINTAINING
	if (reset) begin
		walker3In<=`GOLOBAL_DATA_BUS_WIDTH_CONFIG'd 0;
	end else begin
		if(regTransferDst==REG_TRANS_DST_WALKER3)begin
			walker3In<=selectedForRegTransfer;
		end
	end
end

always @ (posedge clk or posedge reset ) begin : TEMP_REG_A_MAINTAIN
	if (reset) begin
		temp_regA<=0;
	end else begin
		if (load_temp_regA) begin
			temp_regA<=global_data_bus;
		end else begin
			if(regTransferDst==REG_TRANS_DST_REG_A)begin
				temp_regA<=selectedForRegTransfer;
			end
		end
	end 
end

always @ (posedge clk or posedge reset) begin : TEMP_REG_B_MAINTAIN
	if (reset) begin
		temp_regB<=0;
	end else begin
		if (load_temp_regB) begin
			temp_regB<=global_data_bus;
		end
	end 
end
always @ (posedge clk or posedge reset ) begin : TEMP_REG_C_MAINTAIN
	if (reset) begin
		temp_regC<=0;
	end else begin
		if (load_temp_regC) begin
			temp_regC<=global_data_bus;
		end
	end 
end

endmodule // End of Module controller




