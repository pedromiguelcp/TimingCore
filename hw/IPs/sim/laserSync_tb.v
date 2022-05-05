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
    parameter           SYSCLOCK_P          = 500000000, //500MHz
    parameter   [4:0]   THETAMAX_P          = 9,//up to 31
    parameter   [9:0]   FRAME_COLUMNS_P     = 360,//up to 1023
    parameter   [7:0]   FRAME_LINES_P       = 100,//up to 255
    parameter   [2:0]   FRAME_NUMBER_P      = 5,//up to 7
    parameter   [7:0]   MEM_CYCLES_P        = 15,
    parameter   [4:0]   PULSE_LENGTH_P      = 5,
    parameter   [9:0]   LINE_POINTS_P       = 20,
    parameter           MIRROR_FREQ_P       = 10800,
    localparam  [9:0]   PASSAGES_P          = (FRAME_COLUMNS_P/LINE_POINTS_P),
    localparam  [11:0]  TOTAL_POINTS_P      = (FRAME_COLUMNS_P*FRAME_NUMBER_P),//up to 4095
    localparam          SYS_MIRROR_RATIO_P  = (SYSCLOCK_P/MIRROR_FREQ_P)
)();

reg         clk_r, nrst_r, zc_r;
reg [15:0]  cnt_clock_tick_r;

wire        laser_trigger_w;
wire  [2:0] mem_select_w;
wire        wedata_dtTicks_w;
wire [15:0] wdata_dtTicks_w;
wire [10:0] waddr_dtTicks_w;
reg         done_r;

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
        zc_r                <= 1'b0;
    end
    else begin
        if(cnt_clock_tick_r < SYS_MIRROR_RATIO_P/2)begin
            cnt_clock_tick_r <= cnt_clock_tick_r + 1'b1;
        end
        else begin
            cnt_clock_tick_r <= 16'd0;
            zc_r <= ~zc_r;
        end
    end
end


integer f0, f1, f2, f3, f4;
initial begin
  f0 = $fopen("dt_Ticks_Frame0.txt","w");
  f1 = $fopen("dt_Ticks_Frame1.txt","w");
  f2 = $fopen("dt_Ticks_Frame2.txt","w");
  f3 = $fopen("dt_Ticks_Frame3.txt","w");
  f4 = $fopen("dt_Ticks_Frame4.txt","w");
end

always @(posedge clk_r or negedge nrst_r) begin
    if(~nrst_r) begin
        done_r <= 1'b0;
    end
    else if(wedata_dtTicks_w) begin
        if(mem_select_w == 3'b000) begin
            $fwrite(f0,"%d\n",wdata_dtTicks_w[15:0]);
        end
        else if(mem_select_w == 3'b001) begin
            $fwrite(f1,"%d\n",wdata_dtTicks_w[15:0]);
        end
        else if(mem_select_w == 3'b010) begin
            $fwrite(f2,"%d\n",wdata_dtTicks_w[15:0]);
        end
        else if(mem_select_w == 3'b011) begin
            $fwrite(f3,"%d\n",wdata_dtTicks_w[15:0]);
        end
        else if(mem_select_w == 3'b100) begin
            $fwrite(f4,"%d\n",wdata_dtTicks_w[15:0]);
        end
    end
    if ((mem_select_w == 3'b100) & (waddr_dtTicks_w >= 359) & wedata_dtTicks_w) begin
        done_r <= 1'b1;

        $fclose(f0);
        $fclose(f1);
        $fclose(f2);
        $fclose(f3);
        $fclose(f4);
    end
end

always @(posedge clk_r or negedge nrst_r) begin
    if(done_r) begin
        $finish;
    end
end

laserSynchronizer #(
    .SYSCLOCK_P(SYSCLOCK_P),
    .THETAMAX_P(THETAMAX_P),
    .FRAME_COLUMNS_P(FRAME_COLUMNS_P),
    .FRAME_LINES_P(FRAME_LINES_P),
    .FRAME_NUMBER_P(FRAME_NUMBER_P),
    .MEM_CYCLES_P(MEM_CYCLES_P),
    .PULSE_LENGTH_P(PULSE_LENGTH_P),
    .LINE_POINTS_P(LINE_POINTS_P)
) LS_uut
(
    .clk_i(clk_r),
    .nrst_i(nrst_r),
    .zc_i(zc_r),
    .freq_i(SYS_MIRROR_RATIO_P[23:0]),

    .laser_trigger_o(laser_trigger_w),
    .mem_select_o(mem_select_w),
    .wedata_dtTicks_o(wedata_dtTicks_w),
    .wdata_dtTicks_o(wdata_dtTicks_w),
    .waddr_dtTicks_o(waddr_dtTicks_w)
);
endmodule
