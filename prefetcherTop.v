`define		spmvm
//`define	svm
//`define	graph



module prefetcherTop(
	input					clk,
	
	// Trigger is high for one cycle only.
	input					trigger,
	input					reset,
	
	// Cache & Store buffer
	output				cache_data_req_o,
	output	[31:0]	cache_r_addr_o,
	output				strBuf_data_req_o,
	output	[31:0]	strBuf_r_addr_o,
	
	input					wait_cache,
	input					wait_strBuf,
	
	input					cache_data_ready,
	input					strBuf_data_ready,

	input		[31:0]	cache_data_i,
	input		[31:0]	strBuf_data_i,
	
	output	[31:0]	w_addr_o,
	output	[31:0]	w_data_o,
	
	
	// Misc
	output	[3:0]		outState
);

// R11: FP, R10: SL, R13: SP, R14: LR, R15: PC.

reg	[31:0]	rf			[15:0];
reg	[3:0]		state;
reg 	[4:0] 	state_cycle;

assign outState = state;

reg	[31:0]	w_addr;
reg	[31:0]	w_data;

assign w_addr_o = w_addr;
assign w_data_o = w_data;

reg	[31:0]	cache_data;
reg	[31:0]	strBuf_data;


reg				cache_data_req;
reg	[31:0]	cache_r_addr;
reg				strBuf_data_req;
reg	[31:0]	strBuf_r_addr;

assign cache_data_req_o		= cache_data_req;
assign cache_r_addr_o		= cache_r_addr;
assign strBuf_data_req_o	= strBuf_data_req;
assign strBuf_r_addr_o		= strBuf_r_addr;


`include "spmvm.v"
`include "svm.v"
`include "graph.v"
	
	
endmodule






