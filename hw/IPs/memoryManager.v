`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: memoryManager
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
//MEMORY SELECTION STATE MACHINE STATES DEFINITION
`define MEM0        2'b00
`define MEM1        2'b01
`define WAIT_MEM0   2'b10
`define WAIT_MEM1   2'b11

//MEMORY GROUP SELECTION STATE MACHINE STATES DEFINITION
`define MEM_IDLE        2'b00    
`define MEM_LINE_INC    2'b01
`define MEM_SWITCH      2'b10

module memoryManager(
    input           clk_i,
    input           nrst_i,
    input           new_line_i,
    input           mem_updated_i,
    input   [7:0]   mem_cycles_i,
    input   [7:0]   lines_per_frame_i,
    input   [2:0]   number_of_frames_i,
    input   [10:0]  waddr_i,
    input   [16:0]  wdata_i,
    input           wen_i,
    input   [2:0]   memory_selector_i,
    input   [10:0]  raddr_i,
    output          update_mem_o,
    output          active_pixel_o,
    output  [15:0]  timestamp_o
);
//MODULE SIGNALS
reg     [1:0]   mem_sel_cur_state_r;
wire    [1:0]   mem_sel_nxt_state_w;
wire            update_mem_w;
wire            mem_ok_w;   //NUMBER OF MEMORY CYCLES BELOW THE DEFINED VALUE
reg     [7:0]   mem_cycles_cnt_r;
reg             update_mem_r;

reg     [1:0]   mem_grp_cur_state_r;
wire    [1:0]   mem_grp_nxt_state_w;
wire            frame_completed_w; //NUMBER OF LINES below the number of lines per frame
reg     [7:0]   lines_cnt_r;
reg     [2:0]   mem_grp_r;

wire    [4:0]   active_pixel_w;
wire    [15:0]  timestamp_w [0:4];

wire    [4:0]   wen_w;
//MEMORY SELECTION STATE MACHINE
assign mem_sel_nxt_state_w  =   (mem_sel_cur_state_r == `MEM0 & (mem_ok_w))                             ?   `MEM0       :
                                (mem_sel_cur_state_r == `MEM0 & (~mem_ok_w & ~mem_updated_i))           ?   `WAIT_MEM0  :
                                (mem_sel_cur_state_r == `MEM0 & (~mem_ok_w & mem_updated_i))            ?   `MEM1       :
                                (mem_sel_cur_state_r == `WAIT_MEM0 & (~new_line_i | ~mem_updated_i))    ?   `WAIT_MEM0  :
                                (mem_sel_cur_state_r == `WAIT_MEM0 & (new_line_i & mem_updated_i))      ?   `MEM1       :
                                (mem_sel_cur_state_r == `MEM1 & (mem_ok_w))                             ?   `MEM1       :
                                (mem_sel_cur_state_r == `MEM1 & (~mem_ok_w & ~mem_updated_i))           ?   `WAIT_MEM1  :
                                (mem_sel_cur_state_r == `MEM1 & (~mem_ok_w & mem_updated_i))            ?   `MEM0       :
                                (mem_sel_cur_state_r == `WAIT_MEM1 & (~new_line_i | ~mem_updated_i))    ?   `WAIT_MEM1  :
                                (mem_sel_cur_state_r == `WAIT_MEM1 & (new_line_i & mem_updated_i))      ?   `MEM0       :   `MEM0;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_sel_cur_state_r <= `MEM0;
    end
    else begin
        mem_sel_cur_state_r <= mem_sel_nxt_state_w;
    end
end
//MEMORY SELECTION OUTPUT DEFINITION
always@(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_cycles_cnt_r <= 8'h00;
    end
    else if(new_line_i) begin
        mem_cycles_cnt_r <= mem_cycles_cnt_r +1'b1;
    end
    else if(~mem_ok_w) begin
        mem_cycles_cnt_r <= 8'h00;
    end
end


always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        update_mem_r = 1'b1;
    end
    else if(mem_sel_cur_state_r == `MEM0 | mem_sel_cur_state_r == `WAIT_MEM0) begin
        update_mem_r = 1'b1;
    end
    else if(mem_sel_cur_state_r == `MEM1 | mem_sel_cur_state_r == `WAIT_MEM1) begin
        update_mem_r = 1'b0;
    end
end

assign mem_ok_w = (mem_cycles_cnt_r <= mem_cycles_i);
assign update_mem_o = update_mem_r;

//MEMORY GROUP SELECTION STATE MACHINE
assign mem_grp_nxt_state_w  =   (mem_grp_cur_state_r == `MEM_IDLE & (~new_line_i))                      ?   `MEM_IDLE       :
                                (mem_grp_cur_state_r == `MEM_IDLE & (new_line_i & ~frame_completed_w))  ?   `MEM_LINE_INC   :
                                (mem_grp_cur_state_r == `MEM_IDLE & (new_line_i & frame_completed_w))   ?   `MEM_SWITCH     :
                                (mem_grp_cur_state_r == `MEM_LINE_INC)                                  ?   `MEM_IDLE       :
                                (mem_grp_cur_state_r == `MEM_SWITCH)                                    ?   `MEM_IDLE       :   `MEM_IDLE;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_grp_cur_state_r <= `MEM_IDLE;
    end
    else begin
        mem_grp_cur_state_r <= mem_grp_nxt_state_w;
    end
end
//MEMORY GROUP SELECTION OUTPUT DEFINITION
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        lines_cnt_r <= 8'h00;
    end
    else if(mem_grp_cur_state_r == `MEM_LINE_INC) begin
        lines_cnt_r <= lines_cnt_r + 1'b1;
    end
    else if(mem_grp_cur_state_r == `MEM_SWITCH) begin
        lines_cnt_r <= 8'h00;
    end
end

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        mem_grp_r <= 3'b000;
    end
    else if(mem_grp_cur_state_r == `MEM_SWITCH) begin
        if(mem_grp_r < number_of_frames_i) begin
            mem_grp_r <= mem_grp_r + 1'b1;
        end
        else begin
            mem_grp_r <= 3'b000;
        end
    end
end

assign frame_completed_w = (lines_cnt_r == lines_per_frame_i);

assign wen_w    =   (memory_selector_i == 3'b000)   ?   {4'b0000, wen_i}        :
                    (memory_selector_i == 3'b001)   ?   {3'b000, wen_i, 1'b0}   :
                    (memory_selector_i == 3'b010)   ?   {2'b00, wen_i, 2'b00}   :
                    (memory_selector_i == 3'b011)   ?   {1'b0, wen_i, 3'b000}   :
                    (memory_selector_i == 3'b100)   ?   {wen_i, 4'b0000}        :   {4'b000, wen_i};


//TIMESTAMP MEMORY INSTANCES
genvar i;
generate
    for(i = 0; i < 5; i = i + 1) begin: timestampMemGrp
        timestampMem timestampMem_inst(
            .clk_i(clk_i),
            .waddr_i(waddr_i),
            .wdata_i(wdata_i[15:0]),
            .wen_i(wen_w[i]),
            .mem_selector_i(update_mem_r),
            .raddr_i(raddr_i),
            .timestamp_o(timestamp_w[i])
        );
    end
endgenerate

assign timestamp_o  =   (mem_grp_r == 3'b000)   ?   timestamp_w[0]  :
                        (mem_grp_r == 3'b001)   ?   timestamp_w[1]  :
                        (mem_grp_r == 3'b010)   ?   timestamp_w[2]  :
                        (mem_grp_r == 3'b011)   ?   timestamp_w[3]  :
                        (mem_grp_r == 3'b100)   ?   timestamp_w[4]  :    timestamp_w[0];
                        
//ACTIVE PIXEL MEMORY INSTANCES
genvar j;
generate
    for(j = 0; j < 5; j = j + 1) begin: activePixelMemGrp
        activePixelMem activePixelMem_inst(
            .clk_i(clk_i),
            .waddr_i(waddr_i),
            .wdata_i(wdata_i[16]),
            .wen_i(wen_w[j]),
            .mem_selector_i(update_mem_r),
            .raddr_i(raddr_i),
            .active_pixel_o(active_pixel_w[j])
        );
    end
endgenerate

assign active_pixel_o = (mem_grp_r == 3'b000)   ?   active_pixel_w[0]  :
                        (mem_grp_r == 3'b001)   ?   active_pixel_w[1]  :
                        (mem_grp_r == 3'b010)   ?   active_pixel_w[2]  :
                        (mem_grp_r == 3'b011)   ?   active_pixel_w[3]  :
                        (mem_grp_r == 3'b100)   ?   active_pixel_w[4]  :    active_pixel_w[0];

integer f0, f1, f2, f3, f4;
initial begin
  f0 = $fopen("dt_Ticks_Frame0.txt","w");
  f1 = $fopen("dt_Ticks_Frame1.txt","w");
  f2 = $fopen("dt_Ticks_Frame2.txt","w");
  f3 = $fopen("dt_Ticks_Frame3.txt","w");
  f4 = $fopen("dt_Ticks_Frame4.txt","w");
end
always @(posedge clk_i) begin
    if(wen_i) begin
        if(memory_selector_i == 3'b000) begin
            $fwrite(f0,"%d\n",wdata_i[15:0]);
        end
        else if(memory_selector_i == 3'b001) begin
            $fwrite(f1,"%d\n",wdata_i[15:0]);
        end
        else if(memory_selector_i == 3'b010) begin
            $fwrite(f2,"%d\n",wdata_i[15:0]);
        end
        else if(memory_selector_i == 3'b011) begin
            $fwrite(f3,"%d\n",wdata_i[15:0]);
        end
        else if(memory_selector_i == 3'b100) begin
            $fwrite(f4,"%d\n",wdata_i[15:0]);
        end
    end
    if (waddr_i >= 11'd360) begin
        $fclose(f0);
        $fclose(f1);
        $fclose(f2);
        $fclose(f3);
        $fclose(f4);
    end
end

endmodule