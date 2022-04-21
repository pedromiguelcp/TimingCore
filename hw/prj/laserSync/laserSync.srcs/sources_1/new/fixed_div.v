`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 10:47:18 AM
// Design Name: 
// Module Name: fixed_div
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


module fixed_div#(
    parameter Q = 15,
    parameter N = 32
)(
    input 	        clk_i,
    input           nrst_i,
    input 	        valid_i,
    input 	[N-1:0] opA_i,
    input 	[N-1:0] opB_i,

    output 	        ready_o,
    output 	[N-1:0] result_o,
    output	        overflow_o
);

reg [2*N+Q-3:0] aux_quotient_r;
reg [N-1:0]     quotient_r;			
reg [N-2+Q:0]   aux_dividend_r;	
reg [2*N+Q-3:0]	aux_divisor_r;	

reg [N-1:0]     cnt_r;
                                    
reg             done_r;	
reg             sign_r;	
reg             overflow_r;
reg             compute_r;

assign result_o     = {sign_r, quotient_r[N-2:0]};			
assign ready_o      = done_r;
assign overflow_o   = overflow_r;

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        compute_r       <= 1'b0;
        done_r          <= 1'b0;		
        overflow_r      <= 1'b0;	
        sign_r          <= 1'b0;		
        aux_quotient_r  <= 0;
        quotient_r      <= 0;		
        aux_dividend_r  <= 0;
        aux_divisor_r   <= 0;
        cnt_r           <= 0; 		
    end
    else begin
        if(valid_i) begin
            if(~compute_r) begin
                compute_r       <= 1'b1;
                done_r          <= 1'b0;
                cnt_r           <= N+Q-1;                 
                aux_quotient_r  <= 0;                      
                aux_dividend_r  <= 0;							
                aux_divisor_r   <= 0;								
                overflow_r      <= 1'b0;						

                aux_dividend_r[N+Q-2:Q]         <= opA_i[N-2:0];				
                aux_divisor_r[2*N+Q-3:N+Q-1]    <= opB_i[N-2:0];		

                sign_r <= opA_i[N-1] ^ opB_i[N-1];
            end
            else if(~done_r) begin
                aux_divisor_r   <= aux_divisor_r >> 1;	
                cnt_r           <= cnt_r - 1;								

                if(aux_dividend_r >= aux_divisor_r) begin
                    aux_quotient_r[cnt_r]   <= 1'b1;										
                    aux_dividend_r          <= aux_dividend_r - aux_divisor_r;	
                end

                if(cnt_r == 0) begin
                    done_r      <= 1'b1;										
                    quotient_r  <= aux_quotient_r;		

                    if (aux_quotient_r[2*N+Q-3:N]>0) begin
                        overflow_r <= 1'b1;
                    end
                end           
            end
        end
        else begin
            compute_r   <= 1'b0;
            done_r      <= 1'b0;
        end
    end
end
endmodule
