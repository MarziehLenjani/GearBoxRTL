module shifter #(
parameter GOLOBAL_DATA_BUS_WIDTH=32
)
(

input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  input1,
 
//-------
output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] output1
);
//----------------------------
assign output1=input1 <<1;

endmodule

