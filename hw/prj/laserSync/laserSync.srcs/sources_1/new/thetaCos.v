`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2022 11:57:09 AM
// Design Name: 
// Module Name: thetaCos
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


module thetaCos #(
    parameter   THETAMAX_P          = 9,
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    localparam  TOTAL_POINTS_P      = POINTS_PER_LINE_P*NUMBER_OF_FRAMES_P
)(
    input           clk_i,
    input           nrst_i,
    input           theta_iteration_valid_i,
    input   [11:0]  theta_iteration_i,

    output          thetaCos_valid_o,
    output  [31:0]  thetaCos_o
);

reg         thetaM_valid_r;
wire        thetaM_ready_w;
wire [31:0] thetaM_w;
wire        thetaM_ovr_w;

reg         mirrorStepPoints_valid_r;
wire        mirrorStepPoints_ready_w;
wire [38:0] mirrorStepPoints_w;
wire        mirrorStepPoints_ovr_w;

wire        mirrorStep_ready_w;
wire [31:0] mirrorStep_w;
wire        mirrorStep_ovr_w;

wire        thetaItStep_ready_w;
wire [38:0] thetaItStep_w;
wire        thetaItStep_ovr_w;

wire        thetaStep_valid_w;
wire [31:0] thetaStep_w;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        thetaM_valid_r              <= 1'b0;
        mirrorStepPoints_valid_r    <= 1'b0;
    end
    else begin
        thetaM_valid_r              <= 1'b1;
        mirrorStepPoints_valid_r    <= 1'b1;
    end
end

//5b for thetaMAX (0-31) which is 9 for now
fixed_mul #(27,32) mul_uut (//thetaM (thetaMAX*pi/180)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_valid_r),
    .opA_i({THETAMAX_P[4:0], 27'd0}), 
    .opB_i(32'b00000_000001000111011111010000000), 
    .ready_o(thetaM_ready_w),
    .result_o(thetaM_w),
    .overflow_o(thetaM_ovr_w)
);

fixed_div #(27,39) div_uut (//2/(TOTAL_POINTS_P-1)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(mirrorStepPoints_valid_r), 
    .opA_i({10'd0, 2'b10, 27'd0}), 
    .opB_i({TOTAL_POINTS_P[11:0] - 1'b1, 27'd0}), 
    .ready_o(mirrorStepPoints_ready_w),
    .result_o(mirrorStepPoints_w),
    .overflow_o(mirrorStepPoints_ovr_w)
);

fixed_mul #(27,32) mul_uut2 (//mirrorStep (thetaM*(2/(TOTAL_POINTS_P-1)) )
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_ready_w & mirrorStepPoints_ready_w),
    .opA_i(mirrorStepPoints_w[31:0]), 
    .opB_i(thetaM_w), 
    .ready_o(mirrorStep_ready_w),
    .result_o(mirrorStep_w),
    .overflow_o(mirrorStep_ovr_w)
);

fixed_mul #(27,39) mul_uut3 (//thetaIt*mirrorStep
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(mirrorStep_ready_w & theta_iteration_valid_i),
    .opA_i({theta_iteration_i, 27'd0}), 
    .opB_i({7'd0, mirrorStep_w}), 
    .ready_o(thetaItStep_ready_w),
    .result_o(thetaItStep_w),
    .overflow_o(thetaItStep_ovr_w)
);

fixed_sub #(27,32) sub_uut (//thetaM-(thetaIt*mirrorStep)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_ready_w & thetaItStep_ready_w),
    .opA_i(thetaM_w), 
    .opB_i(thetaItStep_w[31:0]), 
    .ready_o(thetaStep_valid_w),
    .result_o(thetaStep_w)
);

fixed_div #(27,32) div_uut (//(thetaM-(thetaIt*mirrorStep)) / thetaM
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaStep_valid_w&thetaM_ready_w), 
    .opA_i(thetaStep_w), 
    .opB_i(thetaM_w), 
    .ready_o(mirrorStepPoints_ready_w),
    .result_o(mirrorStepPoints_w),
    .overflow_o(mirrorStepPoints_ovr_w)
);
//dividir pelo thethaM e mandar isso para fora em vez do thetaStep

//0.0001735687255859375(1)
//0.00017458200454711914(2)
//0.00017462670803070068(3)
//testar o resultado nos tickes
//aumentar resolução se a diferença for significativa
/*******************************/

endmodule
