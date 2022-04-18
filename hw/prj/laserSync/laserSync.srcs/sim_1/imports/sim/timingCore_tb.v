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

//STATE MACHINE DEFINES
`define IDLE        3'b000
`define MEM_INIT    3'b001
`define WAIT        3'b010
`define DELAY       3'b011
`define DONE        3'b100

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

wire    [2:0]   nxt_state_w;
reg     [2:0]   cur_state_r;
reg     [1:0]   mem_switch_r;
reg             start_TC_r, init_mem_r, mems_updated_r;
reg             sim_done_r;
reg     [7:0]   lines_processed_r;

assign nxt_state_w  =   (cur_state_r == `IDLE & ~init_mem_r)                        ?   `IDLE       :
                        (cur_state_r == `IDLE & init_mem_r)                         ?   `MEM_INIT   :
                        (cur_state_r == `MEM_INIT & ~mems_updated_r)                ?   `MEM_INIT   :
                        (cur_state_r == `MEM_INIT & mems_updated_r)                 ?   `WAIT       :
                        (cur_state_r == `WAIT & ~sim_done_r & ~line_completed_w)    ?   `WAIT       :
                        (cur_state_r == `WAIT & ~sim_done_r & line_completed_w)     ?   `DELAY      :
                        (cur_state_r == `WAIT & sim_done_r)                         ?   `DONE       :

                        (cur_state_r == `DELAY & line_completed_w)                  ?   `DELAY      :
                        (cur_state_r == `DELAY & ~line_completed_w)                 ?   `WAIT       :

                        (cur_state_r == `DONE)                                      ?   `DONE       :   `IDLE;


initial begin
    $display("\n\n**************TIMING CORE tb********************\n");

    clk_r                           = 0;
    nrst_r                          = 0;
    points_per_line_r               = 10'd360;
    lines_per_frame_r               = 8'd100;
    number_of_frames_r              = 3'd5;
    mem_cycles_r                    = 8'd100;
    pulse_length_r                  = 5'b00101;
    quarter_mirror_cycle_delay_r    = 16'h0A; // 10 clks delay


    #20 // 2 clk cycles
    nrst_r  = 1;


end

//state machine gear
always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        cur_state_r <= `IDLE;
    end
    else begin
        cur_state_r <= nxt_state_w;
    end
end

//state machine logic
always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        init_mem_r      <= 1'b0;
        mems_updated_r  <= 1'b0;
    end
    else begin
        if(cur_state_r == `IDLE) begin // go directly to next state
            init_mem_r <= 1'b1;
        end
        if(memory_selector_r > 3'b100 & cur_state_r == `MEM_INIT) begin // when all memories are filled go next state
            mems_updated_r <= 1'b1;
        end
    end
end

//Fill tick/pixel memory before mirror signal (zc)
always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        waddr_r     <= 11'd0;
        wdata_r     <= 17'd0;
        we_r        <= 1'b0;
        memory_selector_r <= 3'b000; // 0-4 frame memories (it will only update MEMs1 of specified frames)
    end
    else begin
        if(memory_selector_r <= 3'b100 & cur_state_r == `MEM_INIT) begin
            if(waddr_r < points_per_line_r) begin
                waddr_r <= waddr_r + 1'b1;
                wdata_r <= 17'd5;
                //we_r    <= 1'b1; // memories already filled at init
            end
            else begin
                waddr_r <= 11'd0;
                //we_r    <= 1'b0;
                memory_selector_r <= memory_selector_r + 1'b1;
            end
        end
    end
end

//mirror signal
always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        zc_r    <= 1'b0;
        lines_processed_r    <= 1'b0;
    end
    else begin //sair do estado wait e ir para um intermédio para esperar que o line_complete venha a 0
        if((mems_updated_r & (cur_state_r == `MEM_INIT)) | (line_completed_w & (cur_state_r == `WAIT)))begin
            zc_r    <= ~zc_r;
        end
        //count number of lines completed
        if(line_completed_w & (cur_state_r == `WAIT))begin
            lines_processed_r <= lines_processed_r + 1'b1;
        end
    end
end

//Check for memory switch
always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        mem_switch_r    <= 2'b11;
        mem_updated_r   <= 1'b1; // enable mem switch to receive singal when MEM0 is consumed
    end
    else begin
        if(update_mem_w)begin // starts with 1
            mem_switch_r[0] <= 1'b1;
        end
        else begin
            mem_switch_r[0] <= 1'b0;
        end     
        mem_switch_r[1]    <= mem_switch_r[0];
        sim_done_r <= ((mem_switch_r[0] & ~mem_switch_r[1]) | (~mem_switch_r[0] & mem_switch_r[1]));
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
