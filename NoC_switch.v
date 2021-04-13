

`include "./config.h"
module NoC_switch #(
parameter GOLOBAL_DATA_BUS_WIDTH=`GOLOBAL_DATA_BUS_WIDTH_CONFIG,
parameter LAYER_ID_WIDTH=`LAYER_ID_WIDTH_CONFIG,
parameter SWITCH_ID_WIDTH=`SWITCH_ID_WIDTH_CONFIG,
parameter SWITCH_STATE_WIDTH=`SWITCH_STATE_WIDTH_CONFIG,
parameter THIS_SWITCH_ID=`SWITCH_ID_WIDTH_CONFIG'd 0,
parameter SWITCH_ID_END=GOLOBAL_DATA_BUS_WIDTH-1-LAYER_ID_WIDTH,
parameter SWITCH_ID_START=GOLOBAL_DATA_BUS_WIDTH-1-LAYER_ID_WIDTH-SWITCH_ID_WIDTH,
parameter NO_ONE=2'b10,
parameter SELF=2'b01,
parameter OTHER=2'b10,

//--------
parameter  SWITCH_STATE_INDEX=`SWITCH_STATE_WIDTH_CONFIG'd 0,
parameter  SWITCH_STATE_DATA=`SWITCH_STATE_WIDTH_CONFIG'd 1

)
(
input logic clk,
input logic reset,

input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  selfData, //self input coming from lower subarray

input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  rightData,


//-----------
input logic selfReq,
input logic rightReq,


//-------
output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] selfOut,

output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] leftOut,


//------
output logic  grat2self,
output logic   selfOutputReq,
output logic   leftOutputReq
);
//----------------------------
	
logic [`SWITCH_STATE_WIDTH_CONFIG-1:0] cur_switch_state;
logic [`SWITCH_STATE_WIDTH_CONFIG-1:0] nxt_switch_state;

logic [GOLOBAL_DATA_BUS_WIDTH-1:0] selectedInput;
logic [GOLOBAL_DATA_BUS_WIDTH-1:0] selectedOutput;

logic [1:0]selectedInputID;
logic [1:0]selectedOutputID;

always @ (posedge clk or posedge reset) begin : CUR_STATE_MAINTAINACE
	if (reset) begin
		cur_switch_state <= SWITCH_STATE_INDEX;
	end else  begin
		cur_switch_state <=nxt_switch_state;
	end
end

always @ (posedge clk ) begin : NXT_STATE_MAINTAINACE
	if (selfReq | rightReq ) begin
		nxt_switch_state <=SWITCH_STATE_DATA ;
	end else  begin
		cur_switch_state <=SWITCH_STATE_INDEX;
	end
end
always @ (posedge clk ) begin : SELECTED_OUTPUT_ID_MAINTAIN
	if (selfReq | rightReq ) begin
		if (cur_switch_state==SWITCH_STATE_INDEX ) begin
			if(selectedInput[SWITCH_ID_END:SWITCH_ID_START ]==THIS_SWITCH_ID) begin
				selectedOutputID=SELF;
			end else begin
				selectedOutputID=OTHER;
			end
		end
	end else begin
		selectedOutputID=NO_ONE;
	end
end
always_comb begin
	if(selectedOutputID==OTHER) begin
		selectedInput <=OTHER;
	end else begin
		selectedInput <=SELF;
	end
end	
	
assign grat2self= (selectedOutputID==SELF) ? 1'b1:1'b0;
assign selfOut = (selectedOutputID==SELF ) ? selectedInput:0;
assign leftOut = (selectedOutputID==OTHER ) ? selectedInput:0;

assign   selfOutputReq=(selectedOutputID==SELF ) ? 1'b1:1'b0;
assign   leftOutputReq=(selectedOutputID==OTHER ) ?1'b1:1'b0;


endmodule


