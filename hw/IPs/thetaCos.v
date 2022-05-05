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
    parameter   [4:0]   THETAMAX_P      = 9,//up to 31
    parameter   [9:0]   FRAME_COLUMNS_P = 360,//up to 1023
    parameter   [2:0]   FRAME_NUMBER_P  = 5,//up to 7
    localparam  [11:0]  TOTAL_POINTS_P  = (FRAME_COLUMNS_P*FRAME_NUMBER_P)//up to 4095
)(
    input           clk_i,
    input           nrst_i,
    input           theta_iteration_valid_i,
    input   [11:0]  theta_iteration_i,

    output          thetaCos_valid_o,
    output  [33:0]  thetaCos_o
);

reg         thetaM_valid_r;
wire        thetaM_ready_w;
wire [36:0] thetaM_w;

reg         mirrorStepPoints_valid_r;
wire        mirrorStepPoints_ready_w;
wire [37:0] mirrorStepPoints_w;

wire        mirrorStep_ready_w;
wire [33:0] mirrorStep_w;

wire        thetaItStep_ready_w;
wire [47:0] thetaItStep_w;

wire        thetaStep_valid_w;
wire [33:0] thetaStep_w;

wire        thetaCos_ovr_w;

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


new_fixed_mul #(32,37) mul_uut (//thetaM (thetaMAX*pi/180)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_valid_r),
    .opA_i({THETAMAX_P, 32'd0}), 
    .opB_i({5'd0, 32'b00000100011101111101000110101000}), 
    .ready_o(thetaM_ready_w),
    .result_o(thetaM_w)
);

fixed_div #(26,38) div_uut (//2/(TOTAL_POINTS_P-1)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(mirrorStepPoints_valid_r), 
    .opA_i({12'd2, 26'd0}), 
    .opB_i({TOTAL_POINTS_P - 1'b1, 26'd0}), 
    .ready_o(mirrorStepPoints_ready_w),
    .result_o(mirrorStepPoints_w)
);

new_fixed_mul #(32,34) mul_uut2 (//mirrorStep (thetaM*(2/(TOTAL_POINTS_P-1)) )
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_ready_w & mirrorStepPoints_ready_w),
    .opA_i({mirrorStepPoints_w[27:0], 6'd0}), 
    .opB_i(thetaM_w[33:0]), 
    .ready_o(mirrorStep_ready_w),
    .result_o(mirrorStep_w)
);

new_fixed_mul #(32,48) mul_uut3 (//thetaIt*mirrorStep
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(mirrorStep_ready_w & theta_iteration_valid_i),
    .opA_i({4'd0, theta_iteration_i, 32'd0}), 
    .opB_i({14'd0, mirrorStep_w}), 
    .ready_o(thetaItStep_ready_w),
    .result_o(thetaItStep_w)
);

fixed_sub #(32,34) sub_uut (//thetaM-(thetaIt*mirrorStep)
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaM_ready_w & thetaItStep_ready_w),
    .opA_i(thetaM_w[33:0]), 
    .opB_i(thetaItStep_w[33:0]), 
    .ready_o(thetaStep_valid_w),
    .result_o(thetaStep_w)
);

fixed_div #(32,34) div_uut1 (//(thetaM-(thetaIt*mirrorStep)) / thetaM
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .valid_i(thetaStep_valid_w&thetaM_ready_w), 
    .opA_i(thetaStep_w), 
    .opB_i(thetaM_w[33:0]), 
    .ready_o(thetaCos_valid_o),
    .result_o(thetaCos_o)
);

endmodule
