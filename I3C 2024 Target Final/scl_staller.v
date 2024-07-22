`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Zyad Sobhy
// 
// Create Date: 02/17/2023 05:17:59 PM
// Design Name: 
// Module Name: scl_staller
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


module scl_staller(
input wire       i_stall_clk ,
input wire       i_stall_rst_n,
input wire       i_stall_flag,
input wire [3:0] i_stall_cycles,
output reg       o_stall_done,
output reg       o_scl_stall
    );
    
 reg [3:0] count = 4'b0 ;
    
always@(posedge i_stall_clk or negedge i_stall_rst_n)
 begin 
  if(~i_stall_rst_n)
    begin 
      o_scl_stall <= 1'b0 ;
      count <= 4'b0 ;
    end
  else if(i_stall_flag)
    begin
      if (i_stall_cycles == count)  
        begin
            o_scl_stall <= 1'b0 ;
            count <= 4'b0 ;
            o_stall_done <= 1'b1;
        end        
      else 
        begin      
             
count <= count + 4'b1 ;
        end
    end
  end
    
endmodule
