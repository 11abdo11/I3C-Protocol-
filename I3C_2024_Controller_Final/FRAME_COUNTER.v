
module frame_counter(
    input  wire        i_fcnt_clk         ,
    input  wire        i_fcnt_rst_n       ,
    input  wire        i_fcnt_en          ,
    input  wire        i_regf_CMD_ATTR    ,     // HDR 1 bit only selects bit [0] (1 for immediate and 0 for regular)
    input  wire [15:0] i_regf_DATA_LEN    ,     // HDR 
    input  wire [2:0]  i_regf_DTT         ,     // HDR
    input  wire [5:0]  i_cnt_bit_count    ,     // HDR
    //input  wire        i_ccc_Direct_Broadcast_n ,     // HDR  1 for direct and 0 for Broadcast
    input  wire        i_bitcnt_toggle    , 
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
                    // stay here for 20 bits
                end 
                else begin 
                    if ((i_cnt_bit_count == 'd6 || i_cnt_bit_count == 'd16) && i_bitcnt_toggle) begin 
                        count = count - 1 ;
                    end 
                end 
            end 
            else begin                                  // Disabled to load the count value
                o_cccnt_last_frame = 1'b0 ;
                if (!i_regf_CMD_ATTR) begin             // regular 
                    count = i_regf_DATA_LEN + 1 ;       // fixed whether Direct or Broadcast
                end
                else begin //immediate 
                    case (i_regf_DTT) 
                        3'd0 : count = 1 ;
                        3'd1 : count = 2 ;
                        3'd2 : count = 3 ;
                        3'd3 : count = 4 ;
                        3'd4 : count = 5 ;
    
                        3'd5 : count = 2 ;
                        3'd6 : count = 3 ;
                        3'd7 : count = 4 ;
                    endcase 
                end 
            end  
        end 
    end 
endmodule 
