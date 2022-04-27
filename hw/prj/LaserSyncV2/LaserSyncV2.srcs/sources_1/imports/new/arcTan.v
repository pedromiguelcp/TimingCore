`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2022 10:07:26 AM
// Design Name: 
// Module Name: arcTan
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


module arcTan #(
		
    localparam	IW=16,      
    localparam	NSTAGES=18,
    localparam	WW=21,      // working bit-width
    localparam	PW=26	    // ph_rase bit-width
		
)(
	input                       clk_i,
    input                       nrst_i,
    input                       valid_i,
	input   signed	[(IW-1):0]	cos_i,
    input   signed	[(IW-1):0]	sin_i,
	output          [(IW-1):0]	phase_o,
	output                      atang_valid_o
);

wire	signed  [(WW-1):0]	    cos_w;
wire	signed  [(WW-1):0]	    sin_w;
reg	    signed  [(WW-1):0]	    x_r	    [0:NSTAGES];
reg	    signed	[(WW-1):0]	    y_r	    [0:NSTAGES];
reg		        [(PW-1):0]	    ph_r    [0:NSTAGES];
reg		        [(NSTAGES):0]   atang_valid_r;

wire	[25:0]	cordic_angles_w [0:(NSTAGES-1)];

// Sign extension, more precision, and support cordic gain (1.6)
assign	cos_w = { {(2){cos_i[(IW-1)]}}, cos_i, {(WW-IW-2){1'b0}} };
assign	sin_w = { {(2){sin_i[(IW-1)]}}, sin_i, {(WW-IW-2){1'b0}} };

assign phase_o          = ph_r[NSTAGES][(PW-2):9];
assign atang_valid_o    = atang_valid_r[NSTAGES];

// FIFO for output valid signal
always @(posedge clk_i or negedge nrst_i) begin
    if (~nrst_i) begin
        atang_valid_r <= 0;
    end
    else begin
        atang_valid_r <= { atang_valid_r[(NSTAGES-1):0], valid_i };
    end
end

// Pre-CORDIC rotation, Map to +/- 45 degrees
always @(posedge clk_i or negedge nrst_i) begin
    if (~nrst_i) begin
        x_r[0] <= 0;
        y_r[0] <= 0;
        ph_r[0] <= 0;
    end 
    else if (valid_i) begin
        case({cos_i[IW-1], sin_i[IW-1]})
            2'b01: begin // Rotate -315 deg
                x_r[0]  <=  cos_w - sin_w;
                y_r[0]  <=  cos_w + sin_w;
                ph_r[0] <= 26'b01010111111101101110111110;
            end
                
            2'b10: begin // Rotate -135 deg
                x_r[0]  <= -cos_w + sin_w;
                y_r[0]  <= -cos_w - sin_w;
                ph_r[0] <= 26'b00100101101100101111100011;
            end
                
            2'b11: begin // Rotate -225 deg
                x_r[0]  <= -cos_w - sin_w;
                y_r[0]  <=  cos_w - sin_w;
                ph_r[0] <= 26'b00111110110101001111010001;
            end
                
            // 2'b00:
            default: begin // Rotate -45 deg
                x_r[0]  <=  cos_w + sin_w;
                y_r[0]  <=  sin_w - cos_w;
                ph_r[0] <= 26'b00001100100100001111110110;
            end                
        endcase
    end
end

//                             4b.22b
//                             26'b01010111111101101110111110  // 5.497787143  rad (315 deg)
//                             26'b00111110110101001111010001  // 3.926990817  rad (225 deg)
//                             26'b00100101101100101111100011  // 2.356194490  rad (135 deg)
//                             26'b00001100100100001111110110  // 0.785398163  rad (45 deg)
assign	cordic_angles_w[ 0] =  26'b00000111011010110001100111; // 0.463647605  rad (26.5650 deg)
assign	cordic_angles_w[ 1] =  26'b00000011111010110110111010; // 0.244978654  rad (14.0362 deg)
assign	cordic_angles_w[ 2] =  26'b00000001111111010101101110; // 0.124354988  rad ( 7.1250 deg)
assign	cordic_angles_w[ 3] =  26'b00000000111111111010101011; // 0.062418803  rad ( 3.5763 deg)
assign	cordic_angles_w[ 4] =  26'b00000000011111111111010101; // 0.031239840  rad ( 1.7899 deg)
assign	cordic_angles_w[ 5] =  26'b00000000001111111111111010; // 0.015623733  rad ( 0.8951 deg)
assign	cordic_angles_w[ 6] =  26'b00000000000111111111111111; // 0.007812338  rad ( 0.4476 deg)
assign	cordic_angles_w[ 7] =  26'b00000000000011111111111111; // 0.003906238  rad ( 0.2238 deg)
assign	cordic_angles_w[ 8] =  26'b00000000000010000000000000; // 0.001953128  rad ( 0.1119 deg)
assign	cordic_angles_w[ 9] =  26'b00000000000001000000000000; // 0.000976564  rad ( 0.0559 deg)
assign	cordic_angles_w[10] =  26'b00000000000000011111111111; // 0.000488273  rad ( 0.0279 deg)
assign	cordic_angles_w[11] =  26'b00000000000000001111111111; // 0.000244136  rad ( 0.0139 deg)
assign	cordic_angles_w[12] =  26'b00000000000000000111111111; // 0.000122068  rad ( 0.0069 deg)
assign	cordic_angles_w[13] =  26'b00000000000000000011111111; // 0.000061034  rad ( 0.0034 deg)
assign	cordic_angles_w[14] =  26'b00000000000000000010000000; // 0.000030525  rad ( 0.0017 deg)
assign	cordic_angles_w[15] =  26'b00000000000000000000111111; // 0.000015254  rad ( 0.0008 deg)
assign	cordic_angles_w[16] =  26'b00000000000000000000011111; // 0.000007627  rad ( 0.0004 deg)
assign	cordic_angles_w[17] =  26'b00000000000000000000010000; // 0.000003822  rad ( 0.0002 deg)


// CORDIC rotations
genvar	i;
generate 
    for(i=0; i<NSTAGES; i=i+1) begin : CORDIC_ROT

        always @(posedge clk_i or negedge nrst_i) begin
            if (~nrst_i) begin
                x_r[i+1]    <= 0;
                y_r[i+1]    <= 0;
                ph_r[i+1]   <= 0;
                
            end 
            else if (valid_i) begin
                
                if ((cordic_angles_w[i] == 0)||(i >= WW)) begin // forward
                    x_r[i+1]    <= x_r[i];
                    y_r[i+1]    <= y_r[i];
                    ph_r[i+1]   <= ph_r[i];
                end 
                else if (y_r[i][WW-1]) begin// sin below x axis
                    x_r[i+1]    <= x_r[i]   - (y_r[i]>>>(i+1));
                    y_r[i+1]    <= y_r[i]   + (x_r[i]>>>(i+1));
                    ph_r[i+1]   <= ph_r[i]  - cordic_angles_w[i];
                end 
                else begin
                    x_r[i+1]    <= x_r[i]   + (y_r[i]>>>(i+1));
                    y_r[i+1]    <= y_r[i]   - (x_r[i]>>>(i+1));
                    ph_r[i+1]   <= ph_r[i]  + cordic_angles_w[i];
                end
            end
        end
    end 
endgenerate

endmodule
