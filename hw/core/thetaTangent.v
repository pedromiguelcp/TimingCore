`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2022 04:47:33 PM
// Design Name: 
// Module Name: thetaTangent
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

//input thetaM and thetaStep
//output both cos and sin for the cordic IP
module thetaTangent #(
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   THETAMAX_P          = 9
)(
    input           clk_i,
    input           nrst_i,
    input           theta_iteration_i,

    output          thetaCos_valid_o,
    output          thetaSin_valid_o,
    output  [15:0]  thetaCos_o,
    output  [15:0]  thetaSin_o
);

wire            thetaM_valid_w;
wire [31:0]     thetaM_w;
wire            mirrorStep_valid_w;
wire [31:0]     mirrorStep_w;
wire            fp_thetaStep_sub_result_tvalid_w;
wire [31:0]     fp_thetaStep_sub_result_tdata_w;
wire            fp_thetaStep_div_result_tvalid_w;
wire [31:0]     fp_thetaStep_div_result_tdata_w;

 
//thetaCos_o floating-point format
fp_thetaStep_div fp_thetaStep_div (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_thetaStep_sub_result_tvalid_w),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_thetaStep_sub_result_tdata_w),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(thetaM_valid_i),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(thetaM_i),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(fp_thetaStep_div_result_tvalid_w),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_thetaStep_div_result_tdata_w)    // output wire [31 : 0] m_axis_result_tdata
);

fp_thetaStep_sub fp_thetaStep_sub (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(thetaM_valid_i),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(thetaM_i),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(mirrorStep_valid_i),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(mirrorStep_i),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(fp_thetaStep_sub_result_tvalid_w),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_thetaStep_sub_result_tdata_w)    // output wire [31 : 0] m_axis_result_tdata
);

mirrorStep  #(
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P)
) mirrorStep_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .thetaM_valid_i(thetaM_valid_w),
    .thetaM_i(thetaM_w),

    .mirrorStep_valid_o(mirrorStep_valid_w),
    .mirrorStep_o(mirrorStep_w)
);

thetaM  #(
    .THETAMAX_P(THETAMAX_P)
) thetaM_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .thetaM_valid_o(thetaM_valid_w),
    .thetaM_o(thetaM_w)
);
endmodule
