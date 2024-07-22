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

module Restart_Detector (

input	   i_sys_clk ,
input 	   i_sys_rst ,
input 	   i_scl ,
input      i_sda ,

output reg o_engine_done
); 

reg [1:0] count;
reg [2:0] state;
		
always @ (posedge i_sys_clk , negedge i_sys_rst)
 begin
  if(!i_sys_rst)
   begin
    count <= 0;
    state <= 0;
   end

  else
   begin

 case (state)
 
0:begin
     o_engine_done <= 0;
     if (i_sda && i_scl && count != 1)
      count <= count + 1;
     else if(i_sda && !i_scl && count == 1)
      begin
       state <= 1;
       count <= 0;
      end
     else
      state <= 0;
   end

1:begin
     if (count != 1)
      count <= count + 1;
     else if(!i_sda && !i_scl && count == 1)
      begin
       state <= 2;
       count <= 0;
      end
     else
      state <= 0;
   end

2:begin
     if (count != 1)
      count <= count + 1;
     else if(i_sda && !i_scl && count == 1)
      begin
       state <= 3;
       count <= 0;
      end
     else
      state <= 0;
   end

3:begin
     if (count != 1)
      count <= count + 1;
     else if(!i_sda && !i_scl && count == 1)
      begin
       state <= 4;
       count <= 0;
      end
     else
      state <= 0;
   end

4:begin
     if (count != 1)
      count <= count + 1;
     else if(i_sda && !i_scl && count == 1)
      begin
       state <= 5;
       count <= 0;
      end
     else
      state <= 0;
   end 
 
5:begin
     if (i_sda && i_scl && count != 1)
      count <= count + 1;
     else if(count == 1)
      begin
       o_engine_done <= 1;
       count <= 0;
       state <= 0;
      end
     else
      state <= 0;
   end
endcase
end
end
 endmodule
