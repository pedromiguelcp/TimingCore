`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2022 09:56:34 AM
// Design Name: 
// Module Name: new_fixed_mul
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


module new_fixed_mul #(
    parameter Q = 16,
    parameter N = 32
)(
    input   clk_i, 
    input   nrst_i,
    input   signed	[(N-1):0]  opA_i, 
    input   signed	[(N-1):0]  opB_i, 
    input   valid_i, 
    
    /*output  o_busy,
	output  o_done, */
    output  signed	[(N-1):0]   result_o, 
    output  ready_o
);

reg	[clog2(N)-1:0]	mult_it_r;
reg	[N-1:0]	        opA_r;
reg	[N-1:0]	        opB_r;
reg	[N+N-1:0]	    result_r;
reg			        ready_r;
reg                 busy_r;

wire	last_step_w;
assign	last_step_w = (mult_it_r == 0);

wire	[N-1:0]	soft_mult_w;
assign	soft_mult_w = (opB_r[0] ? opA_r : 0);

wire [N+N-1:0] pre_result_w;
assign pre_result_w = result_r[N+N-1:0] + {1'b1, {(N-2){1'b0}}, 1'b1, {(N){1'b0}}};

assign result_o =  {(opA_i[N-1] ^ opB_i[N-1]), pre_result_w[N-2+Q : Q]};
assign ready_o =   ready_r;



always @(posedge clk_i or negedge nrst_i) begin
    if (~nrst_i) begin
        ready_r <= 1'b0;
        busy_r <= 1'b0;
    end 
    else begin
        if(valid_i) begin
            ready_r <= last_step_w;
            busy_r <= 1'b1;
        end
        else begin
            ready_r <= 1'b0;
            busy_r <= 1'b0;
        end
    end
end

always @(posedge clk_i or negedge nrst_i) begin
    if (~nrst_i) begin
        mult_it_r <= N-1;
        result_r <= 0;
        opA_r <= 0;
        opB_r <= 0;
    end 
    else begin
        if(busy_r) begin
            if (~ready_r) begin
                opB_r <= (opB_r >> 1);
                result_r[N-2:0] <= result_r[N-1:1];

                if(~last_step_w) begin
                    result_r[N+N-1:N-1] <=   {1'b0,result_r[N+N-1:N]} +
                                            { 1'b0, !soft_mult_w[N-1], soft_mult_w[N-2:0] };
                                                
                    mult_it_r <= mult_it_r - 1;
                end
                else begin
                    result_r[N+N-1:N-1] <=   { 1'b0, result_r[N+N-1:N]} +
                                                { 1'b0, soft_mult_w[N-1], ~soft_mult_w[N-2:0] };
                end
            end
        end
        else begin
            mult_it_r <= N-1;
            result_r <= 0;
            opA_r <= {1'b0, opA_i[N-2:0]};
            opB_r <= {1'b0, opB_i[N-2:0]};
        end
    end
end


function integer clog2;
input integer value;
begin  
    value = value-1;
    for (clog2=0; value>0; clog2=clog2+1)
        value = value>>1;
end  
endfunction

endmodule
