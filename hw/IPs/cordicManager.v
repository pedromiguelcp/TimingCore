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
  parameter   FRAME_COLUMNS_P = 360,
  parameter   FRAME_NUMBER_P  = 5,
  parameter   THETAMAX_P      = 9
)(
  input           clk_i,
  input           nrst_i,
  input   [23:0]  freq_i,
  //input           edge_theta_valid_i,
  //input   [11:0]  edge_theta_i,
  input           theta_iteration_valid_i,
  input   [11:0]  theta_iteration_i,

  output          dt_Ticks_valid_o,
  output          next_dt_Ticks_o,
  output  [15:0]  dt_Ticks_o
);

reg         new_dtTick_r, next_dtTick_r;
reg [1:0]   dtTick_states_r;

wire        thetaCos_valid_w;
wire [33:0] thetaCos_w;
wire        thetaSin_valid_w;
wire [33:0] thetaSin_w;

wire        cordic_dout_tvalid_w;
wire [15:0] cordic_dout_tdata_w;

wire        pre_dtTicks_valid_w;
wire [31:0] pre_dtTicks_w;
wire        dtTicks_valid_w;
wire [38:0] dtTicks_w;

assign  dt_Ticks_valid_o  = new_dtTick_r;
assign  next_dt_Ticks_o   = next_dtTick_r;
assign  dt_Ticks_o        = dtTicks_w[35:20];


wire [15:0] cordic_cos_w;
wire [15:0] cordic_sin_w;
assign cordic_cos_w = thetaCos_w[33] ? {1'b1,~thetaCos_w[32:18] + 1'b1}:thetaCos_w[33:18];
assign cordic_sin_w = thetaSin_w[33:18];


/*wire [11:0] theta_iteration_w;
wire        theta_iteration_valid_w;
assign theta_iteration_w = edge_theta_valid_i ? edge_theta_i: theta_iteration_i;
assign theta_iteration_valid_w = edge_theta_valid_i | theta_iteration_valid_i;*/


//Check for new dt_tick
always @(posedge clk_i or negedge nrst_i) begin
  if(~nrst_i) begin
    dtTick_states_r <= 2'b00;
    new_dtTick_r    <= 1'b0;
    next_dtTick_r   <= 1'b0;
  end
  else begin 
    dtTick_states_r <= {dtTick_states_r[0], dtTicks_valid_w};
    new_dtTick_r    <= (dtTick_states_r[0] & ~dtTick_states_r[1]);
    next_dtTick_r   <= (~dtTick_states_r[0] & dtTick_states_r[1]);
  end
end


fixed_div #(20,39) div_uut(//arctang*freq_i/(2*pi)
  .clk_i(clk_i),
  .nrst_i(nrst_i),
  .valid_i(pre_dtTicks_valid_w), 
  .opA_i({pre_dtTicks_w, 7'd0}), 
  .opB_i({16'd0, 23'b11001001000011111101101}), //110.01001000011111101101
  .ready_o(dtTicks_valid_w),
  .result_o(dtTicks_w)
);

fixed_mul #(13,32) mul_uut(//arctang*freq_i
  .clk_i(clk_i),
  .nrst_i(nrst_i),
  .valid_i(cordic_dout_tvalid_w),
  .opA_i({16'd0, cordic_dout_tdata_w}),
  .opB_i({freq_i[18:0], 13'd0}), 
  .ready_o(pre_dtTicks_valid_w),
  .result_o(pre_dtTicks_w)
);

arcTan arcTan_uut(
  .clk_i(clk_i),
  .nrst_i(nrst_i),
  .valid_i(thetaCos_valid_w & thetaSin_valid_w),
  .cos_i(cordic_cos_w),
  .sin_i(cordic_sin_w),
  .phase_o(cordic_dout_tdata_w),
  .atang_valid_o(cordic_dout_tvalid_w)
);

//output thetaCos based on the mirror iteration step
thetaCos  #(
  .THETAMAX_P(THETAMAX_P),
  .FRAME_COLUMNS_P(FRAME_COLUMNS_P),
  .FRAME_NUMBER_P(FRAME_NUMBER_P)
) thetaCos_uut(
  .clk_i(clk_i),
  .nrst_i(nrst_i),
  .theta_iteration_valid_i(theta_iteration_valid_i),
  .theta_iteration_i(theta_iteration_i),

  .thetaCos_valid_o(thetaCos_valid_w),
  .thetaCos_o(thetaCos_w)
);

//output thetaSin
thetaSin  thetaSin_uut(
  .clk_i(clk_i),
  .nrst_i(nrst_i),
  .thetaCos_valid_i(thetaCos_valid_w),
  .thetaCos_i(thetaCos_w),

  .thetaSin_valid_o(thetaSin_valid_w),
  .thetaSin_o(thetaSin_w)
);

endmodule