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

    output          mirrorStep_valid_o,
    output  [31:0]  mirrorStep_o
);

reg             fp_2_a_tvalid;
wire            fp_2_result_tvalid;
wire    [31:0]  fp_2_result_tdata;

reg             fp_1800_a_tvalid;
wire            fp_1800_result_tvalid;
wire    [31:0]  fp_1800_result_tdata;

wire            fp_step_mul_result_tvalid;
wire    [31:0]  fp_step_mul_result_tdata;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        fp_2_a_tvalid       <= 1'b0;
        fp_1800_a_tvalid    <= 1'b0;
    end
    else begin  
        fp_2_a_tvalid       <= 1'b1;
        fp_1800_a_tvalid    <= 1'b1;
    end
end

fp_2 fp_2 (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_2_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(32'd2),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(fp_2_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_2_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_1800 fp_1800 (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_1800_a_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata((POINTS_PER_LINE_P*NUMBER_OF_FRAMES_P) - 1),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(fp_1800_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_1800_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_step_mul fp_step_mul (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_2_result_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_2_result_tdata),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(thetaM_valid_i),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(thetaM_i),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(fp_step_mul_result_tvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(fp_step_mul_result_tdata)    // output wire [31 : 0] m_axis_result_tdata
);

fp_step_div fp_step_div (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_step_mul_result_tvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_step_mul_result_tdata),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(fp_1800_result_tvalid),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(fp_1800_result_tdata),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(mirrorStep_valid_o),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(mirrorStep_o)    // output wire [31 : 0] m_axis_result_tdata
);

endmodule
