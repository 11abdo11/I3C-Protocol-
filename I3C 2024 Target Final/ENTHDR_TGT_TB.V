`timescale 1us / 1ps
`default_nettype none

module ENTHDR_TGT_TB ();

parameter CLK_PERIOD  = 10;

//--------------------------------------------------- Testbench Wires --------------------------------------------//

    // Clock and reset signals
    reg          i_clk_tb           		;
    reg          i_rst_n_tb         		;  
    
    // Design Inputs   
    reg          i_controller_en_tb     	;        
    reg          i_i3c_i2c_sel_tb 			;
    reg          i_hdr_en_tb				; // enable signal for the hdr mode
    reg          i_ccc_en_dis_hj_tb			;


    
    reg   [7:0]  i_regf_config  ;
    reg          i_data_config_mux_sel;                 //1: to write configurations to the controller ,     0:i3c blocks to access reg file  
    reg   [11:0] i_regf_wr_address_config;
    reg          i_regf_wr_en_config     ;
    reg          i_regf_rd_en_config     ;

    reg          i_ccc_done_tb         		; // done signal from CCC block
    reg          i_ddr_mode_done_tb    		; // done signal from ddr block

 
    wire         sda_tb                		;

   
    // Design Output
    wire         o_sdr_rx_valid_tb     		; // output to host >> valid data are loaded
    wire         o_ctrl_done_tb        		; // sdr block done signal
    wire         scl_tb                		;
    wire         o_ddrmode_enable_tb        ; // enable for the ddr block
    wire         o_ccc_enable_tb            ; // enable for the CCC block
    wire  [11:0]  o_regf_address_special_tb  ; // regf special address

    ///////////targt///////////////////////////////////
    reg    i_tgt_engine_en_tb           ;
    wire   o_tgt_sdahnd_sda_tb           ;
    wire   o_tgt_pp_od_sdahand_tb        ;
    wire   o_tgt_engine_done_tb          ;


//--------------------------------------------------- Internal Signals --------------------------------------------//
      
    // locally driven value
    //assign sda_tb   = o_tgt_sdahnd_sda_tb 			;



//--------------------------------------------------- Configuration Values --------------------------------------------//
 parameter EXPECTED_BROADCAST = 8'b11111100; // 'h7E+ R/W bit = 0
    parameter EXPECTED_ENTHDR0 = 9'b001000000;
    


localparam  [11:0]  config_location = 12'd1000;
//reg [11:0] config_location;
localparam  [2:0]   CMD_ATTR 	= 3'b000;
localparam	[3:0]	TID 		= 4'b0000;
localparam	[7:0]	CMD 		= 8'b0;
localparam			CP 			= 1'b0;	 //normal transaction
localparam	[4:0]   DEV_INDEX   = 5'b0;
localparam	[1:0]   RESERVED    = 2'b00;
localparam	[2:0]   DTT         = 3'b000;			
localparam	[2:0]   MODE 		= 3'd6; // hdr mode
localparam			TOC  		= 1'b1;  //exit pattern
localparam			WROC 		= 1'b0;
localparam			RnW 		= 1'b0;
localparam	[7:0]	DEF_BYTE 	= 8'b0;
localparam	[7:0]	DATA_TWO 	= 8'b10001010;
localparam	[7:0]   DATA_THREE  = 8'b01011010; 
localparam	[7:0]   DATA_FOUR   = 8'b11111111;  
//--------------------------------------------------- Clock Generation --------------------------------------------//

always #(CLK_PERIOD/2) i_clk_tb = ~i_clk_tb;   


//--------------------------------------------------- Initial Block ------------------------------------------------//
initial begin
    i_data_config_mux_sel   = 1'b0;
//Signals Initialization
	initialize();
	     
//Reset
	reset();        
        
// Test Case 1: enabling the hdr mode to send the ENTHDR CCC and then enabling the HDR engine     
     
   // Writing configurations
     	write_configurations();
     	i_data_config_mux_sel   = 1'b0;


     // INPUTS 
        i_controller_en_tb = 1'b1 ;
        i_i3c_i2c_sel_tb   = 1'b1;
        i_hdr_en_tb        = 1'b1;
        i_tgt_engine_en_tb    = 1'b1;

         
       

        @(negedge o_tgt_engine_done_tb)
         i_tgt_engine_en_tb    = 1'b0;

        #CLK_PERIOD
        i_controller_en_tb = 1'b0 ;    


         #100000
         $stop ;
         
         


 
end 
pullup(sda_tb);
//--------------------------------------------------- Tasks --------------------------------------------------------//
task initialize; 
	begin
		i_clk_tb 				= 1'b0;
		i_rst_n_tb 				= 1'b1;
		i_i3c_i2c_sel_tb        = 1'b1;  //i3c mode
		i_controller_en_tb      = 1'b0;
		i_hdr_en_tb				= 1'b0;
		i_ccc_en_dis_hj_tb      = 1'b0;
        i_ccc_done_tb			= 1'b0;
        i_ddr_mode_done_tb      = 1'b0;
		
		//i_ddr_pp_od_tb			= 1'b0;
		//i_ddr_pp_od_tb			= 1'b0;
		i_data_config_mux_sel   = 1'b0;
		i_regf_rd_en_config   	= 1'b0;								
    	i_regf_wr_en_config   	= 1'b0;

	end
	endtask

task reset;
	begin
	    i_rst_n_tb 		        = 1'b1;
		# (CLK_PERIOD)
		i_rst_n_tb 				= 1'b0; // activated
		# (CLK_PERIOD)
		i_rst_n_tb 				= 1'b1; // de-activated

	end	
	endtask

task write_configurations;
	begin

// DWORD 0
	 //@(negedge i_clk_tb)
	 #(2*CLK_PERIOD)
	i_regf_rd_en_config   = 1'b0																			;
    i_regf_wr_en_config   = 1'b1 																		    ;
    i_data_config_mux_sel = 1'b1																		    ;  //1: to write configurations to the controller ,     0:i3c blocks to access reg file


		i_regf_config    = { CMD[0] , TID , CMD_ATTR }  												    ;
    	i_regf_wr_address_config = config_location 															;
    	    
      #(2*CLK_PERIOD) 
      //@(negedge i_clk_tb)
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = { CP , CMD[7:1] } 															    ;
    	i_regf_wr_address_config = config_location + 'd1 														;

      #(2*CLK_PERIOD) 
      //@(negedge i_clk_tb)
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = { DTT[0] , RESERVED , DEV_INDEX }  											    ;		    
    	i_regf_wr_address_config = config_location + 'd2 														;

      #(2*CLK_PERIOD) 
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = { TOC , WROC , RnW , MODE , DTT[2:1]} 										;
    	i_regf_wr_address_config = config_location + 'd3 														;

  // DWORD 1
       #(2*CLK_PERIOD) ; 
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = DEF_BYTE     																;
    	i_regf_wr_address_config = config_location + 'd4 														;	

       #(2*CLK_PERIOD) ;
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = DATA_TWO     																;
    	i_regf_wr_address_config = config_location + 'd5 														;

       #(2*CLK_PERIOD) ;
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = DATA_THREE     																;
    	i_regf_wr_address_config = config_location + 'd6 														;

       #(2*CLK_PERIOD) ;
      	//i_regf_wr_en_config   = 1'b1 																		; 
		i_regf_config    = DATA_FOUR     																;
    	i_regf_wr_address_config = config_location + 'd7 														;


  
        #(CLK_PERIOD) ;

	end
endtask



//--------------------------------------------------- Design Instantiation -----------------------------------------//
ENTHDR_CTRL_TGT_top DUT (
 .i_sdr_clk           		(i_clk_tb), 
 .i_sdr_rst_n         		(i_rst_n_tb), 
 .i_controller_en     		(i_controller_en_tb), 
 .i_i3c_i2c_sel       		(i_i3c_i2c_sel_tb), 
 .i_ccc_en_dis_hj     		(i_ccc_en_dis_hj_tb), 

 .i_regf_config        (i_regf_config)					,
 .i_data_config_mux_sel     (i_data_config_mux_sel)					,  //1: to write configurations to the controller ,     0:i3c blocks to access reg file  
 .i_regf_wr_address_config  (i_regf_wr_address_config)					,
 .i_regf_wr_en_config       (i_regf_wr_en_config)					,
 .i_regf_rd_en_config       (i_regf_rd_en_config)                   ,  
 //.i_hdr_en            		(i_hdr_en_tb), 
 


 .sda                 		(sda_tb),


 //.o_regf_address_special  	(o_regf_address_special_tb),
 .scl                 		(scl_tb),
 .o_sdr_rx_valid      		(o_sdr_rx_valid_tb),
 .o_ctrl_done               (o_ctrl_done_tb) ,

 .i_tgt_engine_en           (i_tgt_engine_en_tb), 
 .o_tgt_sdahnd_sda          (o_tgt_sdahnd_sda_tb),
 .o_tgt_pp_od_sdahand       (o_tgt_pp_od_sdahand_tb),
 .o_tgt_engine_done         (o_tgt_engine_done_tb)
 


 ); 
	

    
endmodule
`default_nettype wire 

