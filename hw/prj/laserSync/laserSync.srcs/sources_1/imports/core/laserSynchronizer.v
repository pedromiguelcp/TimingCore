`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2022 01:14:34 PM
// Design Name: 
// Module Name: laserSynchronizer
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

//STATE MACHINE DEFINES
`define IDLE        3'b000
`define MEM_UPDATE  3'b001

module laserSynchronizer #(
    parameter   SYSCLOCK_P          = 500000000, //500MHz
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   LINES_PER_FRAME_P   = 100,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   MEM_CYCLES_P        = 100,//simulation purposes (100 before)
    parameter   PULSE_LENGTH_P      = 5,
    parameter   THETAMAX_P          = 9,
    localparam  TOTAL_POINTS_P      = (POINTS_PER_LINE_P*NUMBER_OF_FRAMES_P)
)(
    input           clk_i,
    input           nrst_i,
    input           zc_i,
    input   [23:0]  freq_i,

    output          laser_trigger_o,
        output        wedata_dtTicks_o,
        output [15:0] wdata_dtTicks_o,
        output [10:0] waddr_dtTicks_o
);

reg     [10:0]  waddr_r;
reg     [16:0]  wdata_r;
reg             we_r;
reg     [2:0]   memory_selector_r;
reg             mem_updated_r;
wire    [15:0]  quarter_mirror_cycle_delay_w;
wire            update_mem_w, line_completed_w;

assign wedata_dtTicks_o = we_r;
assign wdata_dtTicks_o = wdata_r[15:0];
assign waddr_dtTicks_o = waddr_r;

wire    [2:0]   nxt_state_w;
reg     [2:0]   cur_state_r;
reg     [1:0]   mem_switch_r;
reg             ticks_update_r;
reg             mem_update_over_r;
reg             active_pixel_r;
reg     [15:0]  previous_dt_ticks_r [0:NUMBER_OF_FRAMES_P-1];
integer i;
reg             en_cordic_r;
wire            dt_Ticks_valid_w;
wire            next_dt_Ticks_w;
wire [15:0]     dt_Ticks_w;

//STATE MACHINE
assign nxt_state_w  =   (cur_state_r == `IDLE & ~ticks_update_r)            ?   `IDLE       :
                        (cur_state_r == `IDLE & ticks_update_r)             ?   `MEM_UPDATE :
                        (cur_state_r == `MEM_UPDATE & ~mem_update_over_r)   ?   `MEM_UPDATE :
                        (cur_state_r == `MEM_UPDATE & mem_update_over_r)    ?   `IDLE       :   `IDLE;

assign quarter_mirror_cycle_delay_w = freq_i >> 2; // (freq/2)


always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        cur_state_r <= `IDLE;
    end
    else begin
        cur_state_r <= nxt_state_w;
    end
end

//SIGNALS LOGIC
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_update_over_r   <= 1'b0;
    end
    else begin
        if((waddr_r >= POINTS_PER_LINE_P) & (cur_state_r == `MEM_UPDATE)) begin
            mem_update_over_r <= 1'b1;
        end
        else begin
            mem_update_over_r <= 1'b0;
        end
    end
end

//Check for memory switch
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_switch_r    <= 2'b11;
        ticks_update_r  <= 1'b0;
    end
    else begin 
        mem_switch_r    <= {mem_switch_r[0], update_mem_w};
        ticks_update_r  <= ((mem_switch_r[0] & ~mem_switch_r[1]) | (~mem_switch_r[0] & mem_switch_r[1]));
    end
end

//Memory update
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        waddr_r             <= 11'd0;
        wdata_r             <= 17'd0;
        we_r                <= 1'b0;
        active_pixel_r      <= 1'b1; //allways on for now
        memory_selector_r   <= 3'b000;
        en_cordic_r         <= 1'b0;
        for (i = 0; i < NUMBER_OF_FRAMES_P; i = i + 1) begin
            previous_dt_ticks_r[i] <= 16'd0;
        end
    end
    else begin
        if(cur_state_r == `MEM_UPDATE) begin
            if(dt_Ticks_valid_w) begin
                we_r            <= 1'b1;
                wdata_r[16]     <= active_pixel_r;
                wdata_r[15:0]   <= dt_Ticks_w - previous_dt_ticks_r[memory_selector_r];
                previous_dt_ticks_r[memory_selector_r]  <= dt_Ticks_w;

            end
            else if(next_dt_Ticks_w) begin
                if(memory_selector_r < (NUMBER_OF_FRAMES_P - 1)) begin
                    memory_selector_r <= memory_selector_r + 1'b1;
                end
                else begin
                    waddr_r <= waddr_r + 1'b1;
                    memory_selector_r <= 3'b000;
                end

            end
            else begin
                we_r    <= 1'b0;
            end
        end

        if(cur_state_r == `MEM_UPDATE) begin
            en_cordic_r <= 1'b1;
        end 
        else begin
            en_cordic_r <= 0;
            waddr_r     <= 11'd0;
            wdata_r     <= 17'd0;
            we_r        <= 1'b0;
            memory_selector_r   <= 3'b000;
            for (i = 0; i < NUMBER_OF_FRAMES_P; i = i + 1) begin
                previous_dt_ticks_r[i] <= 16'd0;
            end
        end
    end
end

//Enable/Disable mem switch
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_updated_r   <= 1'b1; // enable mem switch to receive singal when MEM0 is consumed
    end
    else begin
        if(cur_state_r == `MEM_UPDATE) begin
            mem_updated_r   <= 1'b0;
        end
        else begin
            mem_updated_r   <= 1'b1;
        end
    end
end


cordicManager #(
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P),
    .THETAMAX_P(THETAMAX_P)
) CM_uut
(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .freq_i(freq_i),
    .en_cordic_i(en_cordic_r),

    .dt_Ticks_valid_o(dt_Ticks_valid_w),
    .next_dt_Ticks_o(next_dt_Ticks_w),
    .dt_Ticks_o(dt_Ticks_w)
);


timingCore TC_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .zc_i(zc_i), // from mirror (signal when mirror passes in the center)
    .waddr_i(waddr_r), // address to write ticks in memory
    .wdata_i(wdata_r), // {dt_ticks [15:0], active_pixel [16:16]} 
    .we_i(we_r), // enable memory write (just send a singal?)
    .memory_selector_i(memory_selector_r), // select MEM0 | MEM1
    .mem_updated_i(mem_updated_r), // memory enable (enable switch between mems)
    .points_per_line_i(POINTS_PER_LINE_P[9:0]-1'b1), // 360
    .lines_per_frame_i(LINES_PER_FRAME_P[7:0]-1'b1), // 100
    .number_of_frames_i(NUMBER_OF_FRAMES_P[2:0]-1'b1), // 5
    .mem_cycles_i(MEM_CYCLES_P[7:0]-1'b1), // 100 
    .pulse_length_i(PULSE_LENGTH_P[4:0]-1'b1), // 5 (clock cycles "triggering" the laser beam)
    .quarter_mirror_cycle_delay_i(quarter_mirror_cycle_delay_w-1'b1), // 12500 | 23148 (? clks from center to edge of mirror)
    
    .update_mem_o(update_mem_w), // update MEM0 | MEM1
    .laser_trigger_o(laser_trigger_o), // trigger lase beam
    .line_completed_o(line_completed_w) // pixels from current row done
);
endmodule
