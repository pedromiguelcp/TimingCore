`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: activePixelMem
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

module activePixelMem(
    input           clk_i,
    input   [10:0]  waddr_i,
    input           wdata_i,
    input           wen_i,
    input           mem_selector_i,
    input   [10:0]  raddr_i,
    output          active_pixel_o
);

wire    [1:0]   active_pixel_w;
wire    [1:0]   wen_w;

assign wen_w = (mem_selector_i) ?   {wen_i, 1'b0}   :   {1'b0, wen_i};
assign active_pixel_o = (mem_selector_i)    ?   active_pixel_w[0]   :   active_pixel_w[1];

genvar i;
generate
    for(i = 0; i < 2; i = i + 1) begin: activePixelMem
        activePixelBRAM activePixelBRAM_inst(
            .clka(clk_i),
            .addra(waddr_i),
            .dina(wdata_i),
            .wea(wen_w[i]),
            .clkb(clk_i),
            .addrb(raddr_i),
            .doutb(active_pixel_w[i])            
        );
    end
endgenerate

endmodule