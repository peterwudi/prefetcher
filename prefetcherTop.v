//`define		spmvm
`define	graph
//`define	svm



module prefetcherTop(
	input					clk,
	
	// Trigger is high for one cycle only.
	input					trigger,
	input					reset,
	
	// Cache & Store buffer
	output				cache_data_req_o,
	output	[31:0]	cache_r_addr_o		[1:0],
	output				strBuf_data_req_o,
	output	[31:0]	strBuf_r_addr_o	[1:0],
	output				strBufWren			[1:0],
	
	input					wait_cache,
	input					wait_strBuf,
	
	input					cache_data_ready,
	input					strBuf_data_ready,

	input		[31:0]	cache_data_i	[1:0],
	input		[31:0]	strBuf_data_i	[1:0],
	
	output	[31:0]	w_addr_o	[1:0],
	output	[31:0]	w_data_o	[1:0],
	
	
	// Misc
	output	[3:0]		outState
);

// R11: FP, R10: SL, R13: SP, R14: LR, R15: PC.

reg	[31:0]	rf			[15:0] /*synthesis keep*/;
reg	[3:0]		state;
reg 	[4:0] 	state_cycle;

// Temp register
reg			[31:0]	temp;
reg signed	[32:0]	carry_test;	


// Flags
reg	c, z, n, v = 1'b0;

assign outState = state;

reg	[31:0]	w_addr	[1:0];
reg	[31:0]	w_data	[1:0];
reg				wren		[1:0];

assign w_addr_o[0] = w_addr[0];
assign w_addr_o[1] = w_addr[1];
assign w_data_o[0] = w_data[0];
assign w_data_o[1] = w_data[1];

reg signed	[31:0]	cache_data		[1:0];
reg signed	[31:0]	strBuf_data		[1:0];


reg				cache_data_req;
reg	[31:0]	cache_r_addr	[1:0];
reg				strBuf_data_req;
reg	[31:0]	strBuf_r_addr	[1:0];

assign cache_data_req_o		= cache_data_req;
assign cache_r_addr_o[0]	= cache_r_addr[0];
assign cache_r_addr_o[1]	= cache_r_addr[1];
assign strBuf_data_req_o	= strBuf_data_req;
assign strBuf_r_addr_o[0]	= strBuf_r_addr[0];
assign strBuf_r_addr_o[1]	= strBuf_r_addr[1];
assign strBufWren[0]			= wren[0];
assign strBufWren[1]			= wren[1];


`include "spmvm.v"
`include "svm.v"
`include "graph.v"
	
	
endmodule






