`timescale 1ns/1ns

module tb();


logic				clk;

// Trigger is high for one cycle only.
logic				trigger;
logic				reset;

// Cache & Store buffer
logic				cache_data_req_o;
logic	[31:0]	cache_r_addr_o;
logic				strBuf_data_req_o;
logic	[31:0]	strBuf_r_addr_o;

logic				wait_cache;
logic				wait_strBuf;

logic				cache_data_ready;
logic				strBuf_data_ready;

logic	[31:0]	cache_data_i;
logic	[31:0]	strBuf_data_i;

logic	[31:0]	w_addr_o;
logic	[31:0]	w_data_o;

// Misc
logic	[3:0]		outState;

prefetcherTop dut ( .* );

initial clk = '1;
always #10 clk = ~clk;  // 50 MHz clock

localparam numCacheLoads	= 100;
localparam numStrBufLoads	= 10;
localparam cache_latency	= 3;
localparam strBuf_latency	= 3;


logic [31:0]	cache_data_arr 	[numCacheLoads-1:0];
logic [31:0]	cache_addr_arr 	[numCacheLoads-1:0];

logic [31:0]	strBuf_data_arr	[numStrBufLoads-1:0];
logic [31:0]	strBuf_addr_arr	[numStrBufLoads-1:0];

logic failed;


initial begin
	integer cacheData_inFile;
	integer cacheAddr_inFile;
	integer strBufData_inFile;
	integer strBufAddr_inFile;
	integer i = 0;		// Cache loads index
	integer j = 0;		// strBuf loads index
	integer k = 0;
	
	
	cacheData_inFile	= $fopen("cacheData", "r");
	cacheAddr_inFile	= $fopen("cacheAddr", "r");
	strBufData_inFile	= $fopen("strBufData", "r");
	strBufAddr_inFile	= $fopen("strBufAddr", "r");
	
	for (int ix = 0; i < numCacheLoads; i++) begin
		integer in1, in2;
		
		// Read from file
		in1 = $fscanf(cacheData_inFile, "%h", cache_data_arr[ix]);
		in2 = $fscanf(cacheAddr_inFile, "%h", cache_addr_arr[ix]);
	end
	
	for (int iy = 0; i < numStrBufLoads; i++) begin
		integer in3, in4;
		
		// Read from file
		in3 = $fscanf(strBufData_inFile, "%h", strBuf_data_arr[iy]);
		in4 = $fscanf(strBufAddr_inFile, "%h", strBuf_addr_arr[iy]);
	end
	
	$fclose(cacheData_inFile);
	$fclose(cacheAddr_inFile);
	$fclose(strBufData_inFile);
	$fclose(strBufAddr_inFile);
	
	failed				= 'b0;
	trigger				= 'b0;
	wait_cache			= 'b0;
	wait_strBuf			= 'b0;
	cache_data_ready	= 'b0;
	strBuf_data_ready	= 'b0;
	cache_data_i		= 'h0;
	strBuf_data_i		= 'h0;
	
	reset = 1'b1;
	@(negedge clk);
	@(negedge clk);
	reset = 1'b0;
	@(negedge clk);
	
	// Start
	trigger	= 'b1;
	@(negedge clk);
	trigger	= 'b0;
	
	
	while ((i < numCacheLoads) && (j < numStrBufLoads)) begin
		cache_data_ready	= 'b0;
		strBuf_data_ready	= 'b0;
		wait_cache			= 'b0;
		wait_strBuf			= 'b0;
		
		@(negedge clk);
		
		if (cache_data_req_o == 1 && strBuf_data_req_o == 1) begin
			if ((cache_r_addr_o != cache_addr_arr[i]) || (strBuf_r_addr_o != strBuf_addr_arr[j])) begin
				$display("cacheAddr: %d, cacheAddr_g: %d, strBufAddr: %d, strBufAddr_g: %d, strat time: ",
						cache_r_addr_o, cache_addr_arr[i], strBuf_r_addr_o, strBuf_addr_arr[j], $time);
				failed = 'b1;
			end
			
			cache_data_i	= cache_data_arr[i];
			strBuf_data_i	= strBuf_data_arr[j];
			i++;
			j++;
			
			wait_cache	= 'b1;
			wait_strBuf	= 'b1;
			for (k = 0; k < ((cache_latency > strBuf_latency)?cache_latency:strBuf_latency)-1; k++) begin
				@(negedge clk);
			end
			
			cache_data_ready	= 'b1;
			strBuf_data_ready	= 'b1;
			wait_cache			= 'b0;
			wait_strBuf			= 'b0;
		end
		else if (cache_data_req_o == 1) begin
			if (cache_r_addr_o != cache_addr_arr[i]) begin
				$display("cacheAddr: %d, cacheAddr_g: %d, strat time: ",
						cache_r_addr_o, cache_addr_arr[i], strBuf_r_addr_o, strBuf_addr_arr[j], $time);
				failed = 'b1;
			end
			
			cache_data_i	= cache_data_arr[i];
			i++;
			
			wait_cache	= 'b1;
			
			for (k = 0; k < cache_latency-1; k++) begin
				@(negedge clk);
			end
			
			cache_data_ready	= 'b1;
			wait_cache			= 'b0;
		end
		else if (strBuf_data_req_o == 1) begin
			if (strBuf_r_addr_o != strBuf_addr_arr[j]) begin
				$display("strBufAddr: %d, strBufAddr_g: %d, strat time: ",
						strBuf_r_addr_o, strBuf_addr_arr[j], $time);
				failed = 'b1;
			end
			
			
			strBuf_data_i	= strBuf_data_arr[j];
			j++;
			
			wait_strBuf	= 'b1;
			
			for (k = 0; k < strBuf_latency-1; k++) begin
				@(negedge clk);
			end
			
			strBuf_data_ready	= 'b1;
			wait_strBuf			= 'b0;
		end
		
		@(negedge clk);
	end
	

	if (failed == 1) begin
		$display("Somthing is wrong");
	end
	else begin
		$display("Great success!!");
	end
	
	wait_cache			= 'b0;
	wait_strBuf			= 'b0;
	cache_data_ready	= 'b0;
	strBuf_data_ready	= 'b0;
	cache_data_i		= 'h0;
	strBuf_data_i		= 'h0;
		
	@(negedge clk);
	reset = 1'b0;
	@(negedge clk);
	
	$stop(0);
end



endmodule
