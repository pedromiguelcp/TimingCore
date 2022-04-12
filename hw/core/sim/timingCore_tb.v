`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2022 10:30:20 AM
// Design Name: 
// Module Name: timingCore_tb
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


module timingCore_tb #(
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
    wire        update_mem_w;
    wire        laser_trigger_w, line_completed_w;

    reg [1:0]   update_mem_switch_r;
    reg         start_TC_r;
    reg [7:0]   cnt_lines_completed_r;

    initial begin
        $display("\n\n**************TIMING CORE tb********************\n");

        clk_r                           = 0;
        nrst_r                          = 0;
        memory_selector_r               = 3'b000; // 0-4 frame memories
        points_per_line_r               = 10'd360;
        lines_per_frame_r               = 8'd100;
        number_of_frames_r              = 3'd5;
        mem_cycles_r                    = 8'd100;
        pulse_length_r                  = 5'b00101;
        quarter_mirror_cycle_delay_r    = 16'h0A; // 10 clks delay
        start_TC_r                      = 1'b0;
  

        #20 // 2 clk cycles
        nrst_r  = 1;


    end

    /*Fill tick/pixel memory before mirror signal (zc)*/
    always @(posedge clk_r or negedge nrst_r) begin
        if(~nrst_r) begin
            waddr_r     <= 11'd0;
            wdata_r     <= 17'd0;
            start_TC_r  <= 1'b0;
            we_r        <= 1'b0;
        end
        else begin
            if(waddr_r < points_per_line_r) begin
                wdata_r     <= 17'd5;
                waddr_r     <= waddr_r + 11'd1;
            end
            else begin
                start_TC_r  <= 1'b1;
            end
        end
    end
    

    /*mirror signal*/
    always @(posedge clk_r or negedge nrst_r) begin
        if(~nrst_r) begin
            zc_r                    <= 1'b0;
            cnt_lines_completed_r   <= 8'd0;
        end
        else begin
            if(start_TC_r && ~zc_r && (cnt_lines_completed_r < lines_per_frame_r))begin
                zc_r    <= 1'b1;
            end
            else if(line_completed_w && (cnt_lines_completed_r < lines_per_frame_r)) begin
                zc_r                    <= 1'b0;
                cnt_lines_completed_r   <= cnt_lines_completed_r + 8'd1;
            end
        end
    end

    always @(posedge clk_r) begin
        if(update_mem_w)begin
            update_mem_switch_r[0] <= 1'b0;
        end
        else begin
            update_mem_switch_r[0] <= 1'b1;
        end
        
        update_mem_switch_r[1]    <= update_mem_switch_r[0];
        if((update_mem_switch_r[0] & ~update_mem_switch_r[1]) | (~update_mem_switch_r[0] & update_mem_switch_r[1]))begin
            $finish;
        end
    end
    
    always #5 clk_r = ~clk_r;


    timingCore uut(
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
    a ideia aqui é fazer um test bench que substitua as operações do sw
    */

endmodule
