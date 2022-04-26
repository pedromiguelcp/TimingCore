`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2022 11:57:09 AM
// Design Name: 
// Module Name: thetaSin
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

//sqr(1-x^2)
module thetaSin(
    input           clk_i,
    input           nrst_i,
    input           thetaCos_valid_i,
    input   [33:0]  thetaCos_i,

    output          thetaSin_valid_o,
    output  [33:0]  thetaSin_o
);

wire        squared_thetaCos_ready_w;
wire [33:0] squared_thetaCos_w;

wire        pre_thetaSin_ready_w;
wire [33:0] pre_thetaSin_w;


fixed_mul #(32,34) mul_uut (//thetaCos_i^2
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaCos_valid_i),
    .opA_i(thetaCos_i), 
    .opB_i(thetaCos_i), 
    .ready_o(squared_thetaCos_ready_w),
    .result_o(squared_thetaCos_w)
);

fixed_sub #(32,34) sub_uut (//1-(thetaCos_i^2)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(squared_thetaCos_ready_w),
    .opA_i({2'd1, 32'd0}), 
    .opB_i(squared_thetaCos_w), 
    .ready_o(pre_thetaSin_ready_w),
    .result_o(pre_thetaSin_w)
);

fixed_sqrt #(32,34) fixed_sqrt_uut (//sqrt(1-(thetaCos_i^2))
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(pre_thetaSin_ready_w),    
    .opA_i(pre_thetaSin_w), 
    .ready_o(thetaSin_valid_o),   
    .result_o(thetaSin_o)
);


endmodule
