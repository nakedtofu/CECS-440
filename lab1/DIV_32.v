`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DIV_32.v
 * Project:    lab 1
 * Designer:   Naoaki Takatsu
 * Email:      naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  09/10/2018
 *
 * Purpose:    This module will take two 32 bit inputs and perform a divide.
 *             The result will be sent out as a 64 bit output.
 *
 * Notes:      This is the 32 bit division module. It will divide
 *             32 bit A and B inputs, then send the resulting 64 bit Y as its
 *             output. Y[63:32] will hold the remainder value while Y[31:0]
 *             will hold the quotient value. Prior to its division step, this
 *             module will change all negative inputs to positive values.
 *             After dividing, it will check the two inputs' sign bit and
 *             change the results to a negative quotient and remainder value
 *             depending on the inputs' (divisor and dividend's) sign bit.
 *             Overflow bit "Vt" will be set to 1 if the operation is a
 *             division by zero.
 *             
 ****************************************************************************/
 
module DIV_32( A, B, Vt, Y );

   input wire [31:0] A, B;                        // dividend and divisor
	output reg Vt;                                 // overflow flag
	output reg [63:0] Y;                           // remainder and quotient
		
	reg [31:0] At, Bt, Q, R;                       // temporary registers
	reg R_sign;
	
	always @ (*)
	begin

		Q  = 32'b0;                                 // initilize outputs to 0s
		R  = 32'b0;
		Vt = 1'b0;
		R_sign = 1'b0;
		
	   At = A;                                     // copy inputs to temp. reg 
		Bt = B;
	
	   if( A[31] )                                 // check if negative
		begin
		
		   At = ~A + 32'h1;                         // change to positive value
			R_sign = 1'b1;
			
		end
		
		if( B[31] )                                 // check if negative
		   Bt = ~B + 32'h1;                         // change to positive
	
	   if( B == 32'h0 )                            // check if division by 0
		begin
		
   		Y = 64'hFFFFFFFFFFFFFFFF;                // set error value
			Vt = 1'b1;                               // set overflow/error to 1

		end
		
		else
		begin
	
	      Q = At / Bt;                             // divide
		   R = At % Bt;                             // find remainder
			
			if( R_sign )                             // check if it was negative
			   R = ~R + 32'h1;                       // revert to negative
			
		   Y = {R, Q};                              // store data
		
		   // check if A and B have opposite signs
		   if( ( A[31] != B[31] ) && ( Bt <= At ) )
		      Y[31:0] = ~Y[31:0] + 32'h1;           // change to neg value

		end
	
	end
	
endmodule
