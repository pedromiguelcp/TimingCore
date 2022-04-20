`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 11:23:20 AM
// Design Name: 
// Module Name: fixed_mul
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


module fixed_mul #(
    parameter Q = 15,
    parameter N = 32
)(
    input           clk_i,
    input           nrst_i,
    input           valid_i,
    input   [N-1:0]	opA_i,
    input   [N-1:0]	opB_i,

    output          ready_o,
    output  [N-1:0]	result_o,
    output	        overflow_o
);

reg [2*N-1:0]	result_r;
reg             ready_r;

assign overflow_o   = (result_r[(2*N)-2 : N-1+Q] > 0) ? 1'b1 : 1'b0;
assign result_o     = {(opA_i[N-1] ^ opB_i[N-1]), result_r[N-2+Q : Q]};
assign ready_o      = ready_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        result_r    <= 0;
        ready_r     <= 1'b0;
    end
    else begin
        if(valid_i)begin
            result_r    <= opA_i[N-2:0] * opB_i[N-2:0];
            ready_r     <= 1'b1;
        end
        else begin
            ready_r     <= 1'b0;
        end
    end
end


endmodule
