module bits_counter_target(
    input  wire       i_sys_clk              ,
    input  wire       i_rst_n                ,
    input  wire       i_bitcnt_en            ,  
    input  wire       i_scl_pos_edge         ,  
    input  wire       i_scl_neg_edge         ,
    input  wire       abort_or_end_reset     , 
    output reg        o_frcnt_toggle         ,
    output reg  [5:0] o_cnt_bit_count = 6'd0
    );

always @(posedge i_sys_clk or negedge i_rst_n) begin 
    if(~i_rst_n) begin
        o_cnt_bit_count <= 0 ;
    end
    else if (abort_or_end_reset)
      o_cnt_bit_count <= 6'd0 ; 
    else 
     begin
        if (i_bitcnt_en) begin 
            if (i_scl_neg_edge || i_scl_pos_edge) begin 
                if (o_cnt_bit_count == 6'd19) begin 
                    o_cnt_bit_count <= 6'd0 ;                     // from 0 to 19 it won't reach 20 
                end
                else begin 
                    o_cnt_bit_count <= o_cnt_bit_count + 1 ; 
                end  
            end 
        end 
        else begin 
            o_cnt_bit_count <= 6'd0 ;
        end 
    end
end

always @(negedge i_sys_clk) begin 
    if ((o_cnt_bit_count == 'd6 || o_cnt_bit_count == 'd16) && (!i_scl_pos_edge && !i_scl_neg_edge)) begin
        o_frcnt_toggle = 1'b1 ;
    end
    else begin 
        o_frcnt_toggle = 1'b0 ;
    end 
end

endmodule 
