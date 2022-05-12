`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: timingCore
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
`define WAIT        3'b001
`define TRIGGER     3'b010
`define DELAY       3'b011
`define NEW_LINE    3'b100

//CONSTANT DEFINES


module timingCore(
    input           clk_i,
    input           nrst_i,
    input           zc_i,
    //MEMORIES INTERFACE
    input   [8:0]   waddr_i,
    input   [16:0]  wdata_i,
    input           we_i,
    input   [2:0]   memory_selector_i,
    input           mem_updated_i,
    output          update_mem_o,
    //CONFIGURATION REGISTERS
    input   [9:0]   points_per_line_i,
    input   [7:0]   lines_per_frame_i,
    input   [2:0]   number_of_frames_i,
    input   [7:0]   mem_cycles_i,
    input   [4:0]   pulse_length_i,
    input   [15:0]  quarter_mirror_cycle_delay_i,
    //LASER DRIVER
    output          laser_trigger_o,
    
    output line_completed_o
);
//MODULE SIGNALS
//reg     [7:0]   quarter_mirror_cycle_delay_r;
wire    [2:0]   nxt_state_w;
reg     [2:0]   cur_state_r;
wire            zc_edge_w;
reg             wait_over_r;
reg             line_completed_r;
reg             fire_next_point_r;

wire    [15:0]  cnt_w;
wire    [15:0]  ticks_cnt_w;


//reg     [9:0]   points_per_line_r;
//reg     [9:0]   points_fired_r;

wire    [15:0]  timestamp_w;
wire            active_pixel_w;

//STATE MACHINE OUTPUT SIGNALS
reg             trigger_r;
reg     [8:0]   raddr_r;
reg             new_line_r;
reg             cnt_en_r;
reg             ticks_cnt_en_r;

//STATE MACHINE
assign nxt_state_w  =   (cur_state_r == `IDLE & ~zc_edge_w)             ?   `IDLE       :
                        (cur_state_r == `IDLE & zc_edge_w)              ?   `WAIT       :
                        (cur_state_r == `WAIT & ~wait_over_r)           ?   `WAIT       :
                        (cur_state_r == `WAIT & wait_over_r)            ?   `DELAY      ://delay?
                        (cur_state_r == `TRIGGER & ~line_completed_r)   ?   `DELAY      :
                        (cur_state_r == `TRIGGER & line_completed_r)    ?   `NEW_LINE   :
                        (cur_state_r == `DELAY & ~fire_next_point_r)    ?   `DELAY      :
                        (cur_state_r == `DELAY & fire_next_point_r)     ?   `TRIGGER    :
                        (cur_state_r == `NEW_LINE)                      ?   `IDLE       :   `IDLE;

assign line_completed_o = line_completed_r;

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
        wait_over_r         <= 1'b0;
        line_completed_r    <= 1'b0;
        fire_next_point_r   <= 1'b0;
    end
    else begin
        if(cnt_w >= quarter_mirror_cycle_delay_i & cur_state_r == `WAIT) begin
            wait_over_r <= 1'b1;
        end
        else begin
            wait_over_r <= 1'b0;
        end
        
        if(raddr_r >= points_per_line_i & cur_state_r == `DELAY) begin
            line_completed_r <= 1'b1;
        end
        else if(cur_state_r == `NEW_LINE) begin
            line_completed_r <= 1'b0;
        end
        
        if(ticks_cnt_w >= timestamp_w & cur_state_r == `DELAY) begin
            fire_next_point_r <= 1'b1;
        end
        else begin
            fire_next_point_r <= 1'b0;
        end
    end
end

//OUTPUTS CONTROL
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        new_line_r <= 1'b0;
        raddr_r <= {9{1'b0}};
        trigger_r <= 1'b0;
        cnt_en_r <= 1'b0;
        ticks_cnt_en_r <= 1'b0;
    end
    else begin
        if(cur_state_r == `NEW_LINE) begin
            new_line_r <= 1'b1;
        end
        else begin
            new_line_r <= 1'b0;
        end
        
        if(nxt_state_w == `TRIGGER) begin
            if(raddr_r < points_per_line_i) begin
                raddr_r <= raddr_r + 1'b1;
            end
            else begin
                raddr_r <= {9{1'b0}};
            end
        end
        
        if(cur_state_r == `TRIGGER) begin
            trigger_r <= 1'b1;
        end
        else begin
            trigger_r <= 1'b0;
        end
        
        if(nxt_state_w == `WAIT) begin
            cnt_en_r <= 1'b1;
        end
        else begin
            cnt_en_r <= 1'b0;
        end

        if(nxt_state_w == `DELAY) begin
            ticks_cnt_en_r <= 1'b1;
        end
        else begin
            ticks_cnt_en_r <= 1'b0;
        end
    end
end

//EDGE DETECTOR
edgeDetector edgeDetector_inst(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .signal_i(zc_i),
    .edge_o(zc_edge_w)
);

//QUARTER CYCLE COUNTER
counter cnt_inst(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .en_i(cnt_en_r),
    .cnt_o(cnt_w)
);

//TICKS COUNTER
counter ticks_cnt_inst(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .en_i(ticks_cnt_en_r),
    .cnt_o(ticks_cnt_w)
);

//LASER DRIVER
laserDriver laserDriver_inst(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .pulse_length_i(pulse_length_i),
    .active_pixel_i(active_pixel_w),
    .trigger_i(trigger_r),
    .laser_trigger_o(laser_trigger_o)
);

//MEMORY MANAGER INSTANCE
memoryManager memoryManager_inst(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .new_line_i(new_line_r),
    .mem_updated_i(mem_updated_i),
    .mem_cycles_i(mem_cycles_i),
    .lines_per_frame_i(lines_per_frame_i),
    .number_of_frames_i(number_of_frames_i),
    .waddr_i(waddr_i),
    .wdata_i(wdata_i),
    .wen_i(we_i),
    .memory_selector_i(memory_selector_i),
    .raddr_i(raddr_r),
    .update_mem_o(update_mem_o),
    .timestamp_o(timestamp_w),
    .active_pixel_o(active_pixel_w)
);

endmodule