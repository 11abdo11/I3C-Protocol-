/*//////////////////////////////////////////////////////////////////////////////////
==================================================================================
 MIXEL GP 2024 LIBRARY
 Copyright (c) 2023 Mixel, Inc.  All Rights Reserved.
 CONFIDENTIAL AND PROPRIETARY SOFTWARE/DATA OF MIXEL and ASU 2024 GP, INC.

 Authors: Abdelrahman Gaber Gharib
   
==================================================================================

  STATEMENT OF USE

  This information contains confidential and proprietary information of MIXEL.
  No part of this information may be reproduced, transmitted, transcribed,
  stored in a retrieval system, or translated into any human or computer
  language, in any form or by any means, electronic, mechanical, magnetic,
  optical, chemical, manual, or otherwise, without the prior written permission
  of MIXEL.  This information was prepared for Garduation Project purpose and is for
  use by MIXEL Engineers only.  MIXEL and ASU 2024 GP reserves the right 
  to make changes in the information at any time and without notice.

==================================================================================
//////////////////////////////////////////////////////////////////////////////////*/

module frame_counter_target(
    input  wire        i_fcnt_clk         ,
    input  wire        i_fcnt_rst_n       ,
    input  wire        i_fcnt_en          ,
    input  wire [15:0] i_regf_MAX_RD_LEN    ,     // HDR
    input  wire [15:0] i_regf_MAX_WR_LEN    ,     // HDR  
    input  wire [5:0]  i_cnt_bit_count    ,     // HDR
    input  wire        i_bitcnt_toggle    , 
    input  wire        i_nt_rnw               ,
    output reg         o_cccnt_last_frame       // HDR
    );
	
reg [15:0] count = 16'd0 ;
//wire       count_done   ;

    always @(posedge i_fcnt_clk or negedge i_fcnt_rst_n) begin 
        if (!i_fcnt_rst_n) begin 
            o_cccnt_last_frame = 1'b0 ;
            count              = 16'd0 ;
        end 
        else begin 
            if(i_fcnt_en) begin 
                if (count == 16'd0) begin 
                    o_cccnt_last_frame = 1'b1 ;
                end 
                else begin 
                    if ((i_cnt_bit_count == 'd6 || i_cnt_bit_count == 'd16) && i_bitcnt_toggle) begin 
                        count = count - 1 ;
                    end 
                end 
            end 
            else begin                                 
                o_cccnt_last_frame = 1'b0 ;             
                count = (i_nt_rnw)? i_regf_MAX_RD_LEN : i_regf_MAX_WR_LEN ;       
                end 
        end 
    end 
endmodule 