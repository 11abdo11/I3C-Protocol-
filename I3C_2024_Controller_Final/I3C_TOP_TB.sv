import SYSTEM_PACKAGE ::*;
`timescale 1us / 1ps
`default_nettype none


module I3C_TOP_TB ();

//-----------------------------Testbench signals-------------------------------------//
  bit         i_sdr_clk_tb           		; // system clk
  bit         i_sdr_rst_n_tb         		; // asynch neg edge reset
  logic         i_controller_en_tb     		; // from device configuration of Controller/Target role
  logic         i_i3c_i2c_sel_tb       		; // sdr/i2c blocks selector
  logic         i_ccc_en_dis_hj_tb     		; //2023: (TBD) for enable/disable events to prevent Bus-Initialization or DAA interruptions.
// Configurations signals
  logic [7:0]   i_regf_config_tb           	;
  logic         i_data_config_mux_sel_tb   	;  //1: to write configurations to the controller ,     0:i3c blocks to access reg file  
  logic [11:0]  i_regf_wr_address_config_tb	;
  logic         i_regf_wr_en_config_tb     	;
  logic         i_regf_rd_en_config_tb     	;

  wire          sda_tb                     	; // sda line
    
  logic         scl_tb                     	; // scl bus
  logic         o_sdr_rx_valid_tb          	; // output to host >> valid data are loaded    //2023
  logic         o_ctrl_done_tb              ; //2023

//-----------------------------Internal signals -------------------------------------//
logic sda_drive;
bit frame_ended;
int cycle_count ;
logic configuration_done=0;

//-----------------------------Parameters-------------------------------------//
    parameter CLK_PERIOD      = 10 ;		 // 100 mhz
    parameter SYS_CLK_PERIOD  = 20 ;  		 // 50mhz
    parameter configuration   = 1'b1 ;
    parameter Design          = 1'b0 ;
    parameter config_location = 12'd1000 ;

    parameter EXPECTED_BROADCAST = 8'b11111100; // 'h7E+ R/W bit = 0
    parameter EXPECTED_ENTHDR0   = 9'b001000000;

    wire  	 sys_clk ;
    assign   sys_clk = DUT.sys_clk_50mhz ;

//----------------------------- Clock Generation-------------------------------------//
always #(CLK_PERIOD/2) i_sdr_clk_tb = ~i_sdr_clk_tb;

//-----------------------------  Initial block  -------------------------------------//
// locally driven value
assign sda_tb   = sda_drive 			;


// initialize the object with the default values in the class defined as bit >> 0
    	configuration_class conf_obj ;


    	// inputs to be randomized 

    	//////////////////////// DWORD0  //////////////////////
    	reg [2:0] RAND_CMD_ATTR      ;
    	reg [3:0] RAND_TID           ;
 			reg [7:0] RAND_CMD           ;
 			reg 	  RAND_CP            ;
 			reg [4:0] RAND_DEV_INDEX     ;
 			reg [1:0] RAND_RESERVED      ;
 			reg [2:0] RAND_DTT           ; 	 	 // or {DBP,SRE,reserved}
 			reg [2:0] RAND_MODE 	     ;
 			reg  	  RAND_RnW           ;
 			reg   	  RAND_WROC          ;
 			reg 	  RAND_TOC           ;

    	//////////////////////// DWORD1  //////////////////////
    	reg [7:0] RAND_DEF_BYTE     ;
    	reg [7:0] RAND_DATA_TWO     ;
    	reg [7:0] RAND_DATA_THREE   ;
    	reg [7:0] RAND_DATA_FOUR    ;

    	/////////////////////// SDA Line //////////////////////
    	reg  	  RAND_SDA_DRIVE ;
    	bit [1:0]   RAND_INDEX ;

    	reg 		  TOC_old ;        // actually it's current value not old one due to the chenge of configuration at state parity
    	reg [1:0] RAND_INDEX_old ; // actually it's current value not old one 

    	integer i ;
    	// sampling old value of TOC
    always @(DUT.frame_counter_hdr.o_cccnt_last_frame) begin 
    	if(DUT.frame_counter_hdr.o_cccnt_last_frame == 'b1) begin 
				TOC_old = RAND_TOC ;
			end 
    end 

    	// sampling old value of RAND_INDEX_old
    always @(DUT.CCC_Handler.o_engine_done) begin 
    	if(DUT.CCC_Handler.o_engine_done == 'b1) begin 
				RAND_INDEX_old = RAND_INDEX ;
			end 
    end

    initial begin 

    	reset();
		initialize();
		conf_obj = new();

		for (i=0 ; i<10000 ; i++) begin 
			assert(conf_obj.randomize());

			RAND_CMD_ATTR  = conf_obj.RAND_CMD_ATTR  ;
			RAND_TID       = conf_obj.RAND_TID       ;
			RAND_CMD       = conf_obj.RAND_CMD       ;
			RAND_CP        = conf_obj.RAND_CP        ;
			RAND_DEV_INDEX = conf_obj.RAND_DEV_INDEX ;
			RAND_RESERVED  = conf_obj.RAND_RESERVED  ;
			RAND_DTT       = conf_obj.RAND_DTT       ;
			RAND_MODE      = conf_obj.RAND_MODE      ;
			RAND_RnW       = conf_obj.RAND_RnW       ;
			RAND_WROC      = conf_obj.RAND_WROC      ;
			RAND_TOC       = conf_obj.RAND_TOC       ;

			RAND_DEF_BYTE   = conf_obj.RAND_DEF_BYTE  ;
			RAND_DATA_TWO   = conf_obj.RAND_DATA_TWO  ;
			RAND_DATA_THREE = conf_obj.RAND_DATA_THREE; 
			RAND_DATA_FOUR  = conf_obj.RAND_DATA_FOUR ; 
			RAND_INDEX 		= conf_obj.RAND_INDEX ;

			//RAND_SDA_DRIVE = conf_obj.RAND_SDA_DRIVE ;

			switch_muxes(configuration);
			write_configurations();
			switch_muxes(Design);
			i_controller_en_tb = 1'b1;
			i_i3c_i2c_sel_tb   = 1'b1 ;

			// if first iteration i must go to enter HDR
			if (i == 0) begin 
				wait (DUT.enthdr_en);
				check_output(); // to check enthdr ccc output
				// write new configuration
				@(DUT.frame_counter_hdr.o_cccnt_last_frame == 'b1 && (DUT.CCC_Handler.current_state == PARITY_DATA || DUT.DDR_NT.current_state == parity));
				$display("this is testcase no. %d :%0t",i,$time);
			end 

			else if (TOC_old) begin
				wait (DUT.enthdr_en); 
				check_output(); // to check enthdr ccc output
				// write new configuration
				@(DUT.frame_counter_hdr.o_cccnt_last_frame == 'b1 && (DUT.CCC_Handler.current_state == PARITY_DATA || DUT.DDR_NT.current_state == parity));
				#(4*SYS_CLK_PERIOD);
				$display("this is testcase no. %d with TOC = 1 ",i,$time);
		  	end 

		  	else if (!TOC_old) begin 
		  		@(DUT.frame_counter_hdr.o_cccnt_last_frame == 'b1 && (DUT.CCC_Handler.current_state == PARITY_DATA || DUT.DDR_NT.current_state == parity));
		  		#(4*SYS_CLK_PERIOD);
		  		$display("this is testcase no. %d with TOC = 0 ",i,$time);
		  	end 
		end	


		//@(posedge (DUT.ccc_engine_done || DUT.ddr_engine_done ));
			$display("this is loop is done  %t",$time);
		#(50*SYS_CLK_PERIOD) ;
		$display("Coverage = %.2f%%",RAND_VALUES_instance.get_coverage());		
		$stop ;
	end

//////////////////////////////////////////////  General driver /////////////////////////////////

	initial begin 
		forever #(2*SYS_CLK_PERIOD) begin 

			if (DUT.CCC_Handler.current_state == PRE_FIRST_DATA_TWO || DUT.DDR_NT.current_state == ack_waiting) begin 
				@(negedge DUT.scl_neg_edge_not_stalled or negedge DUT.scl_pos_edge_not_stalled) ;
				sda_drive = 1'b0 ;
				#(2*SYS_CLK_PERIOD) ;
				sda_drive = 1'bz ;
			end
			else if (!RAND_RnW && (DUT.CCC_Handler.current_state == PRE_DATA_TWO || DUT.DDR_NT.current_state == abort_bit)) begin 
				@(negedge DUT.scl_neg_edge_not_stalled or negedge DUT.scl_pos_edge_not_stalled) ;
				sda_drive = 1'b1 ;
				#(2*SYS_CLK_PERIOD) ;
				sda_drive = 1'bz ;
			end
		end
	end 

   
	// deserialization checking 

	always @(DUT.CCC_Handler.current_state) begin 
		if ((DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.current_state == RNW) || (DUT.DDR_NT.i_engine_en && DUT.DDR_NT.current_state == Read_Write_bit)) begin 
			#(SYS_CLK_PERIOD) ;
			check_cmd_word();
		end 
	end 

	always @(DUT.CCC_Handler.current_state) begin 
		if (DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.current_state == CCC_BYTE) begin 
			#(SYS_CLK_PERIOD) ;
			check_CCC_value_data_word();
		end 
	end

	always @(DUT.CCC_Handler.current_state or DUT.DDR_NT.current_state) begin 
		if (DUT.cccnt_RnW == 0 && (DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.current_state == FIRST_DATA_BYTE) || (DUT.DDR_NT.i_engine_en && DUT.DDR_NT.current_state == first_data_byte)) begin 
			#(SYS_CLK_PERIOD) ;
			check_repeated_data_word();
		end 
	end

	reg [28:0] read_vector_2_1 = 29'b0000_0001_0001_0001_00_01_1100_00010 ;
	reg [28:0] read_vector_2_2 = 29'b1111_1111_1111_1111_01_01_1100_01010 ;
	reg [28:0] read_vector_2_3 = 29'b0010_1010_1011_1111_10_01_1100_10111 ;
	reg [28:0] read_vector_2_4 = 29'b0111_0000_1111_0000_11_01_1100_10101 ;

	reg [28:0] read_vector_2_error = 29'b1010_1010_1010_1010_01_01_1100_10100 ;

	reg [49:0] read_vector_4_1 = 50'b0000_0000_1000_0001_10_1zz_0011_1111_1111_1111_10_01_1100_10100 ;
	reg [70:0] read_vector_6_1 = 71'b1010_1010_1010_1010_01_1zz_1111_1111_1111_1110_00_1zz_0000_0010_1111_0000_11_01_1100_01100 ;
	reg [70:0] read_vector_6_2 = 71'b0000_1111_0000_1000_11_1zz_1111_1111_0000_0000_01_1zz_0011_1100_0000_1111_01_01_1100_10001 ;



		reg [29:0] tmp_regf_read_words [3:0] = '{ 
																					 read_vector_2_1 ,
																					 read_vector_2_2 ,
																					 read_vector_2_3 ,
																					 read_vector_2_4
																					};

	always @(DUT.CCC_Handler.next_state or DUT.DDR_NT.next_state) begin 
		if ( (DUT.cccnt_RnW == 1 ) && (RAND_CMD_ATTR == 'd0) && ({RAND_DATA_FOUR,RAND_DATA_THREE} == 'd2 ) && ((DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.next_state == FIRST_DATA_BYTE) || (DUT.DDR_NT.i_engine_en && DUT.DDR_NT.next_state == first_data_byte))) begin 
			Drive_repeated_data_word_2();
		end 
	end

	always @(DUT.CCC_Handler.next_state or DUT.DDR_NT.next_state) begin 
		if ( (DUT.cccnt_RnW == 1 ) && (RAND_CMD_ATTR == 'd0) && ({RAND_DATA_FOUR,RAND_DATA_THREE} == 'd4 ) && ((DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.next_state == FIRST_DATA_BYTE) || (DUT.DDR_NT.i_engine_en && DUT.DDR_NT.next_state == first_data_byte))) begin 
			Drive_repeated_data_word_4();
		end 
	end

	always @(DUT.CCC_Handler.next_state or DUT.DDR_NT.next_state) begin 
		if ( (DUT.cccnt_RnW == 1 ) && (RAND_CMD_ATTR == 'd0) && ({RAND_DATA_FOUR,RAND_DATA_THREE} == 'd6 ) && ((DUT.CCC_Handler.i_engine_en && DUT.CCC_Handler.next_state == FIRST_DATA_BYTE) || (DUT.DDR_NT.i_engine_en && DUT.DDR_NT.next_state == first_data_byte))) begin 
			Drive_repeated_data_word_6();
		end 
	end

	task Drive_repeated_data_word_2 (); // check read commands
		begin 
			int 		 o ; // counter
			#(CLK_PERIOD);
			for ( o = 0 ; o < 'd29 ; o++ ) begin 

				@ (negedge DUT.scl_neg_edge_not_stalled or negedge DUT.scl_pos_edge_not_stalled ) ;
				sda_drive = tmp_regf_read_words[RAND_INDEX_old] [28 - o];
				# (3*CLK_PERIOD) ;
 
			end
			sda_drive = 1'bz ;
			# (4*SYS_CLK_PERIOD) ;

			if (TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == EXIT_PATTERN) $display("READ data word TOC = 1 is CORRECT : %0t" ,$time);
				else 												   $display("READ data word TOC = 1 is WRONG   : %0t" ,$time);
			end 
			else if (!TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == RESTART_PATTERN) $display("READ data word TOC = 0 is CORRECT : %0t" ,$time);
				else 												   	  $display("READ data word TOC = 0 is WRONG   : %0t" ,$time);
			end 
		end  
	endtask 


	task Drive_repeated_data_word_4 (); // check read commands
		begin 
			int 		 o ; // counter
			#(CLK_PERIOD);
			for ( o = 0 ; o < 'd50 ; o++ ) begin 

				@ (negedge DUT.scl_neg_edge_not_stalled or negedge DUT.scl_pos_edge_not_stalled ) ;
				sda_drive = read_vector_4_1[49 - o];
				# (3*CLK_PERIOD) ;
 
			end
			sda_drive = 1'bz ;
			# (4*SYS_CLK_PERIOD) ;

			if (TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == EXIT_PATTERN) $display("READ data word TOC = 1 is CORRECT : %0t" ,$time);
				else 												   $display("READ data word TOC = 1 is WRONG   : %0t" ,$time);
			end 
			else if (!TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == RESTART_PATTERN) $display("READ data word TOC = 0 is CORRECT : %0t" ,$time);
				else 												   	  $display("READ data word TOC = 0 is WRONG   : %0t" ,$time);
			end 
		end  
	endtask 


	task Drive_repeated_data_word_6 (); // check read commands
		begin 
			int 		 o ; // counter
			#(CLK_PERIOD);
			for ( o = 0 ; o < 'd71 ; o++ ) begin 

				@ (negedge DUT.scl_neg_edge_not_stalled or negedge DUT.scl_pos_edge_not_stalled ) ;
				sda_drive = read_vector_6_2[70 - o];
				# (3*CLK_PERIOD) ;
 
			end
			sda_drive = 1'bz ;
			# (4*SYS_CLK_PERIOD) ;

			if (TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == EXIT_PATTERN) $display("READ data word TOC = 1 is CORRECT : %0t" ,$time);
				else 												   $display("READ data word TOC = 1 is WRONG   : %0t" ,$time);
			end 
			else if (!TOC_old) begin 
				assert (DUT.CCC_Handler.current_state == RESTART_PATTERN) $display("READ data word TOC = 0 is CORRECT : %0t" ,$time);
				else 												   	  $display("READ data word TOC = 0 is WRONG   : %0t" ,$time);
			end 
		end  
	endtask 


	task check_cmd_word (); 
		begin 
			logic [17:0] collected_cmd_wrd ;
			bit 	     parity_adj_7e ,parity_adj ,P1_cmd_sel ,P0_cmdword , P1_cmd_ind ;
			bit   [17:0] correct_first_cmd_word , correct_cmd_word ;
			int 		 o ; // counter

			for ( o = 0 ; o < 'd18 ; o++ ) begin 

			@ (posedge DUT.scl_pos_edge or posedge DUT.scl_neg_edge ) ;

				collected_cmd_wrd['d17- o] = sda_tb ;

				parity_adj    = collected_cmd_wrd[16] ^ collected_cmd_wrd[14] ^ collected_cmd_wrd[12] ^ collected_cmd_wrd[10] ^ collected_cmd_wrd[8] ^ collected_cmd_wrd[6] ^ collected_cmd_wrd[4]  ;
				P1_cmd_sel    = DUT.CCC_Handler.i_regf_RnW ^ collected_cmd_wrd[9] ^ collected_cmd_wrd[7] ^ collected_cmd_wrd[5] ^ collected_cmd_wrd[3] ; // index is shifted by 2 as this is the 18 bit word (data + parity)
				P1_cmd_ind 	  = 1'b0 ^ collected_cmd_wrd[9] ^ collected_cmd_wrd[7] ^ collected_cmd_wrd[5] ^ collected_cmd_wrd[3] ; // index is shifted by 2 as this is the 18 bit word (data + parity)
				P0_cmdword    =  1 ;

				correct_first_cmd_word = {1'b0 			, 7'd0 , 7'b111_1110 					        , parity_adj , P1_cmd_ind , P0_cmdword } ;
				correct_cmd_word 	   = {DUT.cccnt_RnW , 7'd0 , DUT.cccnt_tx_special_data_mux_out[6:0] , parity_adj , P1_cmd_sel , P0_cmdword } ;

				# (2*CLK_PERIOD) ;
				if (o == 'd17) begin 
					if (DUT.CCC_Handler.i_engine_en && (DUT.CCC_Handler.first_time || !DUT.CCC_Handler.Direct_Broadcast_n_del)) begin  // this is a 7E cmd word
						assert (correct_first_cmd_word == collected_cmd_wrd) $display("first command word in CCC is CORRECT : %0t" ,$time);
						else 												 $display("first command word in CCC is WRONG   : %0t" ,$time);
					end 
					else begin 	// this is an address word  
						assert (correct_cmd_word == collected_cmd_wrd) $display("second command word is CORRECT : %0t" ,$time);
						else 										   $display("second command word is WRONG   : %0t" ,$time);
					end 
				end  
			end 
		end  
	endtask 


	task check_CCC_value_data_word (); 
		begin 
			logic [17:0] collected_data_wrd ;
			bit 	     P1 ,P0 ;
			bit   [17:0] correct_first_data_word  ;
			int 		 o ; // counter 

			for ( o = 0 ; o < 'd18 ; o++ ) begin 

			@ (posedge DUT.scl_pos_edge or posedge DUT.scl_neg_edge ) ;

				collected_data_wrd['d17- o] = sda_tb ;

				//$display("vlaue of SDA line is  %b : %t",sda_tb,$time);

				P1 = collected_data_wrd[17] ^ collected_data_wrd[15] ^ collected_data_wrd[13] ^ collected_data_wrd[11] ^ collected_data_wrd[9] ^
				 	 collected_data_wrd[7] ^ collected_data_wrd[5] ^ collected_data_wrd[3] ;

				P0 = collected_data_wrd[16] ^ collected_data_wrd[14] ^ collected_data_wrd[12] ^ collected_data_wrd[10] ^ collected_data_wrd[8] ^
					 collected_data_wrd[6] ^ collected_data_wrd[4] ^ collected_data_wrd[2] ^ 1 ; 

				correct_first_data_word = { DUT.CCC_Handler.o_txrx_addr_ccc , 8'd0 ,  P1 , P0 } ;

				# (2*CLK_PERIOD) ;
				if (o == 'd17) begin 
					assert (correct_first_data_word == collected_data_wrd) $display("CCC data word is CORRECT : %0t" ,$time);
					else 												   $display("CCC data word is WRONG   : %0t" ,$time);
				end  
			end 
		end  
	endtask 



	task check_repeated_data_word (); 
		begin 
			logic [17:0] collected_data_wrd ;
			bit 	     P1 ,P0 ;
			bit   [17:0] correct_repeated_data_word  ;
			int 		 o ;
			bit   [7:0] tmp_D1 , tmp_D0 ;

			for ( o = 0 ; o < 'd18 ; o++ ) begin 

			@ (posedge DUT.scl_pos_edge or posedge DUT.scl_neg_edge ) ;

				collected_data_wrd['d17- o] = sda_tb ;

				//$display("vlaue of SDA line is  %b : %t",sda_tb,$time);

				P1 = correct_repeated_data_word[17] ^ correct_repeated_data_word[15] ^ correct_repeated_data_word[13] ^ correct_repeated_data_word[11] ^ correct_repeated_data_word[9] ^
				 	 correct_repeated_data_word[7] ^ correct_repeated_data_word[5] ^ correct_repeated_data_word[3] ;

				P0 = correct_repeated_data_word[16] ^ correct_repeated_data_word[14] ^ correct_repeated_data_word[12] ^ correct_repeated_data_word[10] ^ correct_repeated_data_word[8] ^
					 correct_repeated_data_word[6] ^ correct_repeated_data_word[4] ^ correct_repeated_data_word[2] ^ 1 ; 

				if (o == 'd3) begin                            // any arbitrary value btn 0 -> 7
					tmp_D1 = DUT.regf_data_rd ; 
				end
	
				if (o == 'd10) begin 	 	 	 	 	 	   // any arbitrary value btn 8 -> 15
					tmp_D0 = DUT.regf_data_rd ;
				end 

				correct_repeated_data_word = { tmp_D1 , tmp_D0 , P1 , P0 };

				# (2*CLK_PERIOD) ;
				if (o == 'd17) begin 
					correct_repeated_data_word = { tmp_D1 , tmp_D0 , P1 , P0 };
					assert (correct_repeated_data_word == collected_data_wrd) $display("repeated data word is CORRECT : %0t" ,$time);
					else 													  $display("repeated data word is WRONG   : %0t" ,$time);
				end  
			end 
		end  
	endtask 


pullup(sda_tb);
//-----------------------------     Tasks       -------------------------------------//

task reset;
	begin
	    i_sdr_rst_n_tb 		        = 1'b1;
		# (SYS_CLK_PERIOD)
		i_sdr_rst_n_tb 				= 1'b0; // activated
		# (SYS_CLK_PERIOD)
		i_sdr_rst_n_tb 				= 1'b1; // de-activated

	end	
	endtask

task initialize; 
	begin
		i_sdr_clk_tb 				= 1'b0;
		i_sdr_rst_n_tb 				= 1'b1;
		i_i3c_i2c_sel_tb        	= 1'b1;  //i3c mode
		i_controller_en_tb      	= 1'b0;
		i_ccc_en_dis_hj_tb      	= 1'b0;
		sda_drive 					= 1'bz;
		i_data_config_mux_sel_tb    = 1'b1;
		i_regf_rd_en_config_tb   	= 1'b0;								
    	i_regf_wr_en_config_tb   	= 1'b1;

	end
	endtask

task switch_muxes(input selector);
        begin 
            i_data_config_mux_sel_tb = selector ; // 1 for configuration and 0 for design 
        end 
    endtask 

task write_configurations();
	begin

//1.write randomized values
	// DWORD0
	@(negedge sys_clk) ;
	 	i_regf_wr_en_config_tb = 1'b1;
	 #(SYS_CLK_PERIOD)																		    																									; 
		i_regf_config_tb     = { RAND_CMD[0] , RAND_TID , RAND_CMD_ATTR }  			 		;
    	i_regf_wr_address_config_tb = config_location 																												;
    	    
      #(SYS_CLK_PERIOD)  																																											; 
		i_regf_config_tb     = { RAND_CP , RAND_CMD[7:1] } 									;
    	i_regf_wr_address_config_tb = config_location + 'd1 																									;

      #(SYS_CLK_PERIOD)  																																											; 
		i_regf_config_tb     = { RAND_DTT[0] , RAND_RESERVED , RAND_DEV_INDEX }  			;		    
    	i_regf_wr_address_config_tb = config_location + 'd2 																									;

      #(SYS_CLK_PERIOD)  																																											; 
		i_regf_config_tb     = { RAND_TOC , RAND_WROC , RAND_RnW ,RAND_MODE , RAND_DTT[2:1]} ;
    	i_regf_wr_address_config_tb = config_location + 'd3 																									;

      // DWORD 1
       #(SYS_CLK_PERIOD)  																																									  ; 
		i_regf_config_tb     = RAND_DEF_BYTE     																														;
    	i_regf_wr_address_config_tb  = config_location + 'd4 																									;		

       #(SYS_CLK_PERIOD)  																																										; 
		i_regf_config_tb     = RAND_DATA_TWO     																														;
    	i_regf_wr_address_config_tb  = config_location + 'd5 																									;

       #(SYS_CLK_PERIOD); 																		 
		i_regf_config_tb     = RAND_DATA_THREE     																													;
    	i_regf_wr_address_config_tb  = config_location + 'd6 																									;

       #(SYS_CLK_PERIOD)  																																										; 
		i_regf_config_tb     = RAND_DATA_FOUR     																														;
    	i_regf_wr_address_config_tb  = config_location + 'd7 																									;
  
        #(SYS_CLK_PERIOD) 																																											;
	end
endtask : write_configurations


task check_output ();
	begin
		logic [7:0] BROADCAST; // 7'h7E+ R/w bit
		logic [8:0] ENTHDR0; 

		BROADCAST = 8'b0; // 7'h7E+ R/w bit
		ENTHDR0 = 9'b0;

			for(int i=0; i < 8 ; i++)   //receive first 8 bits of 7E and write bit
			 	begin  
				   @(posedge scl_tb)
				   	BROADCAST['d7 - i] = sda_tb;
			 	end

			@(negedge scl_tb)
			assert (BROADCAST == EXPECTED_BROADCAST) $display("Broadcast frame is RECIEVED");
			else 									 $display("Broadcast frame is WRONG");
					send_ack();
			 

			for(int i=0; i < 9 ; i++)   //receive first 8 bits of 7E and write bit
			 	begin  
				   @(posedge scl_tb)
				   	ENTHDR0['d8 - i] = sda_tb;
			 	end
 

			assert (ENTHDR0 == EXPECTED_ENTHDR0) $display("ENTHDR frame is RECIEVED");
			else 								 $display("ENTHDR frame is WRONG");			

	   		
		
	end 
endtask

task send_ack;
    begin 
        #(SYS_CLK_PERIOD)
        if(!scl_tb) begin
        	sda_drive = 1'b0; //ack bit
        	#(4*SYS_CLK_PERIOD) ;
        	sda_drive =  1'bz ;
    	end
    end 
endtask


//-----------------------------DUT Instantiation-------------------------------------//
I3C_TOP DUT (
 .i_sdr_clk           		(i_sdr_clk_tb)					, 
 .i_sdr_rst_n         		(i_sdr_rst_n_tb)				, 
 .i_controller_en     		(i_controller_en_tb)			, 
 .i_i3c_i2c_sel       		(i_i3c_i2c_sel_tb)				, 
 .i_ccc_en_dis_hj     		(i_ccc_en_dis_hj_tb)			, 
 .i_regf_config             (i_regf_config_tb)				,
 .i_data_config_mux_sel     (i_data_config_mux_sel_tb)		,    
 .i_regf_wr_address_config  (i_regf_wr_address_config_tb)	,
 .i_regf_wr_en_config       (i_regf_wr_en_config_tb)		,
 .i_regf_rd_en_config       (i_regf_rd_en_config_tb)        ,   
 .sda                 		(sda_tb)						,
 .scl                 		(scl_tb)						,
 .o_sdr_rx_valid      		(o_sdr_rx_valid_tb)				,
 .o_ctrl_done               (o_ctrl_done_tb)
 );

//-------------------------------------- Assertions ---------------------------------------//
	//assign sys_clk_50mhzzz = DUT.sys_clk_50mhz ;
/*
	property EXIT_and_stop_pattern ;
		@(posedge DUT.sys_clk_50mhz) (!scl_tb) [*3] |-> $fell(sda_tb) [*4] ##1 (!sda_tb && scl_tb) ##1 (sda_tb && scl_tb) ;
	endproperty
*/
	property EXIT_and_stop_pattern ;
		disable iff (!i_sdr_rst_n_tb) 
		@(posedge DUT.sys_clk_50mhz)
		(DUT.tx_mode_hdr_mux_out == exit_pattern && ($past(DUT.tx_mode_hdr_mux_out) != exit_pattern )) |=> 
																				   (!scl_tb &&  sda_tb) ##2
																				   (!scl_tb && !sda_tb) ##2
																				   (!scl_tb &&  sda_tb) ##2 
																				   (!scl_tb && !sda_tb) ##2 
																				   (!scl_tb &&  sda_tb) ##2 
																				   (!scl_tb && !sda_tb) ##2
																				   (!scl_tb &&  sda_tb) ##2 
																				   (!scl_tb && !sda_tb) ##1
																				   ( scl_tb && !sda_tb) ##1 
																				   ( scl_tb &&  sda_tb)     ;
	endproperty


	property Middle_Restart_pattern ;
		disable iff (!i_sdr_rst_n_tb) 
		@(posedge DUT.sys_clk_50mhz)
		(!DUT.frmcnt_last_frame_hdr && DUT.ccc_tx_mode == restart_pattern && ($past(DUT.ccc_tx_mode) != restart_pattern )) |-> 
																										##2
																				   (!scl_tb &&  sda_tb) ##2
																				   (!scl_tb && !sda_tb) ##2
																				   (!scl_tb &&  sda_tb) ##2 
																				   (!scl_tb && !sda_tb) ##1 
																				   (!scl_tb &&  sda_tb) ##1 
																				   ( scl_tb &&  sda_tb)     ;
	endproperty

	property Last_Restart_pattern ;
		disable iff (!i_sdr_rst_n_tb) 
		@(posedge DUT.sys_clk_50mhz)
		(DUT.frmcnt_last_frame_hdr && DUT.tx_mode_hdr_mux_out == restart_pattern && ($past(DUT.tx_mode_hdr_mux_out) != restart_pattern )) |-> 
																										##2
																				   (!scl_tb &&  sda_tb) ##2
																				   (!scl_tb && !sda_tb) ##2
																				   (!scl_tb &&  sda_tb) ##2 
																				   (!scl_tb && !sda_tb) ##1 
																				   (!scl_tb &&  sda_tb) ##1 
																				   ( scl_tb &&  sda_tb) ##1 
																				   ( scl_tb &&  sda_tb) ##1
																				   (!scl_tb &&  sda_tb)		;
	endproperty


	assert property(EXIT_and_stop_pattern) 
							$display("%t EXIT_and_stop_pattern SUCCEEDED ",$time); else
                            $display("%t EXIT_and_stop_pattern FAILED    ",$time);

    assert property(Middle_Restart_pattern) 
							$display("%t Middle_Restart_pattern SUCCEEDED ",$time); else
                            $display("%t Middle_Restart_pattern FAILED    ",$time);

    assert property(Last_Restart_pattern) 
							$display("%t Last_Restart_pattern SUCCEEDED ",$time); else
                            $display("%t Last_Restart_pattern FAILED    ",$time);



	covergroup RAND_VALUES @(posedge i_sdr_clk_tb) ;
 
		RAND_CMD_ATTR_cp : coverpoint RAND_CMD_ATTR iff (i_sdr_rst_n_tb)
		{
			bins regular_0   = {0};
			bins immediate_1 = {1};
		}

		RAND_CMD_immediate_cp : coverpoint RAND_CMD iff (i_sdr_rst_n_tb)
		{
			bins ENEC_D_bin      = {8'h80};
			bins DISEC_D_bin     = {8'h81};
			bins SETMWL_D_bin    = {8'h89};
			bins SETMRL_D_bin    = {8'h8A};
			
			bins ENEC_B_bin      = {8'h00};
			bins DISEC_B_bin     = {8'h01};
			bins SETMWL_B_bin    = {8'h09};
			bins SETMRL_B_bin    = {8'h0A};
			bins Dummy_B_bin     = {8'h1F};
			
		}

		RAND_CMD_regular_cp : coverpoint RAND_CMD iff (i_sdr_rst_n_tb)
		{
			
			bins GETMWL_D_bin    = {8'h8B};
			bins GETMRL_D_bin    = {8'h8C};
			bins GETSTATUS_D_bin = {8'h90};
			bins GETBCR_D_bin    = {8'h8E};
			bins GETDCR_D_bin    = {8'h8F};
			
		}

		RAND_CP_cp : coverpoint RAND_CP iff (i_sdr_rst_n_tb)
		{
			//bins Normal_transaction_bin = {0};
			bins CCC_Handler_bin 		= {1};
		}
		
		RAND_DEV_INDEX_cp : coverpoint RAND_DEV_INDEX iff (i_sdr_rst_n_tb)
		{
			bins low  = {[0:8]};
			bins mid  = {[9:20]};
			bins high = {[21:31]};
		}

		RAND_DTT_cp : coverpoint RAND_DTT iff (i_sdr_rst_n_tb)
		{
			bins no_def_byte_0 = {0};
			bins no_def_byte_1 = {1};
			bins no_def_byte_2 = {2};
			bins no_def_byte_3 = {3};

			//ignore_bins def_byte [] = {[5:7]};
		}

		RAND_MODE_cp : coverpoint RAND_MODE iff (i_sdr_rst_n_tb)
		{
			bins HDR_mode_bin = {6};
			illegal_bins none =  default ;
		}

		RAND_RnW_cp : coverpoint RAND_RnW iff (i_sdr_rst_n_tb)
		{
			bins Write  = {0} ;
			bins Read   = {1} ;
		}

		RAND_TOC_cp : coverpoint RAND_TOC iff (i_sdr_rst_n_tb)
		{
			bins exit_patt    = {1} ;
			bins restart_patt = {0} ;
		}

		RAND_DATA_THREE_cp : coverpoint RAND_DATA_THREE iff (i_sdr_rst_n_tb)
		{
			bins DATA_LEN [] = {2,4,6} ;
			bins long_DATA_LEN = {6};
		}

		RAND_DATA_FOUR_cp : coverpoint RAND_DATA_FOUR iff (i_sdr_rst_n_tb)
		{
			bins ZERO = {0} ;
		}
		
		cr1 : cross RAND_CMD_ATTR_cp , RAND_CMD_immediate_cp {
			ignore_bins regular = binsof(RAND_CMD_ATTR_cp) intersect {0};
		}

		cr2 : cross  RAND_CMD_ATTR_cp , RAND_CMD_regular_cp {
			ignore_bins immediate = binsof(RAND_CMD_ATTR_cp) intersect {1};
		}
	
		engine_odd : coverpoint DUT.engine_odd iff (i_sdr_rst_n_tb && ((RAND_DTT == 1) || (RAND_DTT == 3) || {RAND_DATA_THREE,RAND_DATA_FOUR} %2 == 1))
		{
			bins ENGINE_ODD     = {1} ;
			bins ENGINE_ODD_not = {0} ;
		}

/*
		cr3 : cross  RAND_DTT_cp , RAND_CMD_immediate_cp {
			ignore_bins more_than_one =  binsof (RAND_DTT_cp) intersect {0,2,3,4} &&
			 							 binsof (RAND_CMD_immediate_cp) intersect {8'h81,8'h89,8'h8A,8'h00,8'h01,8'h09,8'h0A,8'h1F} ;
		}
*/
	    endgroup

	RAND_VALUES RAND_VALUES_instance = new();
		


endmodule
