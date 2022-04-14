`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2022 03:21:57 PM
// Design Name: 
// Module Name: cordicManager
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


module cordicManager #(
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   THETAMAX_P          = 9
)(
    input           clk_i,
    input           nrst_i,
    input   [23:0]  freq_i,

    output          dt_Ticks_valid_o,
    output  [15:0]  dt_Ticks_o
);

reg             cordic_tvalid;
wire            cordic_dout_tvalid_w;
wire [15:0]     cordic_dout_tdata_w;


always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        cordic_tvalid <= 1'b0;
    end
    else begin
        cordic_tvalid <= 1'b1;
    end
end

cordic cordicCore_uut (
  .aclk(clk_i),                                        // input wire aclk
  .aresetn(nrst_i),                                  // input wire aresetn
  .s_axis_cartesian_tvalid(cordic_tvalid),  // input wire s_axis_cartesian_tvalid
  //.s_axis_cartesian_tdata({6'b0, 10'b0010000000, 6'b0, 10'b0010100000}),    // input wire [31 : 0] s_axis_cartesian_tdata
  .s_axis_cartesian_tdata({16'b0000001100000100, 16'b0011111111101101}), // first step of cordic verified w/ arctang
  .m_axis_dout_tvalid(cordic_dout_tvalid_w),            // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(cordic_dout_tdata_w)              // output wire [15 : 0] m_axis_dout_tdata
);



thetaTangent  #(
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P),
    .THETAMAX_P(THETAMAX_P)
) thetaTangent_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .thetaM_valid_i(thetaM_valid_w),
    .thetaM_i(thetaM_w),

    .mirrorStep_valid_o(mirrorStep_valid_w),
    .mirrorStep_o(mirrorStep_w)
);

endmodule
