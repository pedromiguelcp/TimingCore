`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2022 11:22:43 AM
// Design Name: 
// Module Name: thetaM
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


module thetaM #(
    parameter   THETAMAX_P  = 9
)(
    input           clk_i,
    input           nrst_i,

    output          thetaM_valid_o,
    output  [31:0]  thetaM_o
);

reg             fp_thetaMAX_a_tvalid_r;
wire            fp_thetaMAX_result_tvalid_w;
wire    [31:0]  fp_thetaMAX_result_tdata_w;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        fp_thetaMAX_a_tvalid_r    <= 1'b0;
    end
    else begin
        fp_thetaMAX_a_tvalid_r    <= 1'b1; 
    end
end

fp_uint32_to_float fp_thetaMAX (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                         
  .s_axis_a_tvalid(fp_thetaMAX_a_tvalid_r),            
  .s_axis_a_tdata(THETAMAX_P),              
  .m_axis_result_tvalid(fp_thetaMAX_result_tvalid_w),  
  .m_axis_result_tdata(fp_thetaMAX_result_tdata_w)    
);

fp_mult fp_thetaM_mul (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                            
  .s_axis_a_tvalid(fp_thetaMAX_result_tvalid_w),            
  .s_axis_a_tdata(fp_thetaMAX_result_tdata_w),         
  .s_axis_b_tvalid(1'b1),            
  .s_axis_b_tdata(32'h3c8efa35), // pi/180           
  .m_axis_result_tvalid(thetaM_valid_o),
  .m_axis_result_tdata(thetaM_o)   
);


endmodule
