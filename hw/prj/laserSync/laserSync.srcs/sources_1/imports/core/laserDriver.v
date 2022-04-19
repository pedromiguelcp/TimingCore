`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2021 10:33:52
// Design Name: 
// Module Name: laserDriver
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
`define LASER_IDLE    1'b0
`define LASER_TRIGGER 1'b1

module laserDriver(
    input       clk_i,
    input       nrst_i,
    input [4:0] pulse_length_i,
    input       active_pixel_i,
    input       trigger_i,
    output      laser_trigger_o
);

//MODULE SIGNALS
reg     [4:0]   cnt_r;
reg             trigger_laser_r;

reg             cur_state_r;
wire            nxt_state_w;

wire            trigger_w;
reg             pulse_over_r;

//STATE MACHIE
assign nxt_state_w  =   (cur_state_r == `LASER_IDLE & ~trigger_w)         ?   `LASER_IDLE       :
                        (cur_state_r == `LASER_IDLE & trigger_w)          ?   `LASER_TRIGGER    :
                        (cur_state_r == `LASER_TRIGGER & ~pulse_over_r)   ?   `LASER_TRIGGER    :
                        (cur_state_r == `LASER_TRIGGER & pulse_over_r)    ?   `LASER_IDLE       :   `LASER_IDLE;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        cur_state_r <= `LASER_IDLE;
    end
    else begin
        cur_state_r <=  nxt_state_w;
    end
end

//SIGNALS LOGIC
assign trigger_w = trigger_i & active_pixel_i;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        pulse_over_r    <=  1'b0;
        cnt_r           <=  4'b000;
        trigger_laser_r <=  1'b0;
    end
    else begin
        if(cur_state_r == `LASER_TRIGGER) begin
            cnt_r <= cnt_r + 1'b1;
            trigger_laser_r <=  1'b1;
        end
        else begin
            cnt_r <= 4'b0000;
            trigger_laser_r <=  1'b0;
        end
        
        if(cnt_r >= pulse_length_i /*& cur_state_r == `TRIGGER*/) begin
            pulse_over_r <= 1'b1;
        end
        else begin
            pulse_over_r <= 1'b0;
        end
    end
end

//OUTPUT LOGIC
assign laser_trigger_o = trigger_laser_r;

endmodule