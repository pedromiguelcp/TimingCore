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
    parameter   LINES_PER_FRAME_P   = 13,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   MEM_CYCLES_P        = 13,
    parameter   PULSE_LENGTH_P      = 5,
    parameter   THETAMAX_P          = 9,
    parameter   MIRROR_FREQ_P       = 10800,
    localparam  SYS_MIRROR_RATIO_P  = (SYSCLOCK_P/MIRROR_FREQ_P)
)();

reg         clk_r, nrst_r, zc_r;
reg [15:0]  cnt_clock_tick_r;

wire        laser_trigger_w;
wire        wedata_dtTicks_w;
wire [15:0] wdata_dtTicks_w;
wire [10:0] waddr_dtTicks_w;

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

        //valid_r             <= 1'b0;
        //aux_r               <= 1'b0;
    end
    else begin
        if(cnt_clock_tick_r < SYS_MIRROR_RATIO_P/2)begin
            cnt_clock_tick_r <= cnt_clock_tick_r + 1'b1;
        end
        else begin
            cnt_clock_tick_r <= 16'd0;
            zc_r <= ~zc_r;
        end

        //valid_r             <= 1'b1;
        //aux_r               <= 1'b1;
    end
end

//cos
//0010000000000000
//1100011101100110
//sin
//0011011101101100
//0001110111011111
//cordic
//0010000110000010(59.9)
//0101010011111110

//00010000110000010011111011
//0010.1010011111101111111010
/*wire    [(26-1):0]  phase_w;
wire    [(16-1):0]  mag_w;
wire                aux_w;
reg                 valid_r;
reg                 aux_r;


arcTan arcTan_uut
(
    .clk_i(clk_r),
    .nrst_i(nrst_r),
    .valid_i(valid_r),
    .cos_i(16'b1100011101100110),
    .sin_i(16'b0001110111011111),
    .aux_i(aux_r),
    //.mag_o(mag_w),
    .phase_o(phase_w),
    .aux_o(aux_w)
);*/

/*
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
*/

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
    .freq_i(SYS_MIRROR_RATIO_P[23:0]),

    .laser_trigger_o(laser_trigger_w),
    .wedata_dtTicks_o(wedata_dtTicks_w),
    .wdata_dtTicks_o(wdata_dtTicks_w),
    .waddr_dtTicks_o(waddr_dtTicks_w)
);

endmodule
