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
    input           theta_iteration_valid_i,
    input   [15:0]  theta_iteration_i,

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

wire            fp_sin_mul_result_tvalid_w;
wire [31:0]     fp_sin_mul_result_tdata_w;
wire            fp_sin_sub_result_tvalid_w;
wire [31:0]     fp_sin_sub_result_tdata_w;
wire            fp_sin_sqrt_result_tvalid_w;
wire [31:0]     fp_sin_sqrt_result_tdata_w;


//thetaCos_o fixed-point format
fp_CosSin_to_fixed Cos_fixedPoint (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                           
  .s_axis_a_tvalid(fp_thetaStep_div_result_tvalid_w),          
  .s_axis_a_tdata(fp_thetaStep_div_result_tdata_w),             
  .m_axis_result_tvalid(thetaCos_valid_o), 
  .m_axis_result_tdata(thetaCos_o)    // output wire [15 : 0] m_axis_result_tdata
);

//thetaSin_o fixed-point format
fp_CosSin_to_fixed Sin_fixedPoint (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                           
  .s_axis_a_tvalid(fp_sin_sqrt_result_tvalid_w),          
  .s_axis_a_tdata(fp_sin_sqrt_result_tdata_w),             
  .m_axis_result_tvalid(thetaSin_valid_o), 
  .m_axis_result_tdata(thetaSin_o)    // output wire [15 : 0] m_axis_result_tdata
);


//thetaSin_o floating-point format
fp_sqrt fp_sin_sqrt (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                         
  .s_axis_a_tvalid(fp_sin_sub_result_tvalid_w),            
  .s_axis_a_tdata(fp_sin_sub_result_tdata_w),              
  .m_axis_result_tvalid(fp_sin_sqrt_result_tvalid_w),  
  .m_axis_result_tdata(fp_sin_sqrt_result_tdata_w)    
);

fp_sub fp_sin_sub (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(1'b1),         
  .s_axis_a_tdata(32'h3f800000),   // 1 in fp format          
  .s_axis_b_tvalid(fp_sin_mul_result_tvalid_w),        
  .s_axis_b_tdata(fp_sin_mul_result_tdata_w),          
  .m_axis_result_tvalid(fp_sin_sub_result_tvalid_w),
  .m_axis_result_tdata(fp_sin_sub_result_tdata_w)   
);

fp_mult fp_sin_mul (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(fp_thetaStep_div_result_tvalid_w),             
  .s_axis_a_tdata(fp_thetaStep_div_result_tdata_w),       
  .s_axis_b_tvalid(fp_thetaStep_div_result_tvalid_w),         
  .s_axis_b_tdata(fp_thetaStep_div_result_tdata_w),              
  .m_axis_result_tvalid(fp_sin_mul_result_tvalid_w),
  .m_axis_result_tdata(fp_sin_mul_result_tdata_w)    
);

//thetaCos_o floating-point format
fp_div fp_thetaStep_div (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(fp_thetaStep_sub_result_tvalid_w),     
  .s_axis_a_tdata(fp_thetaStep_sub_result_tdata_w),       
  .s_axis_b_tvalid(thetaM_valid_w),         
  .s_axis_b_tdata(thetaM_w),              
  .m_axis_result_tvalid(fp_thetaStep_div_result_tvalid_w),
  .m_axis_result_tdata(fp_thetaStep_div_result_tdata_w)   
);

fp_sub fp_thetaStep_sub (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(thetaM_valid_w),         
  .s_axis_a_tdata(thetaM_w),             
  .s_axis_b_tvalid(mirrorStep_valid_w),        
  .s_axis_b_tdata(mirrorStep_w),          
  .m_axis_result_tvalid(fp_thetaStep_sub_result_tvalid_w),
  .m_axis_result_tdata(fp_thetaStep_sub_result_tdata_w)   
);


/*mirrorStep  #(
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P)
) mirrorStep_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .thetaM_valid_i(thetaM_valid_w),
    .thetaM_i(thetaM_w),
    .theta_iteration_valid_i(theta_iteration_valid_i),
    .theta_iteration_i(theta_iteration_i),

    .thetaStep_it_valid_o(mirrorStep_valid_w),
    .thetaStep_it_o(mirrorStep_w)
);*/

thetaStep  #(//mandar para fora o thetaM e thetaM-step com base na iteração
    .THETAMAX_P(THETAMAX_P),
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P)
) thetaStep_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .theta_iteration_valid_i(theta_iteration_valid_i),
    .theta_iteration_i(theta_iteration_i),

    .thetaM_valid_o(thetaM_valid_w),
    .thetaM_o(thetaM_w),
    .thetaStep_valid_o(mirrorStep_valid_w),
    .thetaStep_o(mirrorStep_w)
);

/*thetaM  #(
    .THETAMAX_P(THETAMAX_P),
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P)
) thetaM_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .thetaM_valid_o(thetaM_valid_w),
    .thetaM_o(thetaM_w)
);*/
endmodule
