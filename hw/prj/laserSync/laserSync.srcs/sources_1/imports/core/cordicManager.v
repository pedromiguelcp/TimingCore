`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2022 03:21:57 PM
// Design Name: 
// Module Name: cordicManager
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


module cordicManager #(
    parameter   POINTS_PER_LINE_P   = 360,
    parameter   NUMBER_OF_FRAMES_P  = 5,
    parameter   THETAMAX_P          = 9
)(
    input           clk_i,
    input           nrst_i,
    input   [23:0]  freq_i,
    input           en_cordic_i,

    output          dt_Ticks_valid_o,
    output          next_dt_Ticks_o,
    output  [15:0]  dt_Ticks_o
);

wire            cordic_dout_tvalid_w;
wire [15:0]     cordic_dout_tdata_w;

wire            thetaCos_valid_w;
wire            thetaSin_valid_w;
wire [15:0]     thetaCos_w;
wire [15:0]     thetaSin_w;

wire            fp_freq_ticks_result_tvalid_w;
wire [31:0]     fp_freq_ticks_result_tdata_w;

wire            fp_cordic_result_tvalid_w;
wire [31:0]     fp_cordic_result_tdata_w;

wire            fp_dt_ticks_mul_result_tvalid_w;
wire [31:0]     fp_dt_ticks_mul_result_tdata_w;

wire            fp_dt_ticks_div_result_tvalid_w;
wire [31:0]     fp_dt_ticks_div_result_tdata_w;

reg             theta_iteration_valid_r;
reg  [15:0]     theta_iteration_r;

reg         new_dtTick_r, next_dtTick_r;
reg [1:0]   dtTick_states_r;

wire    dt_Ticks_valid_w;
assign  dt_Ticks_valid_o = new_dtTick_r;
assign  next_dt_Ticks_o  = next_dtTick_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        theta_iteration_valid_r <= 1'b0;
        theta_iteration_r       <= 16'd1;
    end
    else begin
        if(en_cordic_i) begin
            if(theta_iteration_r <= 16'd1) begin
                theta_iteration_valid_r <= 1'b1;
            end
            
            if(new_dtTick_r) begin
                theta_iteration_valid_r <= 1'b0;
                theta_iteration_r       <= theta_iteration_r + 16'd1;
            end
            else if(next_dtTick_r) begin
                theta_iteration_valid_r <= 1'b1;
            end
        end
        else begin
            theta_iteration_valid_r <= 1'b0;
            theta_iteration_r       <= 16'd1;  
        end
    end
end


//Check for new dt_tick
always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        dtTick_states_r <= 2'b00;
    end
    else begin 
        dtTick_states_r <= {dtTick_states_r[0], dt_Ticks_valid_w};
        new_dtTick_r    <= (dtTick_states_r[0] & ~dtTick_states_r[1]);
        next_dtTick_r   <= (~dtTick_states_r[0] & dtTick_states_r[1]);
    end
end

//substituir todas as constantes pelo valor respetivo no formato floating-point
//para reduzir ao maximo o uso do FP_IP
//validar tudo e comparar com o sw com varios valores de freq_i
//testar de alguma forma no lab talvez
//pensar que alterações podem ser feitas
    //menor resolução dos floating-points
    //resolução do cordic
    //uso de fixed-point nas operações
    //implementação do cordic
//falar com o abilio/Rui sobre a primeira iteração e sugestoes

//dt_ticks in fixed-point(int32) format
fp_dtTicks_to_fixed fp_dtTicks_to_fixed (
  .aclk(clk_i),                                  // input wire aclk
  .aresetn(nrst_i),                            // input wire aresetn
  .s_axis_a_tvalid(fp_dt_ticks_div_result_tvalid_w),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(fp_dt_ticks_div_result_tdata_w),              // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(dt_Ticks_valid_w),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(dt_Ticks_o)    // output wire [31 : 0] m_axis_result_tdata
);

//dt_ticks in floating-point format
fp_div fp_dt_ticks_div (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(fp_dt_ticks_mul_result_tvalid_w),             
  .s_axis_a_tdata(fp_dt_ticks_mul_result_tdata_w),       
  .s_axis_b_tvalid(1'b1),         
  .s_axis_b_tdata(32'h40c90fdb),   //2*pi in fp format           
  .m_axis_result_tvalid(fp_dt_ticks_div_result_tvalid_w),
  .m_axis_result_tdata(fp_dt_ticks_div_result_tdata_w)    
);

fp_mult fp_dt_ticks_mul (
  .aclk(clk_i),                                 
  .aresetn(nrst_i),                          
  .s_axis_a_tvalid(fp_freq_ticks_result_tvalid_w),             
  .s_axis_a_tdata(fp_freq_ticks_result_tdata_w),       
  .s_axis_b_tvalid(fp_cordic_result_tvalid_w),         
  .s_axis_b_tdata(fp_cordic_result_tdata_w),              
  .m_axis_result_tvalid(fp_dt_ticks_mul_result_tvalid_w),
  .m_axis_result_tdata(fp_dt_ticks_mul_result_tdata_w)    
);

//freq_i in fp format
fp_uint32_to_float fp_freq_ticks (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                         
  .s_axis_a_tvalid(1'b1), //check if freq_i is always changing (debounce?)           
  .s_axis_a_tdata({8'b00000000, freq_i}),              
  .m_axis_result_tvalid(fp_freq_ticks_result_tvalid_w),  
  .m_axis_result_tdata(fp_freq_ticks_result_tdata_w)    
);

//cordic output in fp format
fp_cordic_to_float fp_cordic (
  .aclk(clk_i),                                  
  .aresetn(nrst_i),                         
  .s_axis_a_tvalid(cordic_dout_tvalid_w),         
  .s_axis_a_tdata(cordic_dout_tdata_w),              
  .m_axis_result_tvalid(fp_cordic_result_tvalid_w),  
  .m_axis_result_tdata(fp_cordic_result_tdata_w)    
);

cordic cordicCore_uut (
  .aclk(clk_i),                                       
  .aresetn(nrst_i),                                
  .s_axis_cartesian_tvalid(thetaCos_valid_w & thetaSin_valid_w),  
  //.s_axis_cartesian_tdata({6'b0, 10'b0010000000, 6'b0, 10'b0010100000}),    // example from manual
  //.s_axis_cartesian_tdata({16'b0000001100000100, 16'b0011111111101101}), // first step of cordic verified w/ arctang
  .s_axis_cartesian_tdata({thetaSin_w, thetaCos_w}),
  .m_axis_dout_tvalid(cordic_dout_tvalid_w),            
  .m_axis_dout_tdata(cordic_dout_tdata_w)              // output wire [15 : 0] m_axis_dout_tdata
);


thetaTangent  #(
    .POINTS_PER_LINE_P(POINTS_PER_LINE_P),
    .NUMBER_OF_FRAMES_P(NUMBER_OF_FRAMES_P),
    .THETAMAX_P(THETAMAX_P)
) thetaTangent_uut(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .theta_iteration_valid_i(theta_iteration_valid_r),//control the iteration to compute the tangent for the cordic
    .theta_iteration_i(theta_iteration_r),

    .thetaCos_valid_o(thetaCos_valid_w),
    .thetaSin_valid_o(thetaSin_valid_w),
    .thetaCos_o(thetaCos_w),
    .thetaSin_o(thetaSin_w)
);

endmodule
