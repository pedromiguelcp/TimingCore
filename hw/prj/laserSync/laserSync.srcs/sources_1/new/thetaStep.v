`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 02:13:46 PM
// Design Name: 
// Module Name: thetaStep
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


module thetaStep #(
    parameter   THETAMAX_P          = 9,
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    localparam  TOTAL_POINTS_P      = POINTS_PER_LINE_P*NUMBER_OF_FRAMES_P
)(
    input           clk_i,
    input           nrst_i,
    input           theta_iteration_valid_i,
    input   [15:0]  theta_iteration_i,

    output          thetaM_valid_o,
    output  [31:0]  thetaM_o,
    output          thetaStep_valid_o,
    output  [31:0]  thetaStep_o
);

wire        thetaM_ready_w;
wire [31:0] thetaM_w;
wire        thetaM_ovr_w;

wire [38:0] mirrorStepDiv_quo_w;
wire        mirrorStepDiv_ready_w;
wire        mirrorStepDiv_ovr_w;

wire        mirrorStep_ovr_w;

assign thetaM_o         = thetaM_w;
assign thetaM_valid_o   = thetaM_ready_w;

//5b for thetaMAX (0-31) which is 9 for now
fixed_mul #(27,32) mul_uut (//thetaM (thetaMAX*pi/180)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(1'b1),
    .opA_i({THETAMAX_P[4:0], 27'd0}), 
    .opB_i(32'b00000_000001000111011111010000000), 
    .ready_o(thetaM_ready_w),
    .result_o(thetaM_w),
    .overflow_o(thetaM_ovr_w)
);

fixed_div #(27,39) div_uut (//2/(TOTAL_POINTS_P-1)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(1'b1), 
    .opA_i({10'd0, 2'b10, 27'd0}), 
    .opB_i({TOTAL_POINTS_P[11:0] - 1'b1, 27'd0}), 
    .ready_o(mirrorStepDiv_ready_w),
    .result_o(mirrorStepDiv_quo_w),
    .overflow_o(mirrorStepDiv_ovr_w)
);

fixed_mul #(27,32) mul_uut2 (//mirrorStep (thetaM*(2/(TOTAL_POINTS_P-1)) )
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_ready_w & mirrorStepDiv_ready_w),
    .opA_i(mirrorStepDiv_quo_w[31:0]), 
    .opB_i(thetaM_w), 
    .ready_o(thetaStep_valid_o),
    .result_o(thetaStep_o),
    .overflow_o(mirrorStep_ovr_w)
);


//0.0001735687255859375(1)
//0.00017458200454711914(2)
//(3)
//0.000174629953108
//melhorar o codigo dos módulos de mul/div/add/sub
//ver se está sintetizavel
//criar um novo ip para meter thetaStep com output o step e o thetaM
//testar o resultado nos tickes
//aumentar resolução se a diferença for significativa
/*******************************/

endmodule
