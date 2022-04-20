`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2022 11:38:24 AM
// Design Name: 
// Module Name: mirrorStep
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


module mirrorStep #(
  parameter   POINTS_PER_LINE_P   = 360,
  parameter   NUMBER_OF_FRAMES_P  = 5
)(
  input           clk_i,
  input           nrst_i,
  input           thetaM_valid_i,
  input   [31:0]  thetaM_i,
  input           theta_iteration_valid_i,
  input   [15:0]  theta_iteration_i,

  output          thetaStep_it_valid_o,
  output  [31:0]  thetaStep_it_o
);

reg             fp_points_a_tvalid_r;
wire            fp_points_result_tvalid_w;
wire    [31:0]  fp_points_result_tdata_w;

wire            fp_step_mul_result_tvalid_w;
wire    [31:0]  fp_step_mul_result_tdata_w;

wire            mirrorStep_valid_w;
wire    [31:0]  mirrorStep_w;

wire            fp_theta_it_result_tvalid_w;
wire [31:0]     fp_theta_it_result_tdata_w;

always @(posedge clk_i or negedge nrst_i) begin
  if(~nrst_i) begin
    fp_points_a_tvalid_r    <= 1'b0;
  end
  else begin  
    fp_points_a_tvalid_r    <= 1'b1;
  end
end

//theta_iteration_i*mirrorStep_w
fp_mult fp_theta_step_mul (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(fp_theta_it_result_tvalid_w),             
  .s_axis_a_tdata(fp_theta_it_result_tdata_w),         
  .s_axis_b_tvalid(mirrorStep_valid_w),         
  .s_axis_b_tdata(mirrorStep_w),              
  .m_axis_result_tvalid(thetaStep_it_valid_o),
  .m_axis_result_tdata(thetaStep_it_o)    
);

//theta_iteration_i fp format
fp_uint32_to_float fp_theta_it (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                           
  .s_axis_a_tvalid(theta_iteration_valid_i),           
  .s_axis_a_tdata({16'b0, theta_iteration_i}), 
  .m_axis_result_tvalid(fp_theta_it_result_tvalid_w), 
  .m_axis_result_tdata(fp_theta_it_result_tdata_w)   
);

fp_mult fp_step_mul (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(1'b1),             
  .s_axis_a_tdata(32'h40000000),  // 2 in fp format           
  .s_axis_b_tvalid(thetaM_valid_i),         
  .s_axis_b_tdata(thetaM_i),              
  .m_axis_result_tvalid(fp_step_mul_result_tvalid_w),
  .m_axis_result_tdata(fp_step_mul_result_tdata_w)    
);

fp_uint32_to_float fp_points (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                           
  .s_axis_a_tvalid(fp_points_a_tvalid_r),           
  .s_axis_a_tdata((POINTS_PER_LINE_P*NUMBER_OF_FRAMES_P) - 1), 
  .m_axis_result_tvalid(fp_points_result_tvalid_w), 
  .m_axis_result_tdata(fp_points_result_tdata_w)   
);

fp_div fp_step_div (
  .aclk(clk_i),                                   
  .aresetn(nrst_i),                            
  .s_axis_a_tvalid(fp_step_mul_result_tvalid_w),          
  .s_axis_a_tdata(fp_step_mul_result_tdata_w),         
  .s_axis_b_tvalid(fp_points_result_tvalid_w),           
  .s_axis_b_tdata(fp_points_result_tdata_w),              
  .m_axis_result_tvalid(mirrorStep_valid_w),  
  .m_axis_result_tdata(mirrorStep_w)    
);

endmodule
