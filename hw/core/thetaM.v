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

reg             fp_pi_a_tvalid;
wire            fp_pi_result_tvalid;
wire    [31:0]  fp_pi_result_tdata;

reg             fp_thetaMAX_a_tvalid;
wire            fp_thetaMAX_result_tvalid;
wire    [31:0]  fp_thetaMAX_result_tdata;

reg             fp_180_a_tvalid;
wire            fp_180_result_tvalid;
wire    [31:0]  fp_180_result_tdata;

wire            fp_thetaM_mul_result_tvalid;
wire    [31:0]  fp_thetaM_mul_result_tdata;


always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        fp_pi_a_tvalid          <= 1'b0;
        fp_thetaMAX_a_tvalid    <= 1'b0;
        fp_180_a_tvalid         <= 1'b0;
    end
    else begin
        fp_pi_a_tvalid          <= 1'b1;
        fp_thetaMAX_a_tvalid    <= 1'b1;  
        fp_180_a_tvalid         <= 1'b1;
    end
end


fp_pi fp_pi (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_pi_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata({1'b0, 2'b11, 20'b00100100001111110111, 9'b0}),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(fp_pi_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_pi_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_thetaMAX fp_thetaMAX (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_thetaMAX_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(THETAMAX_P),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(fp_thetaMAX_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_thetaMAX_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_180 fp_180 (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_180_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(32'd180),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(fp_180_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_180_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_thetaM_mul fp_thetaM_mul (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_pi_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_pi_result_tdata),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(fp_thetaMAX_a_tvalid),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(fp_thetaMAX_result_tdata),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(fp_thetaM_mul_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_thetaM_mul_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_thetaM_div fp_thetaM_div (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_thetaM_mul_result_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_thetaM_mul_result_tdata),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(fp_180_result_tvalid),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(fp_180_result_tdata),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(thetaM_valid_o),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(thetaM_o)    // output wire [31 : 0] m_axis_result_tdata
);
endmodule
