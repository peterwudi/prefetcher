

`ifdef graph 

always @(posedge clk) begin	
	if (reset) begin
		state				<= 'b0;
		state_cycle		<= 'b0;
		cache_data[0]	<= 'b0;
		cache_data[1]	<= 'b0;
		strBuf_data[0]	<= 'b0;
		strBuf_data[1]	<= 'b0;
		wren[0]			<= 'b0;
		wren[1]			<= 'b0;
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
			cache_data[0] <= cache_data_i[0];
			cache_data[1] <= cache_data_i[1];
		end
		
		if (wait_strBuf & strBuf_data_ready) begin
			strBuf_data[0] <= strBuf_data_i[0];
			strBuf_data[1] <= strBuf_data_i[1];
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
				// 0x9338 - 0x9362 + 0x938e-0x939a
				case (state_cycle)
					'd0: begin
						// 9338:	ldr.w	sl, [r9, #8]!
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[9] + 'd8;

						// 933c:	ldr	r0, [sp, #36]
						cache_r_addr[1]	<= rf[13] + 'd36;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[10]		<= cache_data[0];
						rf[0]			<= cache_data[1];
					
						// 933e:	add.w	r3, r0, sl, lsl #3
						// 9346:	ldrd	r4, r5, [r3]
						// => ldrd r4, r5, [r0+sl<<3]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= cache_data[0] + cache_data[1] << 3;
						// Know it's a double load, just need a flag,
						// no need to calculate addr
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[4]			<= cache_data[0];
						rf[5]			<= cache_data[1];
						
						// 9352:	ldrd	r2, r3, [sp, #24]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[13] + 'd24;
						
						
						// 938e:	mov.w	r0, r4, rrx
						rf[0]	<= {c, rf[4][31:1]};
						
						state_cycle <= 'd3;
					end
					'd3: begin
						// 935e:	strd	r2, r3, [sp, #8]
						w_addr		= rf[13] + 'd8;
						w_data		= cache_data[0];
						w_data		= cache_data[1];
						
						// 9396:	lsls	r3, r0, #4
						// flags are immediately updated by cmp
						rf[3]	<= rf[0]	<< 4;
						
						// 9392:	and.w	r2, r4, #1
						// 9398:	cmp	r2, #0
						// => cmp r4&1 , #0
						// 939a:	bne.n	9364 <make_bfs_tree+0x118>
						if (rf[4]&1'b1 != 0) begin
							state_cycle <= 'd0;
							state			<= 'd3;
						end
						else begin
							state_cycle <= 'd0;
							state			<= 'd2;
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
			'd2: begin
				// 0x9364 - 0x936a
				case (state_cycle)
					'd0: begin
						// add.w	r2, r7, r0, lsl #4
						rf[2]		<= rf[7] + rf[0] << 4;
						
						// ldr	r1, [r2, #8]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[2] + 8;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[1]		<= cache_data;
					
						// ldr	r6, [r2, #12]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[2] + 'd12;
						
						state_cycle 	<= 'd0;
						state				<= 'd3;
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
				// 0x936c - 0x937e
				case (state_cycle)
					'd0: begin
						// add.w	r0, r8, r1, lsl #3
						rf[0]		<= rf[8] + rf[1] << 3;
						
						// add.w	r4, lr, r4, lsl #3
						rf[4]		<= rf[14] + rf[4]	<< 3;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						// DLI: ldrd	r2, r3, [r0]
						// First load: ldr r2, [r0]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[0];
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[2]		<= cache_data;
						
						// cmp	r2, #0
						// "A carry occurs: if the result of a subtraction is positive or zero"
						c			<= (rf[2] >= 0) ? 1'b1: 1'b0;
						
						// DLI: ldrd	r2, r3, [r0]
						// Second load: ldr r3, [r0, #4]
						cache_data_req	<= 'b1;
						cache_r_addr	<= rf[0] + 'd4;
						
						state_cycle <= 'd3;
					end
					'd3: begin
						rf[3]		<= cache_data;
						
						// sbcs.w	r5, r3, #0
						// "If the carry flag is clear, the result is reduced by one."
						if (c == 0) begin
							rf[5]	<= cache_data - 'd1;
							
							// Set n flag
							n		<= (cache_data - 'd1 < 0) ? 1'b1 : 1'b0;
							
							// Set v flag
							v		<= (cache_data == 32'h8000) ? 1'b1 : 1'b0;
						end
						else begin
							rf[5]	<= cache_data;
							
							// Set n flag
							n		<= (cache_data < 0) ? 1'b1 : 1'b0;
							
							// Set v flag
							v		<= 1'b0;
						end
						
						state_cycle	<= 'd4;
					end
					'd4: begin						
						// blt.n	93a4 <make_bfs_tree+0x158>
						// LT: N and V differ
						if (n != v) begin
							state_cycle 	<= 'd0;
							state				<= 'd7;
						end
						else begin
							state_cycle 	<= 'd0;
							state				<= 'd4;
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
				// 0x9380 - 0x938a
				case (state_cycle)
					'd0: begin
						// DLI: ldrd	r4, r5, [r4]
						// First load: ldr r4, [r4]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[4];
						
						// Copy r4+4 into the temp reg
						// Essentially: add temp, r4, #4
						temp					<= rf[4] + 'd4;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[4]			<= cache_data;
						
						// DLI: ldrd	r4, r5, [r4]
						// Second load: ldr r5, [temp]
						cache_data_req		<= 'b1;
						cache_r_addr		<= temp;
						
						// cmp	r4, #0
						// "A carry occurs: if the result of a subtraction is positive or zero"
						c			<= (cache_data[31] == 0) ? 1'b1: 1'b0;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[5]			<= cache_data;
						
						// sbcs.w	r6, r5, #0
						// "If the carry flag is clear, the result is reduced by one."
						if (c == 0) begin
							rf[6]	<= cache_data - 'd1;
							
							// Set n flag
							n		<= (cache_data - 'd1 < 0) ? 1'b1 : 1'b0;
							
							// Set v flag
							v		<= (cache_data == 32'h8000) ? 1'b1 : 1'b0;
						end
						else begin
							rf[6]	<= cache_data;
							
							// Set n flag
							n		<= (cache_data < 0) ? 1'b1 : 1'b0;
							
							// Set v flag
							v		<= 1'b0;
						end
						state_cycle <= 'd3;
					end
					'd3: begin						
						// blt.n	93d0 <make_bfs_tree+0x184>
						// LT: N and V differ
						if (n != v) begin
							state_cycle 	<= 'd0;
							state				<= 'd8;
						end
						else begin
							state_cycle 	<= 'd0;
							state				<= 'd5;
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
				// 0x938e - 0x939a
				case (state_cycle)
					'd0: begin
						// mov.w	r0, r4, rrx
						rf[0]	<= {c, rf[4][31:1]};
						
						// and.w	r2, r4, #1
						rf[2]	<= rf[4]	& 32'h00000001;
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						// lsls	r3, r0, #4
						// flags are immediately updated by cmp
						rf[3]	<= rf[0]	<< 4;
			
						// cmp	r2, #0
						// bne.n	9364 <make_bfs_tree+0x118>
						if (rf[2] != 'b0) begin
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
				// 0x939c - 0x93a2
				case (state_cycle)
					'd0: begin
						// adds	r2, r7, r3
						rf[2]	<= rf[7] + rf[3];
						
						// ldr	r1, [r7, r3]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[7] + rf[3];
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						rf[1]		<= cache_data;
						
						// ldr	r6, [r2, #4]
						cache_data_req		<= 'b1;
						cache_r_addr		<= rf[2] + rf[4];
						
						state_cycle			<= 'd2;
					end
					'd2: begin
						rf[6]			<= cache_data;
						
						// b.n	936c <make_bfs_tree+0x120>
						state			<= 'd3;
						state_cycle	<= 'b0;
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
				// 0x93a6 - 0x93ce
				case (state_cycle)
					'd0: begin
						// movs	r2, #1
						rf[2]			<= 'b1;
						
						// movs	r3, #0
						rf[3]			<= 'b0;

						// ldrd	sl, fp, [sp, #8]
						// First load: ldr sl, [sp, #8]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd8;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						// sl is overwritten immediately
						
						// ldrd	sl, fp, [sp, #8]
						// Second load: ldr fp, [sp, #12]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd12;
					
						// adds.w	sl, sl, r2
						rf[10]		<= strBuf_data + rf[2];
						carry_test	<= strBuf_data + rf[2];
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[11]		<= strBuf_data;
						
						// "A carry occurs: if the result of an addition is greater than or equal to 2^32"
						c	<= (carry_test[32] == 1) ? 1'b1 : 1'b0;
						
						state_cycle <= 'd3;
					end
					'd3: begin
						// adc.w	fp, fp, r3
						// "adding a further one if the carry flag is set"
						rf[11]		<= rf[11] + rf[3] + c;
						
						// strd	sl, fp, [sp, #8]
						// First store: str sl, [sp, #8]
						w_addr		= rf[13] + 'd8;
						w_data		= rf[10];
						
						state_cycle <= 'd4;
					end
					'd4: begin
						// strd	sl, fp, [sp, #8]
						// Second store: str fp, [sp, #12]
						w_addr		= rf[13] + 'd12;
						w_data		= rf[11];
						
						// b.n	9380 <make_bfs_tree+0x134>
						state_cycle <= 'd0;
						state			<= 'd4;
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
			'd8: begin
				// 0x93d0 - 0x94c8
				case (state_cycle)
					'd0: begin
						// ldrd	r4, r5, [sp, #8]
						// First load: ldr r4, [sp, #8]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd8;
						
						// movs	r2, #1
						rf[2]		<= 'b1;
						
						// movs	r3, #0
						rf[3]		<= 'b0;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[4]		<= strBuf_data;
					
						// ldrd	r4, r5, [sp, #8]
						// Second load: ldr r4, [sp, #12]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd12;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[5]		<= strBuf_data;
						
						// ldrd	r0, r1, [sp, #16]
						// First load: ldr r0, [sp, #16]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd16;
						
						
						state_cycle <= 'd3;
					end
					'd3: begin
						// r0 is overwritten immediately
						
						// ldrd	r0, r1, [sp, #16]
						// Second load: ldr r1, [sp, #20]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr		<= rf[13] + 'd20;
						
						// adds	r0, r0, r2
						rf[0]			<= strBuf_data + rf[2];
						carry_test	<= strBuf_data + rf[2];
						
						state_cycle <= 'd4;
					end
					'd4: begin
						rf[1]		<= strBuf_data;
						
						// "A carry occurs: if the result of an addition is greater than or equal to 2^32"
						c	<= (carry_test[32] == 1) ? 1'b1 : 1'b0;
						
						state_cycle <= 'd5;
					end
					'd5: begin
						// adc.w	r1, r1, r3
						// "adding a further one if the carry flag is set"
						rf[1]		<= rf[1] + rf[3] + c;
						
						// strd	r0, r1, [sp, #16]
						// First store: str r0, [sp, #16]
						w_addr		= rf[13] + 'd16;
						w_data		= rf[0];
						
						// cmp	r0, r4
						// "A carry occurs: if the result of a subtraction is positive or zero"
						c	<= (rf[0] >= rf[4]) ? 1'b1: 1'b0;
						
						state_cycle <= 'd6;
					end
					'd6: begin
						// strd	r0, r1, [sp, #16]
						// Second store: str r1, [sp, #20]
						w_addr		= rf[13] + 'd20;
						w_data		= rf[1];
						
						// sbcs.w	r5, r1, r5
						// "If the carry flag is clear, the result is reduced by one."
						rf[5]		<= (c == 0) ?  rf[1] - rf[5] - 'd1 :  rf[1] - rf[5];
						
						// blt.n	9410 <make_bfs_tree+0x1c4>
						// b.n	9338 <make_bfs_tree+0xec>
						// These branch always gets executed regardless of the flags
						state_cycle <= 'd0;
						state			<= 'd1;
					end
					default: begin
						cache_data_req		<= 'b0;
						strBuf_data_req	<= 'b0;
						state_cycle			<= 'd0;
						state					<= 'd0;
					end
				endcase
			end
		endcase
	end
end

`endif

