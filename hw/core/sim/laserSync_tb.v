`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2022 04:30:45 PM
// Design Name: 
// Module Name: laserSync_tb
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


module laserSync_tb #
(
    parameter   SYSCLOCK_P          = 500000000, //500MHz
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   LINES_PER_FRAME_P   = 100,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   MEM_CYCLES_P        = 100,
    parameter   PULSE_LENGTH_P      = 5,
    parameter   THETAMAX_P          = 9,
    parameter   MIRROR_FREQ_P       = 10800,
    localparam  SYS_MIRROR_RATIO_P  = (SYSCLOCK_P/MIRROR_FREQ_P)
)();

reg         clk_r, nrst_r, zc_r;
reg [15:0]  cnt_clock_tick_r;
wire        laser_trigger_w;

initial begin
    $display("\n\n**************LASER SYNC tb********************\n");

    clk_r   = 0;
    nrst_r  = 0;


    #10 // 5clk cycles
    nrst_r  = 1;
end

always #1 clk_r = ~clk_r; // 500MHz

always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        cnt_clock_tick_r    <= 16'd0;
        zc_r                <= 0;
    end
    else begin
        if(cnt_clock_tick_r < SYS_MIRROR_RATIO_P)begin
            cnt_clock_tick_r <= cnt_clock_tick_r + 1'b1;
        end
        else begin
            cnt_clock_tick_r <= 16'd0;
            zc_r <= ~zc_r;
        end
    end
end

laserSynchronizer #(
    .SYSCLOCK_P(SYSCLOCK_P),
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .LINES_PER_FRAME_P(LINES_PER_FRAME_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P),
    .MEM_CYCLES_P(MEM_CYCLES_P),
    .PULSE_LENGTH_P(PULSE_LENGTH_P),
    .THETAMAX_P(THETAMAX_P)
) LS_uut
(
    .clk_i(clk_r),
    .nrst_i(nrst_r),
    .zc_i(zc_r),
    .freq_i(SYS_MIRROR_RATIO_P),

    .laser_trigger_o(laser_trigger_w)
);

endmodule
