module adder #(
parameter GOLOBAL_DATA_BUS_WIDTH=32
)
(
input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  input1,
input logic [GOLOBAL_DATA_BUS_WIDTH-1:0]  input2,
 
//-------
output logic [GOLOBAL_DATA_BUS_WIDTH-1:0] output1,
output logic equalFlag,
output logic lessFlag
);
//----------------------------
assign output1=  input1+input2 ;
assign equalFlag = (output1==0);
assign lessFlag =(output1>0);
endmodule

