

`ifdef svm 
always @(posedge clk) begin	
	if (reset) begin
		state				<= 'b0;
		state_cycle		<= 'b0;
		cache_data		<= 'b0;
		strBuf_data		<= 'b0;
		c					<= 'b0;
		z					<= 'b0;
		n					<= 'b0;
		v					<= 'b0;
		rf[0] 			<= 'b0;
		rf[1] 			<= 'b0;
		rf[2] 			<= 'b0;
		rf[3] 			<= 'b0;
		rf[4] 			<= 'b0;
		rf[5] 			<= 'b0;
		rf[6] 			<= 'b0;
		rf[7] 			<= 'b0;
		rf[8] 			<= 'b0;
		rf[9] 			<= 'b0;
		rf[10] 			<= 'b0;
		rf[11] 			<= 'b0;
		rf[12] 			<= 'b0;
		rf[13] 			<= 'b0;
		rf[14] 			<= 'b0;
		rf[15] 			<= 'b0;
	end
	else if (wait_cache | wait_strBuf) begin
		// Wait for loads
		// Lower the requests
		cache_data_req		<= 'b0;
		strBuf_data_req	<= 'b0;
		
		if (wait_cache & cache_data_ready) begin
			cache_data <= cache_data_i;
		end
		
		if (wait_strBuf & strBuf_data_ready) begin
			strBuf_data <= strBuf_data_i;
		end
	end
	else begin
		case (state)
			'd0: begin
				// Init state
				if (trigger) begin
					state		<= 'd1;
					rf[0] 	<= 'd0;
					rf[1] 	<= 'd1;
					rf[2] 	<= 'd2;
					rf[3] 	<= 'd3;
					rf[4] 	<= 'd4;
					rf[5] 	<= 'd5;
					rf[6] 	<= 'd6;
					rf[7] 	<= 'd7;
					rf[8] 	<= 'd8;
					rf[9] 	<= 'd9;
					rf[10] 	<= 'd10;
					rf[11] 	<= 'd11;
					rf[12] 	<= 'd12;
					rf[13] 	<= 'd13;
					rf[14] 	<= 'd14;
					rf[15] 	<= 'd15;
				end
				else begin
					state		<= 'd0;
				end
			end
			'd1: begin
				// 0x951a - 0x9536
				case (state_cycle)
					'd0: begin
						// ldr	r1, [sp, #16]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[13] + 'd16;

						state_cycle <= 'd1;
					end
					'd1: begin
						// ldr	r6, [r1, #0]
						cache_data_req	<= 'b1;
						cache_r_addr	<= cache_data;

						// movs	r1, #0
						rf[1]			<= 'b0;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[6]			<= cache_data;
						
						// ldr	r3, [r6, #0]
						cache_data_req	<= 'b1;
						cache_r_addr	<= cache_data;
						
						// str	r1, [sp, #4]						
						w_addr		= rf[13] + 'd4;
						w_data		= rf[1];
						
						state_cycle <= 'd3;
					end
					'd3: begin
						rf[3]			<= cache_data;
						
						// ldr.w	fp, [r0, #8]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[0] + 'd8;
						
						// str	r6, [sp, #8]
						w_addr		= rf[13] + 'd8;
						w_data		= rf[6];
						
						state_cycle <= 'd4;
					end
					'd4: begin
						rf[11]		<= cache_data;
						
						state_cycle <= 'd0;
						state			<= 'd2;
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd2: begin
				// 0x9538 - 0x9564
				case (state_cycle)
					'd0: begin
						// adds	r7, r3, #1
						rf[7]		<= rf[3] + 1;
						
						// ldr.w	r3, [fp, r3, lsl #2]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[11] + (rf[3] << 2);
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[3]		<= cache_data;
					
						// add.w	sl, fp, r7, lsl #2
						rf[10]	<= rf[11] + rf[7]	<< 2;
					
						// ldr	r1, [r0, #4]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[0] + 'd4;
						
						// mov.w	r8, r3, lsl #2
						rf[8]		<= rf[3] << 2;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[1]		<= cache_data;
						
						// add.w	r9, r1, r8
						rf[9]		<= rf[1] + rf[8];
						
						// movs	r1, #0
						rf[1]		<= 0;
						
						// b.n	956e <sm_sv_mul+0x66> always jumps, therefore when jumped
						// from state 2, the state_cycle of state 3 should be 1;
						state			<= 'd3;
						state_cycle <= 'd1;
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd3: begin
				// 0x9568 - 0x9590
				case (state_cycle)
					'd0: begin
						// adds	r1, #4
						rf[1]		<= rf[1] + 4;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						// ldr.w	r4, [r9, r1]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[9] + rf[1];
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[4]		<= cache_data;
						
						// delinquent: ldr.w	r5, [r2, r4, lsl #2]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[2] + (rf[4] << 2);
						
						state_cycle <= 'd3;
					end
					'd3: begin
						rf[5]		<= cache_data;
						
						// ldr	r4, [r0, #16]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[0] + 'd16;
						
						state_cycle	<= 'd4;
					end
					'd4: begin
						rf[4]		<= cache_data;
						
						// ldr.w	r5, [sl]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[10];
						
						// adds	r3, #1
						rf[3]		<= rf[3] + 1;
						
						state_cycle	<= 'd5;
					end
					'd5: begin
						rf[5]		<= cache_data;
						
						// cmp	r3, r5
						// blt.n	9566 <sm_sv_mul+0x5e>
						if (rf[3] < cache_data) begin
							state_cycle <= 'd0;
							state			<= 'd3;
						end
						else begin
							state_cycle <= 'd0;
							state			<= 'd4;
						end	
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd4: begin
				// 0x9592 - 0x959e
				case (state_cycle)
					'd0: begin
						// ldr	r3, [sp, #16]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[13] + 'd16;
						
						// ldr	r1, [sp, #4]
						// Load from the store buffer, so OK to load in the same cycle
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd4;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[3]			<= cache_data;
						rf[1]			<= strBuf_data;
						
						// ldr	r5, [r3, #8]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[3] + 'd8;
						
						// adds	r1, #1
						rf[1]			<= rf[1] + 'd1;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[5]			<= cache_data;
						
						// str	r1, [sp, #4]						
						w_addr		= rf[13] + 'd4;
						w_data		= rf[1];
						
						// cmp	r1, r5
						// bge.n	95c2 <sm_sv_mul+0xba>
						if (rf[1] >= cache_data) begin
							state			<= 'd6;
							state_cycle <= 'b0;
						end
						else begin
							state			<= 'd5;
							state_cycle <= 'd0;
						end
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd5: begin
				// 0x9592 - 0x95b2
				case (state_cycle)
					'd0: begin
						// ldr	r1, [sp, #8]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd8;
						
						// ldr.w	r3, [r1, #4]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[1] + 'd4;
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						rf[1]		<= strBuf_data;
						rf[3]		<= cache_data;
			
						// str	r1, [sp, #8]
						w_addr		= rf[13] + 'd8;
						w_data		= rf[1];
			
						// cmp	r3, r4
						// ble.n	9538 <sm_sv_mul+0x30>
						if (cache_data <= rf[4]) begin
							state			<= 'd2;
							state_cycle	<= 'b0;
						end
						else begin
							state			<= 'd6;
							state_cycle	<= 'b0;
						end
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd6: begin
				// 0x95c2 - 0x95c8
				case (state_cycle)
					'd0: begin
						// ldr	r3, [sp, #20]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd20;
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						// subs	r3, #1
						rf[3]		<= cache_data - 1;
						
						// str	r3, [sp, #20]
						w_addr		= rf[13] + 'd20;
						w_data		= cache_data;
						
						// The cmp insn is:
						// 959c	cmp	r1, r5
						if (rf[1] != rf[5]) begin
							state_cycle	<= 'd0;
							state			<= 'd1;
						end
						else begin
							state			<= 'd7;
							state_cycle	<= 'd0;
						end
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd7: begin
				// Do nothing
			end
		endcase
	end
end

`endif
