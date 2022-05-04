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
`define EDGE_TICKS  3'b001
`define MEM_UPDATE  3'b010

module laserSynchronizer #(
    parameter   SYSCLOCK_P      = 500000000, //500MHz
    parameter   THETAMAX_P      = 9,
    parameter   FRAME_COLUMNS_P = 360,
    parameter   FRAME_LINES_P   = 100,
    parameter   FRAME_NUMBER_P  = 5,
    parameter   MEM_CYCLES_P    = 13,
    parameter   PULSE_LENGTH_P  = 5,
    parameter   LINE_POINTS_P   = 20,
    localparam  PASSAGES_P      = (FRAME_COLUMNS_P/LINE_POINTS_P),
    localparam  TOTAL_POINTS_P  = (FRAME_COLUMNS_P*FRAME_NUMBER_P),//MAX=4095
    localparam  THETA_STEP_P    = (FRAME_NUMBER_P*PASSAGES_P)
)(
    input           clk_i,
    input           nrst_i,
    input           zc_i,
    input   [23:0]  freq_i,

    output          laser_trigger_o,

    output [2:0]    mem_select_o, //remove
    output          wedata_dtTicks_o, //remove
    output [15:0]   wdata_dtTicks_o,//remove
    output [10:0]   waddr_dtTicks_o//remove
);

//TIMING CORE
wire [15:0] quarter_mirror_cycle_delay_w;
wire        update_mem_w, line_completed_w;
reg  [16:0] wdata_r;
reg  [10:0] waddr_r;
reg  [2:0]  mem_select_r;
reg         mem_updated_r;
reg         we_r;

assign quarter_mirror_cycle_delay_w = freq_i >> 2; // (freq/4)

assign mem_select_o = mem_select_r; //remove
assign wedata_dtTicks_o = we_r; //remove
assign wdata_dtTicks_o = wdata_r[15:0]; //remove
assign waddr_dtTicks_o = waddr_r; //remove

//STATE MACHINE
wire [2:0]  nxt_state_w;
reg  [2:0]  cur_state_r;
reg         edgeTicks_saved_r;
reg         mem_update_over_r;

//CORDIC
wire [15:0] tick_data_w;
wire        tick_Valid_w;
wire        tick_notValid_w;
reg  [11:0] theta_data_r, theta_aux0_r, theta_aux1_r;
reg         theta_valid_r;

//LASER SYNC
reg [15:0]  edgeTicks_r [0:FRAME_NUMBER_P-1];
reg [2:0]   edgeTicks_select_r;
reg [15:0]  last_dt_Ticks_r;
reg [9:0]   line_points_cnt_r;
reg [9:0]   passages_cnt_r;
reg [2:0]   frame_number_cnt_r;
reg [1:0]   mem_switch_r;
reg         ticks_update_r;
reg         active_pixel_r;

integer     i, aux;//clean array


//STATE MACHINE
assign nxt_state_w  =   (cur_state_r == `IDLE & ~ticks_update_r)            ?   `IDLE       :
                        (cur_state_r == `IDLE & ticks_update_r)             ?   `EDGE_TICKS :
                        (cur_state_r == `EDGE_TICKS & ~edgeTicks_saved_r)   ?   `EDGE_TICKS :
                        (cur_state_r == `EDGE_TICKS & edgeTicks_saved_r)    ?   `MEM_UPDATE :
                        (cur_state_r == `MEM_UPDATE & ~mem_update_over_r)   ?   `MEM_UPDATE :
                        (cur_state_r == `MEM_UPDATE & mem_update_over_r)    ?   `IDLE       :   `IDLE;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        cur_state_r <= `IDLE;
    end
    else begin
        cur_state_r <= nxt_state_w;
    end
end

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_update_over_r   <= 1'b0;
        edgeTicks_saved_r  <= 1'b0;
    end
    else begin
        if((cur_state_r == `EDGE_TICKS) & (edgeTicks_select_r > FRAME_NUMBER_P-1)) begin
            edgeTicks_saved_r <= 1'b1;
        end
        else begin
            edgeTicks_saved_r <= 1'b0;
        end
        
        if((cur_state_r == `MEM_UPDATE) & (frame_number_cnt_r >= FRAME_NUMBER_P-1) & (waddr_r >= FRAME_COLUMNS_P-1) & tick_Valid_w) begin
            mem_update_over_r <= 1'b1;
        end
        else begin
            mem_update_over_r <= 1'b0;
        end
    end
end


//MEMORY SWITCH
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_switch_r    <= 2'b11;
        ticks_update_r  <= 1'b0;
        mem_updated_r   <= 1'b1; // enable mem switch to receive singal when MEM0 is consumed
    end
    else begin 
        mem_switch_r    <= {mem_switch_r[0], update_mem_w};
        ticks_update_r  <= ((mem_switch_r[0] & ~mem_switch_r[1]) | (~mem_switch_r[0] & mem_switch_r[1]));

        if((cur_state_r == `MEM_UPDATE) | (cur_state_r == `EDGE_TICKS)) begin //Enable/Disable mem switch
            mem_updated_r   <= 1'b0;
        end
        else begin
            mem_updated_r   <= 1'b1;
        end
    end
end

//EDGE TICK
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        edgeTicks_select_r <= 3'b000;   
        for (aux = 0; aux < FRAME_NUMBER_P; aux = aux + 1) begin
            edgeTicks_r[aux] <= 19'd0;
        end
    end
    else begin 
        if((cur_state_r == `EDGE_TICKS) & tick_Valid_w) begin
                edgeTicks_r[edgeTicks_select_r] <= tick_data_w;
        end

        if(cur_state_r == `EDGE_TICKS) begin
            if (tick_notValid_w) begin
                edgeTicks_select_r <= edgeTicks_select_r + 1'b1;
            end
        end
        else begin
            edgeTicks_select_r <= 3'b000;
        end
    end
end

//FRAME ITERATION
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        frame_number_cnt_r <= 3'b000;
        passages_cnt_r  <= 10'd0;
        line_points_cnt_r <= 10'd0;
    end
    else if(cur_state_r == `MEM_UPDATE) begin 
        /*if(cur_state_r == `MEM_UPDATE) begin
            if(tick_Valid_w) begin
                if (line_points_cnt_r < LINE_POINTS_P-1) begin//20
                    line_points_cnt_r <= line_points_cnt_r + 1'b1;
                end
                else begin
                    line_points_cnt_r <= 10'd0;
                    if(passages_cnt_r < PASSAGES_P-1) begin//18
                        passages_cnt_r <= passages_cnt_r + 1'b1;
                    end
                    else begin
                        passages_cnt_r <= 10'd0;
                        if (frame_number_cnt_r < FRAME_NUMBER_P-1) begin//5
                            frame_number_cnt_r <= frame_number_cnt_r + 1'b1;
                        end
                        else begin
                            frame_number_cnt_r <= 3'b000;
                        end
                    end
                end
            end
        end
        else begin
            line_points_cnt_r <= 10'd0;
            passages_cnt_r <= 10'd0;
            frame_number_cnt_r <= 3'b000;
        end*/


        if(tick_Valid_w) begin

            if (line_points_cnt_r < LINE_POINTS_P-1) begin//20
                line_points_cnt_r <= line_points_cnt_r + 1'b1;
            end
            else begin
                line_points_cnt_r <= 10'd0;
            end
            
            if (line_points_cnt_r >= LINE_POINTS_P-1) begin
                if(passages_cnt_r < PASSAGES_P-1) begin//18
                    passages_cnt_r <= passages_cnt_r + 1'b1;
                end
                else begin
                    passages_cnt_r <= 10'd0;
                end
            end
        
            if (passages_cnt_r >= PASSAGES_P-1) begin
                if(frame_number_cnt_r < FRAME_NUMBER_P-1) begin//5
                    frame_number_cnt_r <= frame_number_cnt_r + 1'b1;
                end
                else begin
                    frame_number_cnt_r <= 10'd0;
                end
            end
        end

    end
    else begin
        line_points_cnt_r <= 10'd0;
        passages_cnt_r <= 10'd0;
        frame_number_cnt_r <= 3'b000;
    end
end

//THETA ITERATION
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        theta_valid_r   <= 1'b0;
        theta_data_r    <= 12'd0;
        theta_data_r    <= TOTAL_POINTS_P[11:0] - FRAME_NUMBER_P[11:0];
    end
    else begin 
        //THETA VALID
        if((cur_state_r == `IDLE) & ticks_update_r) begin // trigger computation when previous state done
            theta_valid_r <= 1'b1;
        end
        else if(cur_state_r == `EDGE_TICKS) begin
            if(tick_Valid_w) begin
                theta_valid_r <= 1'b0;
            end
            else if (edgeTicks_saved_r | (tick_notValid_w & (edgeTicks_select_r < FRAME_NUMBER_P-1))) begin
                theta_valid_r <= 1'b1;
            end
        end
        else if(cur_state_r == `MEM_UPDATE) begin
            theta_valid_r <= tick_Valid_w ? 1'b0 : (tick_notValid_w ? 1'b1 : theta_valid_r);
        end
        else  begin
            theta_valid_r <= 1'b0;
        end

        //THETA ITERATION
        if(cur_state_r == `EDGE_TICKS) begin
            if (tick_Valid_w) begin
                theta_data_r <= theta_data_r + 1'b1; 
            end
            else if(edgeTicks_saved_r) begin
                theta_data_r <= 12'd0;
            end
        end
        else if(cur_state_r == `MEM_UPDATE) begin
            theta_aux0_r <= line_points_cnt_r * THETA_STEP_P;
            theta_aux1_r <= (passages_cnt_r >> 1) * FRAME_NUMBER_P;
            if(tick_notValid_w) begin
                theta_data_r <= theta_aux0_r + theta_aux1_r + frame_number_cnt_r;
            end
        end
        else begin
            theta_data_r <= TOTAL_POINTS_P[11:0] - FRAME_NUMBER_P[11:0];
        end
    end
end

//DATA TICKS
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        waddr_r         <= 11'd0;
        wdata_r         <= 17'd0;
        last_dt_Ticks_r <= 16'd0;
        we_r            <= 1'b0;
        mem_select_r    <= 3'b000;
        active_pixel_r  <= 1'b1; //enable every pixel
    end
    else begin 
        //DATA TICKS
        if(cur_state_r == `MEM_UPDATE) begin
            if(tick_Valid_w) begin
                /*if((passages_cnt_r == 10'd0) & (line_points_cnt_r == 10'd0)) begin//1st iteration
                    wdata_r[15:0]   <= tick_data_w;
                end
                else if(line_points_cnt_r == 10'd0) begin//mirror in the edges
                    wdata_r[15:0]   <= tick_data_w - last_dt_Ticks_r + edgeTicks_r[frame_number_cnt_r];
                end
                else begin//elsewhere
                    wdata_r[15:0]   <= tick_data_w - last_dt_Ticks_r;
                end*/

                if((line_points_cnt_r == 10'd0) & (passages_cnt_r > 10'd0)) begin//mirror in the edges
                    wdata_r[15:0]   <= tick_data_w - last_dt_Ticks_r + edgeTicks_r[frame_number_cnt_r];
                end
                else begin
                    wdata_r[15:0]   <= tick_data_w - last_dt_Ticks_r;//elsewhere
                end




                wdata_r[16]     <= active_pixel_r;
                last_dt_Ticks_r <= tick_data_w;
            end
        end
        else begin
            wdata_r         <= 17'd0;
            last_dt_Ticks_r <= 16'd0;
        end

        //ADDR TICKS
        if(cur_state_r == `MEM_UPDATE) begin
            if(tick_notValid_w) begin
                if (waddr_r < FRAME_COLUMNS_P-1) begin
                    waddr_r <= waddr_r + 1'b1;
                end
                else begin
                    waddr_r <= 11'd0;
                end
            end
        end
        else begin
            waddr_r <= 11'd0;
        end

        //STORE TICKS
        if((cur_state_r == `MEM_UPDATE) & tick_Valid_w) begin
            we_r            <= 1'b1;
        end
        else begin
            we_r            <= 1'b0;
        end

        mem_select_r    <= frame_number_cnt_r; //delay needed when switching between frame mems
    end
end


cordicManager #(
    .FRAME_COLUMNS_P(FRAME_COLUMNS_P),
    .FRAME_NUMBER_P(FRAME_NUMBER_P),
    .THETAMAX_P(THETAMAX_P)
) CM_uut
(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .freq_i(freq_i),
    .theta_iteration_valid_i(theta_valid_r),//valid theta
    .theta_iteration_i(theta_data_r),//theta step

    .dt_Ticks_valid_o(tick_Valid_w),//valid tick
    .next_dt_Ticks_o(tick_notValid_w),//invalid tick
    .dt_Ticks_o(tick_data_w)//data tick
);


timingCore TC_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .zc_i(zc_i), // from mirror (zero cross)
    .waddr_i(waddr_r), // tick addr
    .wdata_i(wdata_r), // {dt_ticks [15:0], active_pixel [16:16]} 
    .we_i(we_r), // write tick
    .memory_selector_i(mem_select_r), // select frame mem
    .mem_updated_i(mem_updated_r), // memory enable (enable switch mems)
    .points_per_line_i(FRAME_COLUMNS_P[9:0]-1'b1), // 360
    .lines_per_frame_i(FRAME_LINES_P[7:0]-1'b1), // 100
    .number_of_frames_i(FRAME_NUMBER_P[2:0]-1'b1), // 5
    .mem_cycles_i(MEM_CYCLES_P[7:0]-1'b1), // 100 
    .pulse_length_i(PULSE_LENGTH_P[4:0]-1'b1), // 5 
    .quarter_mirror_cycle_delay_i(quarter_mirror_cycle_delay_w-1'b1), // 1/4 mirror period
    
    .update_mem_o(update_mem_w), // update MEM0 | MEM1
    .laser_trigger_o(laser_trigger_o), // trigger lase beam
    .line_completed_o(line_completed_w) // for top level sync
);
endmodule
