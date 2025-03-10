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

module target_top (
input i_sys_clk,
input i_sys_rst,
input SCL,
input scl_pos_edge, scl_neg_edge,
inout SDA
);

  /////////nt_target/////////////  
  wire o_cccnt_last_frame;
  wire i_engine_en;
  wire tx_mode_done, o_ddrccc_rx_mode_done, o_ddrccc_pre;
  wire i_rx_ddrccc_rnw, o_ddrccc_error, o_tx_en, o_nt_rx_en;
  wire o_regf_wr_en, o_regf_rd_en; 
  wire [3:0] o_nt_rx_mode;
  wire [2:0] o_tx_mode;
  wire [9:0] o_regf_addr;
  wire o_frmcnt_en, i_sdr_scl_gen_pp_od;
  wire o_engine_done, o_bitcnt_en, o_bitcnt_reset, o_frmcnt_rnw;

nt_target U0_nt_target (
    .i_sys_clk(i_sys_clk),
    .i_sys_rst(i_sys_rst),
    .i_engine_en(i_engine_en),
    .i_frmcnt_last(o_cccnt_last_frame),
    .i_tx_mode_done(tx_mode_done),
    .i_rx_mode_done(o_ddrccc_rx_mode_done),
    .i_rx_pre(o_ddrccc_pre),
    .i_rx_ddrccc_rnw(i_rx_ddrccc_rnw),
    .i_rx_error(o_ddrccc_error), 
    .o_tx_en(o_tx_en),
    .o_tx_mode(o_tx_mode),
    .o_rx_en(o_nt_rx_en),
    .o_rx_mode(o_nt_rx_mode),
    .o_frmcnt_en(o_frmcnt_en),
    .o_sdahand_pp_od(i_sdr_scl_gen_pp_od),
    .o_regf_wr_en(o_regf_wr_en),
    .o_regf_rd_en(o_regf_rd_en),
    .o_regf_addr(o_regf_addr),
    .o_frmcnt_rnw(o_frmcnt_rnw),
    .o_engine_done(o_engine_done),
    .o_bitcnt_en (o_bitcnt_en),
    .o_bitcnt_reset (o_bitcnt_reset)
	);

	///////////////////////frame_counter//////////////////
	wire [5:0]  o_bitcnt;
	wire i_bitcnt_toggle;
        wire [15:0] o_frmcnt_max_rd_len, o_frmcnt_max_wr_len;
		
frame_counter_target U1_frame_counter_target (
    .i_fcnt_clk          (i_sys_clk),
    .i_fcnt_rst_n        (i_sys_rst),
    .i_fcnt_en           (o_frmcnt_en),
    .i_regf_MAX_RD_LEN     (o_frmcnt_max_rd_len),
    .i_regf_MAX_WR_LEN     (o_frmcnt_max_wr_len),
    .i_cnt_bit_count     (o_bitcnt),
    .i_bitcnt_toggle     (i_bitcnt_toggle),
    .i_nt_rnw            (o_frmcnt_rnw),
    .o_cccnt_last_frame  (o_cccnt_last_frame)
); 

//////////bit_counter////////////////////////

bits_counter_target U2_bits_counter_target (
		.i_sys_clk       (i_sys_clk),
		.i_rst_n 	  (i_rst_n),
		.i_bitcnt_en     (o_bitcnt_en),
                .abort_or_end_reset (o_bitcnt_reset),
		.i_scl_pos_edge  (scl_pos_edge),
		.i_scl_neg_edge  (scl_neg_edge),
		.o_frcnt_toggle  (i_bitcnt_toggle),
		.o_cnt_bit_count (o_bitcnt)
);

/////////////////////rx///////////////////////
wire [4:0] i_crc_value;
wire [7:0] o_regfcrc_rx_data_out, o_ccc_ccc_value;
wire [1:0] o_engine_decision;
wire [3:0]  o_rx_mode;
wire last_byte_rx;
wire o_crc_en_rx;
wire [7:0] o_crc_parallel_data_rx;
wire data_valid_rx;

target_rx U3_target_rx (
	.i_sys_clk					(i_sys_clk)				,
	.i_sys_rst					(i_sys_rst)				,
	.i_sclgen_scl				(SCL)			,
	.i_sclgen_scl_pos_edge		(scl_pos_edge)	,
	.i_sclgen_scl_neg_edge		(scl_neg_edge)	,
	.i_ddrccc_rx_en				(o_rx_en)			,
	.i_sdahnd_rx_sda			(SDA)		,
	.i_ddrccc_rx_mode			(o_rx_mode)		,
	.i_crc_value                           (i_crc_value),		
	.o_regfcrc_rx_data_out		(o_regfcrc_rx_data_out)	,
	.o_ddrccc_rx_mode_done		(o_ddrccc_rx_mode_done)	,
	.o_ddrccc_pre				(o_ddrccc_pre)			,
	.o_ddrccc_error_flag				(o_ddrccc_error)			,
	.o_ddrccc_rnw   (i_rx_ddrccc_rnw)  ,
	.o_engine_decision (o_engine_decision) ,
	.o_ccc_ccc_value (o_ccc_ccc_value)  ,
        .o_crc_en (o_crc_en_rx),
        .o_crc_data_valid (data_valid_rx),
        .o_crc_last_byte (last_byte_rx),
        .o_crc_data (o_crc_parallel_data_rx)   
);

//////////////////tx/////////////////////////////

wire [7:0] i_regf_tx_parallel_data ;
wire o_sdahnd_tgt_serial_data;
wire last_byte_tx;
wire o_crc_en__tx;
wire [7:0] o_crc_parallel_data_tx;
wire data_valid_tx;

tx_t  U4_tx_t(
   .i_sys_clk(i_sys_clk),
   .i_sys_rst(i_sys_rst),
   .i_sclgen_scl(scl),
   .i_sclgen_scl_pos_edge(scl_pos_edge),
   .i_sclgen_scl_neg_edge(scl_neg_edge),
   .i_ddrccc_tx_en(o_tx_en),
   .i_ddrccc_tx_mode(o_tx_mode),
   .i_regf_tx_parallel_data(i_regf_tx_parallel_data),
   .i_crc_crc_value(i_crc_value),
   .o_sdahnd_tgt_serial_data(o_sdahnd_tgt_serial_data),
   .o_ddrccc_tx_mode_done(tx_mode_done),
   .o_crc_en(o_crc_en_tx), 
   .o_crc_parallel_data(o_crc_parallel_data_tx),
   .o_crc_data_valid(data_valid_tx),
   .o_crc_last_byte (last_byte_tx)
);

///////////////////engine_nt_mux////////////////////////
wire engine_en ;
wire [1:0] engine_or_nt;
gen_mux #(1,2) U5_gen_mux(
.data_in({1'b0 , o_nt_rx_en , engine_en}),
.ctrl_sel(engine_or_nt),
.data_out(o_rx_en)
);

wire [3:0] engine_mode; 
gen_mux #(4,2) U6_gen_mux (
.data_in({4'b0 , o_nt_rx_mode , engine_mode}),
.ctrl_sel(engine_or_nt),
.data_out(o_rx_mode)
);

////////////////////engine//////////////////////////
wire restart_done; 
wire exit_done, ENTHDR_done, CCC_done;
wire o_ENTHDR_en_tb, o_CCC_en_tb;
Target_engine U7_Target_engine (
.i_sys_clk(i_sys_clk),
.i_sys_rst(i_sys_rst),
.i_rstdet_RESTART(restart_done),
.i_exitdet_EXIT(exit_done),
.i_ENTHDR_done(ENTHDR_done),
.i_CCC_done(CCC_done),
.i_NT_done(o_engine_done),
.i_rx_decision(o_engine_decision),
.i_rx_decision_done(o_ddrccc_rx_mode_done),
.o_muxes(engine_or_nt),
.o_ENTHDR_en(o_ENTHDR_en),
.o_NT_en(i_engine_en),
.o_CCC_en(o_CCC_en),
.o_rx_en(engine_en),
.o_rx_mode(engine_mode)
);

///////////////////regfile/////////////////////////

reg_file_t U8_reg_file_t(
.i_regf_clk (i_sys_clk),
.i_regf_rst_n (i_sys_rst),
.i_regf_rd_en (o_regf_rd_en),
.i_regf_wr_en (o_regf_wr_en),
.i_regf_addr (o_regf_addr),
.i_regf_data_wr(o_regfcrc_rx_data_out),
.o_frmcnt_max_rd_len(o_frmcnt_max_rd_len),
.o_frmcnt_max_wr_len(o_frmcnt_max_wr_len),
.o_regf_data_rd(i_regf_tx_parallel_data)
);

////////////////////restart_detector////////////////////////////
Restart_Detector U9_Restart_Detector (
.i_sys_clk(i_sys_clk),
.i_sys_rst(i_sys_rst),
.i_scl(SCL),
.i_sda(SDA),
.o_engine_done(restart_done)
);

/////////////////////enthdr_response//////////////

wire o_tgt_pp_od_sdahand;
ENTHDR_TGT U10_enthdr (
 .i_sys_clk   (i_sys_clk),
 .i_sys_rst   (i_sys_rst),
 .i_enigne_en (o_ENTHDR_en), 
 .i_sda       (SDA), 
 .i_scl          (SCL),
 .i_scl_pos_edge (scl_pos_edge) ,
 .i_scl_neg_edge (scl_neg_edge),
 . o_sdahnd_sda (o_tgt_sdahnd_sda) ,
 . o_pp_od      (o_tgt_pp_od_sdahand), 
 . o_engine_done(ENTHDR_done) 
);

gen_mux #(1,1) U11_gen_mux ( //who on bus 
.data_in({o_tgt_sdahnd_sda , o_sdahnd_tgt_serial_data}),
.ctrl_sel(o_ENTHDR_en_tb),
.data_out(SDA)
);

/////////////////////crc/////////////////////////////////
wire crc_valid, last_byte, data_valid, CRC_EN;
wire [7:0] CRC_data;
crc U12_crc (
.i_sys_clk (i_sys_clk),
.i_sys_rst(i_sys_rst),
.i_txrx_en(CRC_EN),
.i_txrx_data_valid(data_valid),
.i_txrx_last_byte(last_byte),
.i_txrx_data(CRC_data),
.o_txrx_crc_value(i_crc_value),
.o_txrx_crc_valid(crc_valid)
);

////////////////crc_muxes//////////////////////////////
gen_mux #(1,1) U13_gen_mux (
.data_in({o_crc_en_tx , o_crc_en_rx}),
.ctrl_sel(o_tx_en_tb),
.data_out(CRC_EN)
);

gen_mux #(8,1) U14_gen_mux (
.data_in({o_crc_parallel_data_tx , o_crc_parallel_data_rx}),
.ctrl_sel(o_tx_en),
.data_out(CRC_data)
);

gen_mux #(1,1) U15_gen_mux (
.data_in({last_byte_tx , last_byte_rx}),
.ctrl_sel(o_tx_en),
.data_out(last_byte)
);

gen_mux #(1,1) U16_gen_mux (
.data_in({data_valid_tx , data_valid_rx}),
.ctrl_sel(o_tx_en),
.data_out(data_valid)
);

////////////////////exit_detector///////////////////
Exit_Detector U17_Exit_Detector (
.i_sys_clk(i_sys_clk),
.i_sys_rst(i_sys_rst),
.i_scl(SCL),
.i_sda(SDA),
.o_engine_done(exit_done)
);	

endmodule