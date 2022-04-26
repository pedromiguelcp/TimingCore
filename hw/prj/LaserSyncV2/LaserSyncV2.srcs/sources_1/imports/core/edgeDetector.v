`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: edgeDetector
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

module edgeDetector(
    input clk_i,
    input nrst_i,
    input signal_i,
    output edge_o
);

reg     [1:0]   signal_r;
reg             edge_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        signal_r    <=  2'b00;
        edge_r      <=  1'b0;
    end
    else begin
        signal_r[0] <=  signal_i;
        signal_r[1] <=  signal_r[0];
        edge_r      <=  (signal_r[0] & ~signal_r[1]) | (~signal_r[0] & signal_r[1]);
    end
end

assign edge_o = edge_r;

endmodule