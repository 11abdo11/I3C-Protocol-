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

`timescale 1us / 1ps

module target_tb ();
  ////////////////this module is made starting with rx, tx and nt block and then integrating block by block /////////////////////
  /////////nt_target/////////////
  reg i_sys_clk_tb = 1'b0;
  reg i_sys_rst_tb;
  wire o_cccnt_last_frame_tb;
  wire i_engine_en_tb;
  wire tx_mode_done_tb, o_ddrccc_rx_mode_done_tb, o_ddrccc_pre_tb;
  wire i_rx_ddrccc_rnw_tb, o_ddrccc_error_tb, o_tx_en_tb, o_nt_rx_en_tb;
  wire o_regf_wr_en_tb, o_regf_rd_en_tb; 
  wire [3:0] o_nt_rx_mode_tb;
  wire [2:0] o_tx_mode_tb;
  wire [9:0] o_regf_addr_tb;
  wire o_frmcnt_en_tb, i_sdr_scl_gen_pp_od_tb;
  wire o_engine_done_tb, o_bitcnt_en_tb, o_bitcnt_reset_tb, o_frmcnt_rnw_tb;

nt_target DUT0 (
    .i_sys_clk(i_sys_clk_tb),
    .i_sys_rst(i_sys_rst_tb),
    .i_engine_en(i_engine_en_tb),
    .i_frmcnt_last(o_cccnt_last_frame_tb),
    .i_tx_mode_done(tx_mode_done_tb),
    .i_rx_mode_done(o_ddrccc_rx_mode_done_tb),
    .i_rx_pre(o_ddrccc_pre_tb),
    .i_rx_ddrccc_rnw(i_rx_ddrccc_rnw_tb),
    .i_rx_error(o_ddrccc_error_tb), 
    .o_tx_en(o_tx_en_tb),
    .o_tx_mode(o_tx_mode_tb),
    .o_rx_en(o_nt_rx_en_tb),
    .o_rx_mode(o_nt_rx_mode_tb),
    .o_frmcnt_en(o_frmcnt_en_tb),
    .o_sdahand_pp_od(i_sdr_scl_gen_pp_od_tb),
    .o_regf_wr_en(o_regf_wr_en_tb),
    .o_regf_rd_en(o_regf_rd_en_tb),
    .o_regf_addr(o_regf_addr_tb),
    .o_frmcnt_rnw(o_frmcnt_rnw_tb),
    .o_engine_done(o_engine_done_tb),
    .o_bitcnt_en (o_bitcnt_en_tb),
    .o_bitcnt_reset (o_bitcnt_reset_tb)
	);
	
	///////////////////////frame_counter//////////////////
	wire [5:0]  o_bitcnt_tb;
	wire i_bitcnt_toggle_tb;
        wire [15:0] o_frmcnt_max_rd_len_tb, o_frmcnt_max_wr_len_tb;
		
frame_counter_target DUT1 (
    .i_fcnt_clk          (i_sys_clk_tb),
    .i_fcnt_rst_n        (i_sys_rst_tb),
    .i_fcnt_en           (o_frmcnt_en_tb),
    .i_regf_MAX_RD_LEN     (o_frmcnt_max_rd_len_tb),
    .i_regf_MAX_WR_LEN     (o_frmcnt_max_wr_len_tb),
    .i_cnt_bit_count     (o_bitcnt_tb),
    .i_bitcnt_toggle     (i_bitcnt_toggle_tb),
    .i_nt_rnw            (o_frmcnt_rnw_tb),
    .o_cccnt_last_frame  (o_cccnt_last_frame_tb)
); 

//////////bit_counter////////////////////////

  bits_counter_target DUT2 (
		.i_sys_clk       (i_sys_clk_tb),
		.i_rst_n 	  (i_rst_n_tb),
		.i_bitcnt_en     (o_bitcnt_en_tb),
                .abort_or_end_reset (o_bitcnt_reset_tb),
		.i_scl_pos_edge  (DUT11.scl_pos_edge),
		.i_scl_neg_edge  (DUT11.scl_neg_edge),
		.o_frcnt_toggle  (i_bitcnt_toggle_tb),
		.o_cnt_bit_count (o_bitcnt_tb)
		
	);
	
	/////////////////////scl////////////////
	/*reg i_scl_gen_stall_tb, i_timer_cas_tb, i_sdr_ctrl_scl_idle_tb;
	wire i_sclgen_scl_tb_mux_inp;
	wire i_sclgen_scl_tb;
	
  scl_generation DUT3 (
    .i_sdr_ctrl_clk     	(i_sys_clk_tb),
    .i_sdr_ctrl_rst_n   	(i_sys_rst_tb),
    .i_sdr_scl_gen_pp_od	(i_sdr_scl_gen_pp_od_tb), 	
    .i_scl_gen_stall    	(i_scl_gen_stall_tb),   
    .i_sdr_ctrl_scl_idle	(i_sdr_ctrl_scl_idle_tb),
    .i_timer_cas        	(i_timer_cas_tb), 	
    .o_scl_pos_edge     	(i_sclgen_scl_pos_edge_tb),
    .o_scl_neg_edge     	(i_sclgen_scl_neg_edge_tb),
    .o_scl              	(i_sclgen_scl_tb)                         	
); */        //managed by controller

/////////////////////rx///////////////////////
reg i_sdahnd_rx_sda_tb;
wire [4:0] i_crc_value_tb;
wire [7:0] o_regfcrc_rx_data_out_tb, o_ccc_ccc_value_tb;
wire [1:0] o_engine_decision_tb;
wire [3:0]  o_rx_mode_tb;
wire last_byte_rx;
wire o_crc_en_rx_tb;
wire [7:0] o_crc_parallel_data_rx_tb;
wire data_valid_rx;
target_rx DUT4 (
	.i_sys_clk					(i_sys_clk_tb)				,
	.i_sys_rst					(i_sys_rst_tb)				,
	.i_sclgen_scl				(DUT11.scl)			,
	.i_sclgen_scl_pos_edge		(DUT11.scl_pos_edge)	,
	.i_sclgen_scl_neg_edge		(DUT11.scl_neg_edge)	,
	.i_ddrccc_rx_en				(o_rx_en_tb)			,
	.i_sdahnd_rx_sda			(i_sdahnd_rx_sada_tb)		, //edit lately to add a handler for op and pp behave
	.i_ddrccc_rx_mode			(o_rx_mode_tb)		,
	.i_crc_value                           (i_crc_value_tb),		
	.o_regfcrc_rx_data_out		(o_regfcrc_rx_data_out_tb)	,
	.o_ddrccc_rx_mode_done		(o_ddrccc_rx_mode_done_tb)	,
	.o_ddrccc_pre				(o_ddrccc_pre_tb)			,
	.o_ddrccc_error_flag				(o_ddrccc_error_tb)			,
	.o_ddrccc_rnw   (i_rx_ddrccc_rnw_tb)  ,
	.o_engine_decision (o_engine_decision_tb) ,
	.o_ccc_ccc_value (o_ccc_ccc_value_tb)  ,
        .o_crc_en (o_crc_en_rx_tb),
        .o_crc_data_valid (data_valid_rx),
        .o_crc_last_byte (last_byte_rx),
        .o_crc_data (o_crc_parallel_data_rx_tb)   
);

/////////////////tx//////////////////////
wire [7:0] i_regf_tx_parallel_data_tb ;
wire o_sdahnd_tgt_serial_data_tb;
wire last_byte_tx;
wire o_crc_en__tx_tb;
wire [7:0] o_crc_parallel_data_tx_tb;
wire data_valid_tx;

tx_t  DUT5(
   .i_sys_clk(i_sys_clk_tb),
   .i_sys_rst(i_sys_rst_tb),
   .i_sclgen_scl(DUT11.scl),
   .i_sclgen_scl_pos_edge(DUT11.scl_pos_edge),
   .i_sclgen_scl_neg_edge(DUT11.scl_neg_edge),
   .i_ddrccc_tx_en(o_tx_en_tb),
   .i_ddrccc_tx_mode(o_tx_mode_tb),
   .i_regf_tx_parallel_data(i_regf_tx_parallel_data_tb),
   .i_crc_crc_value(i_crc_value_tb),
   .o_sdahnd_tgt_serial_data(o_sdahnd_tgt_serial_data_tb),
   .o_ddrccc_tx_mode_done(tx_mode_done_tb),
   .o_crc_en(o_crc_en_tx_tb), 
   .o_crc_parallel_data(o_crc_parallel_data_tx_tb),
   .o_crc_data_valid(data_valid_tx),
   .o_crc_last_byte (last_byte_tx)
);

///////////////////engine_nt_mux////////////////////////

wire engine_en_tb ;
wire [1:0] engine_or_nt;
gen_mux #(1,2) DUT6(
.data_in({1'b0 , o_nt_rx_en_tb , engine_en_tb}), //signal zero as ccc block not finished
.ctrl_sel(engine_or_nt),
.data_out(o_rx_en_tb) //mux to control who is handling the rx (engine or normal)
);

wire [3:0] engine_mode; 
gen_mux #(4,2) DUT7 (
.data_in({4'b0000 , o_nt_rx_mode_tb , engine_mode}), ////signal zero as ccc block not finished
.ctrl_sel(engine_or_nt),
.data_out(o_rx_mode_tb) ////mux to control who is handling the rx (engine or normal)
);

////////////////////engine//////////////////////////
wire restart_done_tb; 
wire exit_done_tb, ENTHDR_done, CCC_done_tb;
wire o_ENTHDR_en_tb, o_CCC_en_tb;
Target_engine DUT8 (
.i_sys_clk(i_sys_clk_tb),
.i_sys_rst(i_sys_rst_tb),
.i_rstdet_RESTART(restart_done_tb),
.i_exitdet_EXIT(exit_done_tb),
.i_ENTHDR_done(ENTHDR_done),
.i_CCC_done(CCC_done_tb),
.i_NT_done(o_engine_done_tb),
.i_rx_decision(o_engine_decision_tb),
.i_rx_decision_done(o_ddrccc_rx_mode_done_tb),
.o_muxes(engine_or_nt),
.o_ENTHDR_en(o_ENTHDR_en_tb),
.o_NT_en(i_engine_en_tb),
.o_CCC_en(o_CCC_en_tb),
.o_rx_en(engine_en_tb),
.o_rx_mode(engine_mode)
);

///////////////////regfile/////////////////////////

reg_file_t DUT9(
.i_regf_clk (i_sys_clk_tb),
.i_regf_rst_n (i_sys_rst_tb),
.i_regf_rd_en (o_regf_rd_en_tb),
.i_regf_wr_en (o_regf_wr_en_tb),
.i_regf_addr (o_regf_addr_tb),
.i_regf_data_wr(o_regfcrc_rx_data_out_tb),
.o_frmcnt_max_rd_len(o_frmcnt_max_rd_len_tb),
.o_frmcnt_max_wr_len(o_frmcnt_max_wr_len_tb),
.o_regf_data_rd(i_regf_tx_parallel_data_tb)
);

////////////////////restart_detector/////////////////
wire SCL;
Restart_Detector DUT10 (
.i_sys_clk(i_sys_clk_tb),
.i_sys_rst(i_sys_rst_tb),
.i_scl(SCL),
.i_sda(i_sdahnd_rx_sda_tb),
.o_engine_done(restart_done_tb)
);

////////////////////////ENTHDR_HDR_///////////////////////////////////
//used only for testing
    // Design Inputs   
    reg          i_controller_en_tb    	;        
    reg          i_i3c_i2c_sel_tb 			;
    reg          i_ccc_en_dis_hj_tb			;

    reg   [7:0]  i_regf_config  ;
    reg          i_data_config_mux_sel;  //1: to write configurations to the controller ,     0:i3c blocks to access reg file  
    reg   [11:0] i_regf_wr_address_config;
    reg          i_regf_wr_en_config     ;
    reg          i_regf_rd_en_config     ;

    reg          i_ccc_done_tb         		; // done signal from CCC block
    reg          i_ddr_mode_done_tb    		; // done signal from ddr block

    wire         sda_tb                		;

   
    // Design Output
    wire         o_sdr_rx_valid_tb     		; // output to host >> valid data are loaded
    wire         o_ctrl_done_tb        		; // sdr block done signal            		
    wire         o_ddrmode_enable_tb        ; // enable for the ddr block
    wire         o_ccc_enable_tb            ; // enable for the CCC block
    wire  [11:0]  o_regf_address_special_tb  ; // regf special address

    ///////////targt///////////////////////////////////         ;
    wire   o_tgt_sdahnd_sda_tb           ;
    wire   o_tgt_pp_od_sdahand_tb        ;

  ///////////////////ent_hdr_parameter////////////////////////////
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
//---------------------------------------------------
//////////////////////////////////////////////////////////////
ENTHDR_CTRL_TGT_top DUT11 (
.i_sdr_clk(i_sys_clk_tb),
.i_sdr_rst_n(i_sys_rst_tb),
.i_controller_en(i_controller_en_tb),
.i_i3c_i2c_sel(i_i3c_i2c_sel_tb),
.i_ccc_en_dis_hj(i_ccc_en_dis_hj_tb),
.i_regf_config(i_regf_config),
.i_data_config_mux_sel(i_data_config_mux_sel),
.i_regf_wr_address_config(i_regf_wr_address_config),
.i_regf_wr_en_config(i_regf_wr_en_config),
.i_regf_rd_en_config(i_regf_rd_en_config),
.sda(sda_tb),
.scl(DUT11.scl),
.o_sdr_rx_valid(o_sdr_rx_valid_tb),
.o_ctrl_done(o_ctrl_done_tb),
//////////////response_signals////////////////////
.i_tgt_engine_en(o_ENTHDR_en_tb),
.o_tgt_sdahnd_sda(o_tgt_sdahnd_sda_tb),
.o_tgt_pp_od_sdahand(o_tgt_pp_od_sdahand_tb),
.o_tgt_engine_done(ENTHDR_done)
);
pullup(sda_tb);
     
// locally driven value
assign sda_tb   = o_tgt_sdahnd_sda_tb 			;
// testing the enthdr response using a top containing controller blocks and the response block to make sure pattern is detected correctly
// scl of this top is also used in testing ;)
/////////////////////////muxes_for_SDA////////////////////////////////////////////
wire sda_in;
reg ent; 
gen_mux #(1,1) DUT12 (
.data_in({i_sdahnd_rx_sda_tb , sda_tb}), 
.ctrl_sel(ent),
.data_out(sda_in)
); //only for better screening for the sda entering the response in the top tested and the one drived in this module (not included in TOP_Module)

wire sda_drive_;
assign sda_drive_ = o_tgt_sdahnd_sda_tb;
pullup (sda_drive_);
wire sda_out;
gen_mux #(1,1) DUT13 (  
.data_in({sda_drive_ , o_sdahnd_tgt_serial_data_tb}),
.ctrl_sel(o_ENTHDR_en_tb),
.data_out(sda_out)
); //who is accessing the bus (response or tx)

reg [1:0] stall;
gen_mux #(1,2) DUT14 (
.data_in({1'b1 ,!DUT11.scl ,1'b0 , DUT11.scl}), //this !DUT11.scl as after stalling SCL is may take a 180 phaseshift ;)
.ctrl_sel(stall),
.data_out(SCL)
); //mux to make the behave of stalling scl as its only in the controller 

wire crc_valid, last_byte, data_valid, CRC_EN;
wire [7:0] CRC_data;
crc DUT15 (
.i_sys_clk (i_sys_clk_tb),
.i_sys_rst(i_sys_rst_tb),
.i_txrx_en(CRC_EN),
.i_txrx_data_valid(data_valid),
.i_txrx_last_byte(last_byte),
.i_txrx_data(CRC_data),
.o_txrx_crc_value(i_crc_value_tb),
.o_txrx_crc_valid(crc_valid)
);

gen_mux #(1,1) DUT16 (
.data_in({o_crc_en_tx_tb , o_crc_en_rx_tb}),
.ctrl_sel(o_tx_en_tb),
.data_out(CRC_EN)
);

gen_mux #(8,1) DUT17 (
.data_in({o_crc_parallel_data_tx_tb , o_crc_parallel_data_rx_tb}),
.ctrl_sel(o_tx_en_tb),
.data_out(CRC_data)
);

gen_mux #(1,1) DUT18 (
.data_in({last_byte_tx , last_byte_rx}),
.ctrl_sel(o_tx_en_tb),
.data_out(last_byte)
);

gen_mux #(1,1) DUT19 (
.data_in({data_valid_tx , data_valid_rx}),
.ctrl_sel(o_tx_en_tb),
.data_out(data_valid) //all these muxes is for who is accessing crc block (tx or rx)
);

Exit_Detector DUT20 (
.i_sys_clk(i_sys_clk_tb),
.i_sys_rst(i_sys_rst_tb),
.i_scl(SCL),
.i_sda(i_sdahnd_rx_sda_tb),
.o_engine_done(exit_done_tb)
);

wire SDA2; //SDA of Blocks of tx and rx only not include enthdr response sda
wire SDA;
sda_handling DUT21 (
.i_handling_s_data (o_sdahnd_tgt_serial_data_tb),
.i_handling_sel_pp_od (1'b1),
.i_handling_pp_en (1'b1),
.sda (SDA),
.o_handling_s_data (i_sdahnd_rx_sada_tb)
); //non synthizable block but just to perform the behave of Open drain and Push Pull (not included in TOP_Module) 

assign SDA2 = i_sdahnd_rx_sda_tb; 
gen_mux #(1,1) DUT22 (
.data_in({sda_in , SDA2}),
.ctrl_sel(o_ENTHDR_en_tb),
.data_out(SDA) 
);//mux of SDA handled from controller_target enthdr top and from  this module to be on waveform (not included in top module)
pullup(SDA); 
///////////////////////CLK_Generator////////////////////////////////////
parameter CLK_PERIOD = 40;  	 
always #(CLK_PERIOD/2) i_sys_clk_tb = ~i_sys_clk_tb ;
integer i;
reg [19:0] data ;

initial 
 begin
  //////////////////////ent_hdr///////////////////////
    //////////////gonna be done by controller////////////
        ent = 0;
        stall = 1'b0;
        i_data_config_mux_sel   = 1'b0;
	initialize();
	reset();               
     	write_configurations();
     	i_data_config_mux_sel   = 1'b0;
        i_controller_en_tb = 1'b1 ;
        i_i3c_i2c_sel_tb   = 1'b1; 
//////////////////////////////////////////////////////      
        @(posedge ENTHDR_done) //start of our sequence
        ent = 1;
        #(CLK_PERIOD )   


  data = {2'b01,1'b1,7'd0,7'h66,1'b1,2'b10}; //testing complete read sequence
  for (i = 0 ; i < 19 ; i = i + 1)
   begin
     i_sdahnd_rx_sda_tb = data[19-i];
     #(2*CLK_PERIOD);
   end
  i_sdahnd_rx_sda_tb = data[0];
  @(o_ddrccc_rx_mode_done_tb);
  if(o_engine_decision_tb == 2'b01)
   begin
    #(CLK_PERIOD); 
   end
  //i_sdahnd_rx_sda_tb = 0; was for testing a framing error case
  i_sdahnd_rx_sda_tb = 1;
  #(2*CLK_PERIOD);
  i_sdahnd_rx_sda_tb = 1'bz;
  ////////////////////////////////////////
  @((o_tx_mode_tb == 1) && (tx_mode_done_tb));
  #(2*CLK_PERIOD);
  //i_sdahnd_rx_sda_tb = 0;
  //@(o_engine_done_tb);  //was for testing aborting case
  i_sdahnd_rx_sda_tb = 1;
  #(2*CLK_PERIOD);
  i_sdahnd_rx_sda_tb = 1'bz;
  @(tx_mode_done_tb)
  #(CLK_PERIOD);
  //o_cccnt_last_frame_tb = 1;
  @(o_engine_done_tb);
  @(!i_engine_en_tb); //end of full reading sequence
  gene_restart ();
  #(CLK_PERIOD); 
  //////////////////////////////////////////
  data = {2'b01,1'b0,7'd0,7'h66,1'b0,2'b01}; //testing complete write sequence
  for (i = 0 ; i < 19 ; i = i + 1)
   begin
     i_sdahnd_rx_sda_tb = data[19-i];
     #(2*CLK_PERIOD);
   end
  i_sdahnd_rx_sda_tb = data[0];
  #(2*CLK_PERIOD);
  i_sdahnd_rx_sda_tb = 1; 
  @(tx_mode_done_tb);
  i_sdahnd_rx_sda_tb = 1'bz;
  #(2*CLK_PERIOD);
  data[17:0] = {8'b01010101,8'b11001100,2'b01};
  for (i = 0 ; i < 18 ; i = i + 1)
   begin
     i_sdahnd_rx_sda_tb = data[17-i];
     #(2*CLK_PERIOD);
   end
  //i_sdahnd_rx_sda_tb = 1'b1;
  //#(2*CLK_PERIOD);
  //i_sdahnd_rx_sda_tb = 1'bz;  
  //@(o_engine_done_tb); //it was for testing aborting writing case
  //#(5*CLK_PERIOD); 
  //data[10:0] = {2'b01,4'b1100,5'b11011}; //for testing a crc error case
  data[10:0] = {2'b01,4'b1100,5'b10001};
  for (i = 0 ; i < 11 ; i = i + 1)
   begin
     i_sdahnd_rx_sda_tb = data[10-i];
     #(2*CLK_PERIOD);
   end
  //@(o_engine_done_tb && o_ddrccc_error_tb);
  //@(!i_engine_en_tb);
  gene_exitandstop;
  //@(!i_engine_en_tb);  //complete writing sequence with error in last stage (CRC) to make sure togglig of error flag
  //@(exit_done_tb); //complete writing sequence with exit a5iraaaaaaan el7 
  #(5*CLK_PERIOD); 
  $stop;
 end

///////////////////////initialize///////////////////////////////
task initialize; 
	begin
		i_sys_clk_tb 				= 1'b0;
		i_sys_rst_tb 				= 1'b1;
		i_i3c_i2c_sel_tb        = 1'b1;  //i3c mode
		i_controller_en_tb      = 1'b0;
		//i_hdr_en_tb				= 1'b0;
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
	    i_sys_rst_tb 		        = 1'b1;
		# (CLK_PERIOD)
		i_sys_rst_tb 				= 1'b0; // activated
		# (CLK_PERIOD)
		i_sys_rst_tb 				= 1'b1; // de-activated

	end	
	endtask
/////////////////////write_configurations//////////////////////
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

//////////generating_restart_task/////////////////////
task gene_restart ();
  begin
                #(CLK_PERIOD);
                stall = 1;
  		i_sdahnd_rx_sda_tb = 1;
  		repeat (4) begin
  		#(2*CLK_PERIOD);
		i_sdahnd_rx_sda_tb = ~ i_sdahnd_rx_sda_tb;
		end
		#(CLK_PERIOD);
                stall = 2; //for making 180 phase shift for scl iam using in testing 
                i_sdahnd_rx_sda_tb = 1;
                #(2*CLK_PERIOD);
  end
endtask

task gene_exitandstop ();
 begin
                stall = 1;
  		i_sdahnd_rx_sda_tb = 1;
  		repeat (7) begin
  		#(2*CLK_PERIOD);
		i_sdahnd_rx_sda_tb = ~ i_sdahnd_rx_sda_tb;
		end
		#(CLK_PERIOD);
                stall = 2;
                #(CLK_PERIOD);
                i_sdahnd_rx_sda_tb = 1;
                #(CLK_PERIOD);
                stall = 3; 
 end
endtask

  
endmodule
