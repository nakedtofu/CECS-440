`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MPY_32.v
 * Project:    lab 4
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This module will take two 32 bit inputs and perform a mutlipy.
 *             The result will be sent out as a 64 bit output.
 *
 * Notes:      This is the 32 bit multiplication module. It will multiply
 *             32 bit A and B inputs, then send the resulting 64 bit Y as its
 *             output. Prior to its multiplication step, this module will 
 *             change all negative inputs to positive values. After 
 *             multiplying, it will check the two inputs' sign bit and change
 *             the result to a negative value if both sign bits are not equal
 *             to each other.
 *             
 ****************************************************************************/

module MPY_32_2( A, B, Y );

   input wire [31:0] A, B; // two 32 bit inputs
	output reg [63:0] Y;    // one 64 bit output
	
	reg [31:0] At, Bt;      // temporary registers

	always @ (*)
	begin
	
	   Y = 64'h0;           // initialize registers to 0s
		
	   At = A;              // copy inputs to temp. registers 
		Bt = B;
	
	   if( A[31] )          // check if negative
		   At = ~A + 32'h1;  // change to positive
		
		if( B[31] )          // check if negative
		   Bt = ~B + 32'h1;  // change to positive
	
	   Y = At * Bt;         // multiply
		
		if( A[31] != B[31] ) // check if A and B have opposite signs
		   Y = ~Y + 64'h1;   // change to negative value
	
	end

endmodule
