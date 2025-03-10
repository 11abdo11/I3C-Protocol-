/*//////////////////////////////////////////////////////////////////////////////////
==================================================================================
 MIXEL GP 2024 LIBRARY
 Copyright (c) 2023 Mixel, Inc.  All Rights Reserved.
 CONFIDENTIAL AND PROPRIETARY SOFTWARE/DATA OF MIXEL and ASU 2024 GP, INC.

 Authors: Omar Maghraby
 
 Revision: 

 Version : 1.0

 Create Date: 
 Design Name:  
 Module Name:  

==================================================================================

  STATEMENT OF USE

  This information contains confidential and proprietary information of MIXEL.
  No part of this information may be reproduced, transmitted, transcribed,
  stored in a retrieval system, or translated into any human or computer
  language, in any form or by any means, electronic, mechanical, magnetic,
  optical, chemical, manual, or otherwise, without the prior written permission
  of MIXEL.  This information was prepared for Garduation Project purpose and is for
  use by MIXEL Engineers only.  MIXEL and ASU 2023 GP reserves the right 
  to make changes in the information at any time and without notice.

==================================================================================
//////////////////////////////////////////////////////////////////////////////////*/
module tx_t(

input                     i_sys_clk,
input                     i_sys_rst,
input                     i_sclgen_scl,
input                     i_sclgen_scl_pos_edge,
input                     i_sclgen_scl_neg_edge,
input                     i_ddrccc_tx_en,
input         [2:0]       i_ddrccc_tx_mode,
input         [7:0]       i_regf_tx_parallel_data,
input         [4:0]       i_crc_crc_value,

output reg                o_sdahnd_tgt_serial_data, //SDA
output reg                o_ddrccc_tx_mode_done,
output reg                o_crc_en, 
output reg    [7:0]       o_crc_parallel_data,
output reg                o_crc_data_valid,
output reg                o_crc_last_byte
 );



localparam    [2:0]     
                          PREAMBLE_ZERO           = 3'b000  ,   //After(cmd) Preamble value= zero-->ack        After(date) Preamble value= zero-->abort        
 
                          PREAMBLE_ONE            = 3'b001  ,   //After(cmd) Preamble value= one--> nack       After(date) Preamble value= one-->follow 

                          SERIALIZING_BYTE        = 3'b011  ,     
    
                          CRC_TOKEN               = 3'b010  ,
    
                          PAR_VALUE               = 3'b110  ,
    
                          CRC_VALUE               = 3'b111  ;
                     

wire   SCL_edges;
assign SCL_edges = (i_sclgen_scl_pos_edge || i_sclgen_scl_neg_edge);


reg  [2:0]  count;   

reg         byte_num;

reg  [15:0] data_parity_calc; 
wire [1:0]  parity_value;


reg  [7:0] i_regf_tx_parallel_data_temp;
wire count_done;
assign count_done = (count==7)? 1'b1:1'b0 ;


/*always@(count) begin
  if (count==7)
    i_regf_tx_parallel_data_temp = i_regf_tx_parallel_data;
  
end*/



reg data_mode;

/*always @(posedge i_sys_clk or negedge i_sys_rst)  
begin
  if(!i_sys_rst)

  begin
    data_parity_calc <= 'b0;
  end

  else if ((byte_num == 0) && data_mode/*&& (count_done))
   data_parity_calc[15:8] <= i_regf_tx_parallel_data_temp;

  else if ((byte_num == 1) && data_mode)
   data_parity_calc[7 :0]  <= i_regf_tx_parallel_data_temp;


end*/


reg [3:0] crc_token_value  = 4'b1100;

assign parity_value[1] =  data_parity_calc[15]^data_parity_calc[13]^data_parity_calc[11]^data_parity_calc[9]^data_parity_calc[7]^data_parity_calc[5]^data_parity_calc[3]^data_parity_calc[1] ;     
assign parity_value[0] =  data_parity_calc[14]^data_parity_calc[12]^data_parity_calc[10]^data_parity_calc[8]^data_parity_calc[6]^data_parity_calc[4]^data_parity_calc[2]^data_parity_calc[0]^1'b1 ; 

always @(posedge i_sys_clk or negedge i_sys_rst) 
begin

  if (!i_sys_rst) 
   begin
    o_sdahnd_tgt_serial_data <= 1'b1;
    o_ddrccc_tx_mode_done    <= 1'b0;
    o_crc_en               <= 1'b1; 
  o_crc_parallel_data      <= 8'b0;
  count            <= 1'b0;
		  o_crc_data_valid <= 0;
                  o_crc_last_byte <= 0;

   end

   else if (i_ddrccc_tx_en)
    begin
      // o_sdahnd_tgt_serial_data <= 1'b0;
       o_ddrccc_tx_mode_done    <= 1'b0;
       o_crc_data_valid <= 0;
     //count          <= 1'b0;
       
       data_mode              <=1'b1;
     
     case (i_ddrccc_tx_mode)
         
         PREAMBLE_ZERO: 
                   begin
              
              if (SCL_edges)
               begin
                      o_sdahnd_tgt_serial_data <= 1'b0;
                      o_ddrccc_tx_mode_done    <= 1'b1; 
                      
                   end 
              else
                begin
                  count<='d0;
                  byte_num                 <= 1'b0;
                end
                 
                end   

         PREAMBLE_ONE: 
                 begin
              
              if (SCL_edges)
               begin
                      //count                    <= 'b0;
                      //byte_num                 <= 1'b0;
                      o_sdahnd_tgt_serial_data <= 1;
                      o_ddrccc_tx_mode_done    <= 1'b1; 
               end
              else
                begin
                  count<='d0;
                  byte_num                 <= 1'b0;
                end
               end     


         SERIALIZING_BYTE: 
                      begin 
                        o_crc_parallel_data<= i_regf_tx_parallel_data;
                        o_crc_en<=1'b1;
                        data_mode <=1'b1;

                        if (SCL_edges)
                         begin
                            o_sdahnd_tgt_serial_data <= i_regf_tx_parallel_data['d7-count];  
                            count                    <= count +1'b1;
                            if (count == 'd1)
                              o_crc_data_valid <= 1;

                            if (count=='d7) 
                              begin
                               count <= 'd0;
                               o_ddrccc_tx_mode_done<=1'b1;
        
                               
                              end
                        
                         end
                        
                      
                        else if (count=='d7)     //
                         begin

                           if (!byte_num) 
                                    begin
                                     data_parity_calc[15:8] <= i_regf_tx_parallel_data;
                                     byte_num <=1'b1;
                                    end
                                   else
                                   begin
                                     data_parity_calc[7 :0]  <= i_regf_tx_parallel_data;
                                     byte_num<=1'b0;
                                   end
                        end
                      
                      end


         CRC_TOKEN:     
                    begin
                        if (SCL_edges)
                         begin
                           o_crc_last_byte <= 1'b1;
                           o_sdahnd_tgt_serial_data<=crc_token_value['d3-count];  
                           count<=count +1'b1;
                           if (count=='d3) 
                          begin
                            count<='d0;
                            o_ddrccc_tx_mode_done<=1'b1;
                          end
  
                         end
                        else
                         begin
                          o_ddrccc_tx_mode_done<=1'b0;
                         end
                      
                   
                    end  


         PAR_VALUE:

                  begin
                        if (SCL_edges)
                         begin

                           o_sdahnd_tgt_serial_data<=parity_value['d1-count]; 
                           count<=count +1'b1;
                           if (count==1'd1) 
                          begin
                            o_crc_last_byte <= 1'b0;
                            count<='d0;
                            o_ddrccc_tx_mode_done<=1'b1;
                          end
  
                         end
                        else
                         begin
                          o_ddrccc_tx_mode_done<=1'b0;
                         end
                      
              
                    end  

         CRC_VALUE:        
              begin
                        if (SCL_edges)
                         begin
                           o_crc_en<=1'b0;
                           o_sdahnd_tgt_serial_data<=i_crc_crc_value['d4-count];  
                           count<=count +1'b1;
                           if (count=='d4) 
                          begin
                            count<='d0;
                            o_ddrccc_tx_mode_done<=1'b1;
                          end
  
                         end
                        else
                         begin
                          o_ddrccc_tx_mode_done<=1'b0;
                         end
                      
                 
                    end  

      default :      begin
                      o_sdahnd_tgt_serial_data <= 1'b0;
                      o_ddrccc_tx_mode_done    <= 1'b0;
                      o_crc_en                 <= 1'b0; 
                      o_crc_parallel_data      <= 8'b0;
                      count                    <= 1'b0;
                      byte_num                 <= 1'b0;
               end
     

     endcase

    end
    
    else
      begin
     o_sdahnd_tgt_serial_data <= 1'b1;
     o_ddrccc_tx_mode_done    <= 1'b0;
     o_crc_en <= 1'b1;
     o_crc_last_byte <= 1'b0;
     end
end








endmodule 