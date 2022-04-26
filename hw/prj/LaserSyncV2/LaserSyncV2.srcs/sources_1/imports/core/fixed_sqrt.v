`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2022 05:27:20 PM
// Design Name: 
// Module Name: fixed_sqrt
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


module fixed_sqrt #(
    parameter   Q       = 16,   //must be a multiple of 2
    parameter   N       = 32,  
    localparam  ITER    = (N+Q) >> 1
)(
    input           clk_i,
    input           nrst_i,
    input           valid_i,  
    input   [N-1:0] opA_i,    
    
    output          ready_o,   
    output  [N-1:0] result_o   
    //output  [N-1:0] rem_o    
);

reg [N-1:0] radCpy_r;   
reg [N-1:0] radCpy_next_r;   
reg [N-1:0] auxRoot_r;
reg [N-1:0] auxRoot_next_r; 
reg [N+1:0] acc_r;
reg [N+1:0] acc_next_r;  
reg [N+1:0] checkSign_r;  

reg [clog2(ITER)-1:0] iterator_r;     

reg compute_r;
reg done_r;	

assign ready_o  = done_r;
assign result_o = auxRoot_next_r;
//assign rem_o    = acc_next_r[N+1:2];  


always @(*) begin
    checkSign_r = acc_r - {auxRoot_r, 2'b01};
    if (checkSign_r[N+1] == 0) begin 
        {acc_next_r, radCpy_next_r} = {checkSign_r[N-1:0], radCpy_r, 2'b0};
        auxRoot_next_r              = {auxRoot_r[N-2:0], 1'b1};
    end else begin
        {acc_next_r, radCpy_next_r} = {acc_r[N-1:0], radCpy_r, 2'b0};
        auxRoot_next_r              = auxRoot_r << 1;
    end
end

always @(posedge clk_i or negedge nrst_i) begin
    if(~nrst_i) begin
        compute_r           <= 1'b0;
        done_r              <= 1'b0;
        iterator_r          <= 0;
        auxRoot_r           <= 0;
        acc_r               <= 0;
        radCpy_r            <= 0;
    end
    else begin
        if(valid_i) begin
            if(~compute_r) begin
                compute_r           <= 1'b1;
                done_r              <= 1'b0;
                iterator_r          <= 0;
                auxRoot_r           <= 0;
                acc_r               <= 0;
                radCpy_r            <= 0;
                {acc_r, radCpy_r}   <= {{N{1'b0}}, opA_i, 2'b0};
            end
            else if(~done_r) begin
                if (iterator_r >= ITER-1) begin 
                    done_r  <= 1'b1; 
                end 
                else begin 
                    iterator_r  <= iterator_r + 1;
                    radCpy_r    <= radCpy_next_r;
                    acc_r       <= acc_next_r;
                    auxRoot_r   <= auxRoot_next_r;
                end
            end
        end
        else begin
            compute_r   <= 1'b0;
            done_r      <= 1'b0;    
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