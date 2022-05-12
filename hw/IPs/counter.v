`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: counter
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


module counter(
    input           clk_i,
    input           nrst_i,
    input           en_i,
    output  [15:0]  cnt_o
);

reg [15:0]  cnt_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        cnt_r <= 16'h0000;
    end
    else if(en_i) begin
        cnt_r <= cnt_r + 1'b1;
    end
    else begin
        cnt_r <= 16'h0000;
    end
end

assign cnt_o = cnt_r;

endmodule
