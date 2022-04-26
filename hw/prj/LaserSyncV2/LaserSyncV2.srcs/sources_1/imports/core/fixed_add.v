`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 11:27:20 PM
// Design Name: 
// Module Name: fixed_add
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


module fixed_add #(
    parameter Q = 16,
    parameter N = 32
)(
    input           clk_i,
    input           nrst_i,
    input           valid_i,
    input   [N-1:0] opA_i,
    input   [N-1:0] opB_i,

    output          ready_o,
    output  [N-1:0] result_o
);

reg [N-1:0] result_r;
reg         ready_r;

assign ready_o  = ready_r;
assign result_o = result_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        result_r    <= 0;
        ready_r     <= 1'b0;
    end
    else begin
        if(valid_i)begin
            result_r[N-2:0] <= opA_i[N-2:0] + opB_i[N-2:0];
            result_r[N-1]   <= opA_i[N-1];
            ready_r         <= 1'b1;
        end
        else begin
            ready_r         <= 1'b0;
        end
    end
end

endmodule