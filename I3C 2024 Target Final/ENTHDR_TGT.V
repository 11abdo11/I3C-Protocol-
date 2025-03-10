module ENTHDR_TGT (
	input wire  i_sys_clk ,
	input wire  i_sys_rst ,
	input wire  i_enigne_en , 
	input wire  i_sda ,
	input wire  i_scl ,
    input wire  i_scl_pos_edge  ,
    input wire  i_scl_neg_edge  ,

	output reg  o_sdahnd_sda ,
	output reg o_pp_od      , 
	output reg  sda_handle_en,
	output reg  o_engine_done 
);


parameter [6:0] broadcast_address = 7'H7E;
parameter [7:0] ENTHDR_CMD        = 8'H20;


localparam [2:0] IDLE    = 3'b000,
				 START   	= 3'b001,
				 ADDRESS = 3'b011,
				 ACK     = 3'b010,
				 ENTHDR  = 3'b110,
				 PARITY  =  3'b100;


reg        [2:0] state;

reg start_detected;

reg [1:0] tgt_count;
reg       ack_done; 

reg sda_old;

reg [2:0] count;

reg  [7:0] address_RnW_des;

reg  [7:0] enthdr_des;

reg o_engine_done_temp;

wire parity_calc;
assign parity_calc = ~^(enthdr_des);


always@(posedge i_sys_clk or negedge i_sys_rst)
  begin
   if (!i_sys_rst)
    begin
     sda_old<= 1'b0;
     start_detected<=1'b0;
     o_engine_done_temp <= 1'b0;
    end

   else if (i_enigne_en) 
    begin
     if(i_scl)
      begin
      sda_old<=i_sda;
      start_detected<=1'b0;
      if (sda_old && !i_sda)
       begin
        start_detected<=1'b1;
       end
      end
     else
      sda_old<=1'b0;
    end
   end
 
   /*else if (i_scl && sda_old && !i_sda)
     begin
      start_detected<=1'b1;
     end
   end*/

always @ (posedge i_sys_clk)
 begin
  o_engine_done <= o_engine_done_temp;
 end

always@(posedge i_sys_clk or negedge i_sys_rst)
 begin

     if(!i_sys_rst)
       begin
         state <= IDLE;
		 o_sdahnd_sda <= 1'b1;
		 sda_handle_en<=1'b1;
                 o_engine_done_temp <= 0;
                 o_pp_od <= 0;
		
       end
     
     else 
       begin
	   	 o_sdahnd_sda <= 1'bz;
		 o_engine_done_temp <=1'b0;
		 tgt_count<=0;
                 o_pp_od <= 0;
		 
		 //enthdr_des<=0;
		 //address_RnW_des<=0;

       
         case(state) 

          IDLE: begin
          	     if (i_enigne_en)
          	      begin
          	       if (start_detected)
          	        state<=START;
          	        count<=1'b0;
                  end
                  else
                    state<=IDLE;
                end

          START: begin
           		  if(i_sda)
          		  state<=ADDRESS;
          		 else begin
          		 state<=START;
          		 end

          		 end

         ADDRESS: begin

                    if (i_scl_pos_edge)
                     begin
                      address_RnW_des[7'd7-count]<= i_sda;
 					  count<= count+1;
 					  if (count==7'd7)
 					     count<= 1'b0;
 					 end
 					
 					
 					else if ((address_RnW_des=={broadcast_address,1'b0})&&i_scl_neg_edge) begin
 					     state <= ACK;
					     o_sdahnd_sda<=1'b0;
					     sda_handle_en<=1'b1;
                                             o_pp_od <= 1;
					end
 					   
 				     
 				    else 
 				     state<=ADDRESS;

       		       end

         ACK:begin
          	  o_sdahnd_sda<=1'b0;
                  o_pp_od <= 1;
		      if(i_scl_neg_edge)
               begin
	            o_sdahnd_sda<=1'b0;
                    o_pp_od <= 1;
		        state<= ENTHDR; 
               end



          	 /* 
          	  
		 
          	  o_sdahnd_sda<=1'b0;
          	  o_sda_handle_en<=1'b1;
	      if(i_scl_pos_edge)
               begin
                tgt_count<=tgt_count+1'b1;
	            o_sdahnd_sda<=1'b0;
		
               end

              if(i_scl_neg_edge)
               begin
                //tgt_count<=tgt_count+1'b1;
	            o_sdahnd_sda<=1'b0;
		
               end
              else if (tgt_count==2'd1)
               begin
                state<= ENTHDR;  
                o_sdahnd_sda<=1'bz;
                o_sda_handle_en<=1'b0;          
               end
     
              else 
               begin
            	state<= ACK;
     			
               end*/
		
             end

          ENTHDR:begin
 					tgt_count<=1'b0;
                     if (i_scl_pos_edge)
                      begin
                       enthdr_des[7'd7-count]<= i_sda;
 		 			   count<= count+1;
 		 			   if (count==7'd7)
 		 			   count<= 1'b0;
 		 			  end

 		 			 else if ((enthdr_des=={ENTHDR_CMD})&&i_scl_neg_edge)
 		 			   state <= PARITY;
 		 			 


 		 		    else 
 		 		     state<=ENTHDR;
       	 	    
       	 	    end
        
         PARITY:begin
                 if (i_scl_pos_edge)
                  begin
                 
                   if (parity_calc<=i_sda)
                    begin
                     o_engine_done_temp<=1'b1;
                     state<=IDLE;
                    end
                   else begin
                   o_engine_done_temp<=1'b0;
                     state<=IDLE;
                   end
                  end
       		     else 
       		       state<=PARITY;
         		end

         /*default:begin
         		 	 o_sdahnd_sda  <= 1'bz;
		             o_engine_done <=1'b0;
		             tgt_count     <=0;
		             count         <=0;
		             enthdr_des     <=0;
		             address_RnW_des<=0;
		
         		 end*/
        endcase
   end
  end
  endmodule 