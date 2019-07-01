`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_32.v
 * Project:    lab 1
 * Designer:   Naoaki Takatsu
 * Email:      naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  09/10/2018
 *
 * Purpose:    This module will perform the following operations for each of
 *             its corresponding 5 bit function select hex value:
 *
 *                0 - Pass_S   7 - SLTU   E  - SRA     15 - SP_INIT
 *                1 - Pass_T   8 - AND    F  - INC     16 - ANDI
 *                2 - ADD      9 - OR     10 - DEC     17 - ORI
 *                3 - SUB      A - XOR    11 - INC4    18 - LUI
 *                4 - ADDU     B - NOR    12 - DEC4    19 - XORI
 *                5 - SUBU     C - SLL    13 - ZEROS   default - all x's
 *                6 - SLT      D - SRL    14 - ONES    
 *
 *             This module will detect if the result: is a negative value,
 *             is a zero, has overflow, or has carry. The results of the
 *             operation will be sent out as outputs.
 *
 * Notes:      This is the 32 bit MIPS operation module. It will take a 5 bit
 *             function selet input "FS" to determine which operation it
 *					should execute. I will also take two 32 bit values for its
 *             input. Flags 'N', 'Z', 'V', and 'C' (negative, zero, overflow,
 *             and carry) will be outputted along with the resulting two 
 *             32 bit values "Y_hi" and "Y_lo".
 *             
 ****************************************************************************/
 
module MIPS_32( FS, S, T, N, Z, V, C, Y_hi, Y_lo );

   input wire [4:0] FS;          // function select
	input wire [31:0] S, T;       // two 32 bit inputs
	output reg N, Z, V, C;        // negative, zero, overflow, carry
	output reg [31:0] Y_hi, Y_lo; // two 32 bit outputs
	
	reg [31:0] Ans, Flag;         // temporary registers
	reg Ct, Vt;
	
	always @( * ) 
	begin
	
	N = 1'bx;                     // initialize outputs to x's and 0's
	Z = 1'bx;
	V = 1'bx;
	C = 1'bx;
	Y_hi = 32'h0;
	Y_lo = 32'h0;
	
		case ( FS )
		
		   // Pass S
		   5'h00:
			begin
			
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( S[31] ) ? 1'b1:1'b0,          // Negative
					   ( S     == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'b0,                         // Overflow
					     1'b0,                         // Carry
					     32'h0,                        // Y_hi
					     S                             // Y_lo			 
					};
					
			end
					
			// Pass T
			5'h01:
			begin
			
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( T[31] ) ? 1'b1:1'b0,          // Negative
					   ( T     == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'b0,                         // Overflow
					     1'b0,                         // Carry
					     32'h0,                        // Y_hi
					     T                             // Y_lo				 
					};

			end

			
			// Add S and T
			5'h02:
			begin
			
			   {Ct, Ans} = S + T; // add
				
				// check for overflow
				if( ( S[31] == T[31] ) && ( Ans[31] != S[31] ) )
				   Vt = 1'b1;
				else
				   Vt = 1'b0;
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( Ans[31] ) ? 1'b1:1'b0,          // Negative
					   ( Ans     == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                             // Overflow
					     Ct,                             // Carry
					     32'h0,                          // Y_hi
					     Ans                             // Y_lo				 
					};
						 
			end
			
			// Sub S and T
			5'h03:
			begin
			
			   {Ct, Ans} = S - T; // sub
				
				// check for overflow
				if( ( S[31] != T[31] ) && ( Ans[31] == T[31] ) )
				   Vt = 1'b1;
				else
				   Vt = 1'b0;
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( Ans[31] ) ? 1'b1:1'b0,          // Negative
					   ( Ans     == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                             // Overflow
					     Ct,                             // Carry
					     32'h0,                          // Y_hi
					     Ans[31:0]                       // Y_lo				 
					};
						 
			end
			
			// Unsign add S and T
			5'h04:
			begin
			
			   {Ct, Ans} = S + T; // uadd
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					  1'b0,                           // Negative
					   ( Ans     == 32'h0 ) ? 1'b1:1'b0, // Zero
					   ( Ct ) ? 1'b1:1'b0,               // Overflow
					     Ct,                             // Carry
					     32'h0,                          // Y_hi
					     Ans                             // Y_lo				 
					};
						 
			end
			
			// Unsign sub S and T
			5'h05:
			begin
			
			   {Ct, Ans} = S - T; // usub
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					  1'b0,                           // Negative
					   ( Ans     == 32'h0 ) ? 1'b1:1'b0, // Zero
					   ( Ct ) ? 1'b1:1'b0,               // Overflow
					   ( Ct ) ? 1'b1:1'b0,               // Carry
					     32'h0,                          // Y_hi
					     Ans                             // Y_lo				 
					};
						 
			end
			
			// S less than T
			5'h06:
			begin
			
				if (  
				
				      
					   ( 
						
						// neg < pos unless both 0s
						( ( S[31] == 1'b1 ) && ( T[31] == 1'b0 ) && 
				      ! ( ( S[30:0] == T[30:0] ) && ( S[30:0] == 31'h0 ) ) )
					
					   || // or
					
					   // check value when both signs are equal
   				   ( ( S[31] == T[31] ) && ( S[30:0] < T[30:0] ) ) 
						
						)
					
					) // end if
					
					Flag = 32'h1;
					
				else
				   Flag = 32'h0; // else false
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					1'b0,                   // Negative
					   ~Flag[0],               // Zero
					   1'bx,                   // Overflow
					   1'bx,                   // Carry
					   32'h0,                  // Y_hi
					   Flag                    // Y_lo		
					};
						 
			end
			
			// S unsigned less than T
			5'h07:
			begin
			
			   Flag = ( S < T ) ? 32'h1:32'h0;
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					1'b0,                   // Negative
					   ~Flag[0],               // Zero
					   1'bx,                   // Overflow
					   1'bx,                   // Carry
					   32'h0,                  // Y_hi
					   Flag                    // Y_lo				 
					};
					
			end
					
			// S AND with T
			5'h08:
			begin
			
			   Ans = S & T; // and
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     1'bx,                       // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// S OR with T
			5'h09:
			begin
			
			   Ans = S | T; // or
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     1'bx,                       // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// S XOR with T
			5'h0A:
			begin
			
			   Ans = S ^ T; // xor
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     1'bx,                       // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// S NOR with T
			5'h0B:
			begin
			
			   Ans = ~ ( S | T ); // nor
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   					( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     1'bx,                       // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Logical shift left T
			5'h0C:
			begin
			
			   Ct = T[31];                         // carry
			   Ans = T << 1;                       // sll
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Logical shift right T
			5'h0D:
			begin
			
			   Ct = T[0];                          // carry
			   Ans = T >> 1;                       // srl
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Arithmatic Shift right T
			5'h0E:
			begin
			
			   Ct = T[0];                       // carry
			   Ans = { T[31], T[31], T[30:1] }; // sra
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     1'bx,                       // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Increment S by 1
			5'h0F:
			begin
			
			   {Ct, Ans} = S + 1'b1; // inc
				Vt = ( S[31] != Ans[31] ) ? 1'b1:1'b0; // check if overflow
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                         // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Decrement S by 1
			5'h10:
			begin
			
			   {Ct, Ans} = S - 1'b1; // dec
				Vt = ( S[31] != Ans[31] ) ? 1'b1:1'b0; // check if overflow
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                         // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Increment S by 4
			5'h11:
			begin
			
			   {Ct, Ans} = S + 3'h4; // inc 4
				Vt = ( S[31] != Ans[31] ) ? 1'b1:1'b0; // check if overflow
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                         // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Decrement S by 4
			5'h12:
			begin
			
			   {Ct, Ans} = S - 3'h4; // dec 4
				Vt = ( S[31] != Ans[31] ) ? 1'b1:1'b0; // check if overflow
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					     Vt,                         // Overflow
					     Ct,                         // Carry
					     32'h0,                      // Y_hi
					     Ans                         // Y_lo				 
					};
						 
			end
			
			// Zero/clear S
			5'h13:
			begin
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   1'b0,                         // Negative
					   1'b1,                         // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   32'h0                         // Y_lo				 
					};
						 
			end
			
			// One/fill S
			5'h14:
			begin
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   1'b1,                         // Negative
					   1'b0,                         // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   32'hffffffff                  // Y_lo				 
					};
						 
			end
			
			// set Y_lo (stack pointer) to 32'h3FC
			5'h15:
			begin
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   1'b0,                         // Negative
					   1'b0,                         // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   32'h3FC                       // Y_lo				 
					};
						 
			end
			
			// AND immediate
			5'h16:
			begin
			
			   Ans = S & { 16'h0, T[15:0] };       // ANDI
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   Ans                           // Y_lo				 
					};
						 
			end
			
			// OR immediate
			5'h17:
			begin
			
			   Ans = S | { 16'h0, T[15:0] };       // ORI
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   Ans                           // Y_lo				 
					};
						 
			end
			
			// Load upper immediate
			5'h18:
			begin
			
			   Ans = { T[15:0], 16'h0 };           // LUI
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   Ans                           // Y_lo				 
					};
						 
			end
			
			// XOR immediate
			5'h19:
			begin
			
			   Ans = S ^ { 16'h0, T[15:0] };       // XORI
					
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   ( Ans[31] ) ? 1'b1:1'b0,      // Negative
					   ( Ans == 32'h0 ) ? 1'b1:1'b0, // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'h0,                        // Y_hi
					   Ans                           // Y_lo				 
					};
						 
			end
			
			default:
			begin
			
			   {N,Z,V,C,Y_hi,Y_lo} = 
			      {
   				   1'bx,                         // Negative
					   1'bx,                         // Zero
					   1'bx,                         // Overflow
					   1'bx,                         // Carry
					   32'hxxxxxxxx,                 // Y_hi
					   32'hxxxxxxxx                  // Y_lo				 
					};
					
			end
	
		endcase
			
	end   


endmodule
