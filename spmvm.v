`ifdef spmvm

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
				// 0x951a - 0x9590 without 0x9568
				case (state_cycle)
					'd0: begin
						// 951a	ldr	r1, [sp, #16]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[13] + 'd16;
						
						// 952c	ldr.w	fp, [r0, #8]
						cache_r_addr[1]	<= rf[0] + 'd8;
						
						// 9532	movs	r1, #0
						// 9536	str	r1, [sp, #4]
						// Combine: str #0, [sp, #4]
						w_addr[0]	<= rf[13] + 'd4;
						w_data[0]	<= 'b0;
						wren[0]		<= 1'b1;

						state_cycle <= 'd1;
					end
					'd1: begin
						wren[0]		<= 1'b0;
					
						// ldr	r6, [r1, #0]
						cache_data_req	<= 'b1;
						cache_r_addr[0]	<= cache_data[0];

						// 9554	ldr	r1, [r0, #4]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[0] + 'd4;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[6]			<= cache_data[0];
						
						// 9522	ldr	r3, [r6, #0]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= cache_data[0];
						
						// 9534	str	r6, [sp, #8]
						w_addr[0]	<= rf[13] + 'd8;
						w_data[0]	<= cache_data[0];
						wren[0]		<= 1'b1;
						
						state_cycle <= 'd3;
					end
					'd3: begin
						// r3 will be overwritten
						//rf[3]			<= cache_data[0];
						wren[0]		<= 1'b0;
						
						// 9538	adds	r7, r3, #1
						rf[7]			<= cache_data[0] + 'd1;
						
						// 9546	add.w	sl, fp, r7, lsl #2
						// Dependent on r7 but can calculate
						rf[13]		<= rf[11] + ((cache_data[0] + 'd1) << 2);
						
						// 953a	ldr.w	r3, [fp, r3, lsl #2]			
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[11] + cache_data[0] << 2;
						
						state_cycle <= 'd4;
					end
					'd4: begin
						// 958c	adds	r3, #1
						rf[3]		<= cache_data[0] + 'd1;
						
						// 9588	ldr.w	r5, [sl]
						// The DLI loads r5 and overwritten by this insn
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[13];
						
						// 956e	ldr.w	r4, [r9, r1]
						// r9 is only used to load r4, and it's from
						// 9556	mov.w	r8, r3, lsl #2
						// 955c	add.w	r9, r1, r8
						// r8 is only used to calculate r9
						// r3 used here is the old r3, before 958c	adds	r3, #1
						cache_r_addr[1]	<= rf[1] + (cache_data[0] << 2);
						
						// 9560	movs	r1, #0
						rf[1]			<= 'b0;
						
						state_cycle <= 'd5;
					end
					'd5: begin
						rf[5]		<= cache_data[0];
						rf[4]		<= cache_data[1];
						
						
						// DLI: 9576	ldr.w	r5, [r2, r4, lsl #2]
						// r5 was overwritten, disgard the content it loads
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[2] + cache_data[1];
						
						
						// 9582	ldr	r4, [r0, #16]
						// r4 is only needed in s4,
						// otherwise it will be overwritten
						cache_r_addr[1]	<= rf[0] + 'd16;
						
						// 958e	cmp	r3, r5
						// 9590	blt.n	9566 <sm_sv_mul+0x5e>
						if (rf[3] < cache_data[0]) begin
							state_cycle <= 'd0;
							state			<= 'd2;
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
			'd2: begin
				// 0x9568 - 0x9590
				case (state_cycle)
					'd0: begin
						// 9568	adds	r1, #4
						rf[1]		<= rf[1] + 'd4;
						
						// 958c	adds	r3, #1
						rf[3]		<= rf[3] + 'd1;
						
						// 9588	ldr.w	r5, [sl]
						// The DLI loads r5 and overwritten by this insn
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[13];
						
						// 956e	ldr.w	r4, [r9, r1]
						// r9 is only used to load r4, and it's from
						// 9556	mov.w	r8, r3, lsl #2
						// 955c	add.w	r9, r1, r8
						// r8 is only used to calculate r9
						cache_r_addr[1]	<= rf[1] + (rf[3] << 2);
						
						// 9560	movs	r1, #0
						rf[1]			<= 'b0;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[5]		<= cache_data[0];
						rf[4]		<= cache_data[1];
						
						// DLI: 9576	ldr.w	r5, [r2, r4, lsl #2]
						// r5 was overwritten, disgard the content it loads
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[2] + cache_data[1];
						
						
						// 9582	ldr	r4, [r0, #16]
						// r4 is only needed in s4,
						// otherwise it will be overwritten
						cache_r_addr[1]	<= rf[1] + 'd16;
						
						// 958e	cmp	r3, r5
						// 9590	blt.n	9566 <sm_sv_mul+0x5e>
						if (rf[3] < cache_data[0]) begin
							state_cycle <= 'd0;
							state			<= 'd2;
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
			'd3: begin
				// 0x9538 - 0x9590 without 0x9568
				case (state_cycle)
					'd0: begin
						// 9538	adds	r7, r3, #1
						rf[7]			<= rf[3] + 'd1;
						
						// 9546	add.w	sl, fp, r7, lsl #2
						// Dependent on r7 but can calculate
						rf[13]		<= rf[11] + ((rf[3] + 'd1) << 2);
						
						// 953a	ldr.w	r3, [fp, r3, lsl #2]			
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[11] + rf[3] << 2;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						// 958c	adds	r3, #1
						rf[3]		<= cache_data[0] + 'd1;
						
						// 9588	ldr.w	r5, [sl]
						// The DLI loads r5 and overwritten by this insn
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[13];
						
						// 956e	ldr.w	r4, [r9, r1]
						// r9 is only used to load r4, and it's from
						// 9556	mov.w	r8, r3, lsl #2
						// 955c	add.w	r9, r1, r8
						// r8 is only used to calculate r9
						// r3 used here is the old r3, before 958c	adds	r3, #1
						cache_r_addr[1]	<= rf[1] + (cache_data[0] << 2);
						
						// 9560	movs	r1, #0
						rf[1]			<= 'b0;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[5]		<= cache_data[0];
						rf[4]		<= cache_data[1];
						
						
						// DLI: 9576	ldr.w	r5, [r2, r4, lsl #2]
						// r5 was overwritten, disgard the content it loads
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[2] + cache_data[1];
						
						
						// 9582	ldr	r4, [r0, #16]
						// r4 is only needed in s4,
						// otherwise it will be overwritten
						cache_r_addr[1]	<= rf[0] + 'd16;
						
						// 958e	cmp	r3, r5
						// 9590	blt.n	9566 <sm_sv_mul+0x5e>
						if (rf[3] < cache_data[0]) begin
							state_cycle <= 'd0;
							state			<= 'd2;
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
						// r4 is loaded in s1, and is needed in s4.
						rf[4]		<=	cache_data[1];
					
						// 9592	ldr	r3, [sp, #16]
						cache_data_req		<= 'b1;
						cache_r_addr[0]		<= rf[13] + 'd16;
						
						// ldr	r1, [sp, #4]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr[0]	<= rf[13] + 'd4;
						wren[0]				<= 1'b1;
						
						state_cycle <= 'd1;
					end
					'd1: begin
						rf[3]			<= cache_data[0];
						wren[0]		<= 1'b0;
						
						// 9598	adds	r1, #1
						rf[1]			<= strBuf_data[0] + 'd1;
						
						// 9594	ldr	r5, [r3, #8]
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= rf[3] + 'd8;
						
						state_cycle <= 'd2;
					end
					'd2: begin
						rf[5]			<= cache_data[0];
						
						// 959a	str	r1, [sp, #4]					
						w_addr[0]	<= rf[13] + 'd4;
						w_data[0]	<= rf[1];
						wren[0]		<= 1'b1;
						
						// 959c	cmp	r1, r5
						// 959e	bge.n	95c2 <sm_sv_mul+0xba>
						if (rf[1] >= cache_data[0]) begin
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
						wren[0]				<= 1'b0;
						
						// 95a0	ldr	r1, [sp, #8]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr[0]	<= rf[13] + 'd8;
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						rf[1]		<= strBuf_data[0];
						
						// 95a2	ldr.w	r3, [r1, #4]!
						cache_data_req		<= 'b1;
						cache_r_addr[0]	<= strBuf_data[0] + 'd4;
			
						// 95a8	str	r1, [sp, #8]
						w_addr[0]	<= rf[13] + 'd8;
						w_data[0]	<= strBuf_data[0];
						wren[0]		<= 1'b1;
						
						state_cycle	<= 'd2;
					end
					'd2: begin
						rf[3]			<= cache_data[0];
					
						// 95a6	cmp	r3, r4
						// 95b2	ble.n	9538 <sm_sv_mul+0x30>
						if (cache_data[0] <= rf[4]) begin
							state			<= 'd3;
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
						wren[0]				<= 1'b0;
						
						// 95c2	ldr	r3, [sp, #20]
						// Load from the store buffer
						strBuf_data_req	<= 'b1;
						strBuf_r_addr[0]	<= rf[13] + 'd20;
						
						state_cycle			<= 'd1;
					end
					'd1: begin
						// 95c4	subs	r3, #1
						rf[3]		<= strBuf_data[0] - 'd1;
						
						// 95c6	str	r3, [sp, #20]
						w_addr[0]		<= rf[13] + 'd20;
						w_data[0]		<= strBuf_data[0] - 'd1;
						wren[0]			<= 1'b1;
						
						// 95c8	bne.n	9516 <sm_sv_mul+0xe>
						// The Z flag is set by: 95c4	subs	r3, #1
						// NE: Z clear
						// Z flag: Set to 1 when the result of the operation is zero, cleared to 0 otherwise.
						if (strBuf_data[0] != 'd1) begin
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
