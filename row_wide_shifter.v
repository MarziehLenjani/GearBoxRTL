module row_wide_shifter #(
parameter GOLOBAL_DATA_BUS_WIDTH=32,
parameter NUM_OF_COL_IN_ROW=64
)
(
input clk,
input logic loadRow,
input logic  [NUM_OF_COL_IN_ROW-1:0] [GOLOBAL_DATA_BUS_WIDTH-1:0] inputRow,
input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  inputColumn,
input logic shiftSignal,
input logic shiftDir_read_or_write, //0 read, write 1 
//-------
output logic [NUM_OF_COL_IN_ROW-1:0]  [GOLOBAL_DATA_BUS_WIDTH-1:0]  outputRow,
output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] outputColumn
);
//----------------------------
logic [NUM_OF_COL_IN_ROW-1:0] [GOLOBAL_DATA_BUS_WIDTH-1:0] rowOfRegs ; //TODO: packed array, make sure the order of slicing is correct

assign outputRow=rowOfRegs;
assign outputColumn= rowOfRegs[0];
//-----------------------------------------------
always @(posedge clk ) begin
	if(loadRow)begin
		rowOfRegs=inputRow;
	end else begin
		if(shiftSignal) begin
			if(shiftDir_read_or_write)begin
				rowOfRegs={inputColumn,rowOfRegs[NUM_OF_COL_IN_ROW-1:1] };
			end else begin
				rowOfRegs={rowOfRegs[NUM_OF_COL_IN_ROW-1:1], inputRow[NUM_OF_COL_IN_ROW-1]}; // TODO: enable circular shift of two rows
			end
		end
	end
end
endmodule

