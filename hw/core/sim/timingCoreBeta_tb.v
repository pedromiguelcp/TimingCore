`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2022 10:46:12 AM
// Design Name: 
// Module Name: timingCoreBeta_tb
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


module timingCoreBeta_tb #(
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    parameter   SYSCLOCK = 500000000 //500MHz
)();

    reg         clk_r, nrst_r, zc_r, we_r, mem_updated_r;
    reg [10:0]  waddr_r;
    reg [16:0]  wdata_r;
    reg [2:0]   memory_selector_r;
    reg [9:0]   points_per_line_r;
    reg [7:0]   lines_per_frame_r;
    reg [2:0]   number_of_frames_r;
    reg [7:0]   mem_cycles_r;
    reg [4:0]   pulse_length_r;
    reg [15:0]  quarter_mirror_cycle_delay_r;
    wire        update_mem_w, laser_trigger_w, line_completed_w;

    always @(posedge clk_r) begin
        $finish;
    end

    initial begin
        clk_r   = 0;
        nrst_r  = 0;
        zc_r    = 0;
    end

    always #5 clk_r = ~clk_r;


    timingCoreBeta uut(
        .clk_i(clk_r),
        .nrst_i(nrst_r),
        .zc_i(zc_r), // from mirror (signal when mirror passes in the center)
        .waddr_i(waddr_r), // address to write ticks in memory
        .wdata_i(wdata_r), // {dt_ticks [15:0], active_pixel [16:16]} 
        .we_i(we_r), // enable memory write (just send a singal?)
        .memory_selector_i(memory_selector_r), // select MEM0 | MEM1
        .mem_updated_i(mem_updated_r), // memory enable (enable switch between mems)
        .points_per_line_i(points_per_line_r), // 360
        .lines_per_frame_i(lines_per_frame_r), // 100
        .number_of_frames_i(number_of_frames_r), // 5
        .mem_cycles_i(mem_cycles_r), // 100 (maybe not needed)
        .pulse_length_i(pulse_length_r), // 5 (clock cycles "triggering" the laser beam)
        .quarter_mirror_cycle_delay_i(quarter_mirror_cycle_delay_r), // 12500 | 23148 (? clks from center to edge of mirror)
        
        .update_mem_o(update_mem_w), // update MEM0 | MEM1
        .laser_trigger_o(laser_trigger_w), // trigger lase beam
        .line_completed_o(line_completed_w) // pixels from current row done
    );

/*
a ideia aqui é fazer um test bench para a nova versão do TC
*/

endmodule
