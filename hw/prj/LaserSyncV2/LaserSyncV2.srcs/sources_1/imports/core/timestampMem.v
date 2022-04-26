`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: timestampMem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module timestampMem(
    input           clk_i,
    input   [10:0]  waddr_i,
    input   [15:0]  wdata_i,
    input           wen_i,
    input           mem_selector_i, //SELECTS WHICH IS THE MEMORY BEING UPDATED
    input   [10:0]  raddr_i,
    output  [15:0]  timestamp_o
);

wire    [15:0]  dout_w [0:1];
wire    [1:0]   wen_w;

assign timestamp_o = (mem_selector_i)   ?   dout_w[0]   :   dout_w[1];
assign wen_w = (mem_selector_i) ?   {wen_i, 1'b0}   :   {1'b0, wen_i};

genvar i;
generate
    for(i = 0; i < 2; i = i + 1) begin: timestampMem
        timestampBRAM timestampBRAM_inst(
            .clka(clk_i),
            .wea(wen_w[i]),
            .addra(waddr_i),
            .dina(wdata_i),
            .clkb(clk_i),
            .addrb(raddr_i),
            .doutb(dout_w[i])
        );
    end
endgenerate

endmodule