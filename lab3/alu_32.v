`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  alu_32.v
 * Project:    lab 3
 * Designer:   Naoaki Takatsu
 * Email:      naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  09/10/2018
 *
 * Purpose:    This module will instantiate three modules:
 *             MIPS_32, DIV_32, and MPY_32.
 *
 * Notes:      This is the Arithmetic Logic Unit module. It will act as a 
 *             wrapper instantiating MIPS_32, DIV_32, and MPY_32 modules.
 *             5 bit function select "FS" will select which wires to use for
 *             this module's outputs.
 *             
 ****************************************************************************/
 
module alu_32( FS, S, T, N, Z, V, C, Y_hi, Y_lo );

   input wire [4:0] FS;          // function select
	input wire [31:0] S, T;       // two 32 bit inputs
	output reg N, Z, V, C;        // negative, zero, overflow, carry flags
	output reg [31:0] Y_hi, Y_lo; // two 32 bit outputs
	
	wire Nt, Zt, Vt, Ct, Vd;      // temporary wires
	wire [31:0] Y_hi_t, Y_lo_t;
	wire [63:0] Ans_M, Ans_D;
	
   // instantiate MIPS, DIV, and MPY modules
   MIPS_32 MIPS( .FS(FS), .S(S), .T(T), .N(Nt), .Z(Zt), 
	              .V(Vt), .C(Ct), .Y_hi(Y_hi_t), .Y_lo(Y_lo_t) );
	DIV_32 DIV( .A(S), .B(T), .Vt(Vd), .Y(Ans_D) );
	MPY_32 MPY( .A(S), .B(T), .Y(Ans_M) );
	
	always @ ( * )
	begin
	
	   case (FS)

         // Multiply S by T
	      5'h1E:
	   	   begin
				
   		      {N,Z,V,C,Y_hi,Y_lo} = 
	   	         {
  		   		      ( Ans_M[63] ) ? 1'b1:1'b0,      // Negative
			   	      ( Ans_M == 64'h0 ) ? 1'b1:1'b0, // Zero
	   			      1'bx,                           // Overflow
		   		      1'bx,                           // Carry
   		   		   Ans_M[63:32],                   // Y_hi
	   		   	   Ans_M[31:0]                     // Y_lo				 
		   		   };
					 
	   	   end
			
         // Divide S by T
   	   5'h1F:
	   	   begin
				
		         {N,Z,V,C,Y_hi,Y_lo} = 
		            {
  				         ( Ans_D[31] ) ? 1'b1:1'b0,      // Negative
   				      ( Ans_D == 32'h0 ) ? 1'b1:1'b0, // Zero
	   			      Vd,                             // Overflow
   		   		   1'bx,                           // Carry
	   		   	   Ans_D[63:32],                   // Y_hi
		   		      Ans_D[31:0]                     // Y_lo				 
   		   		};
					 
	   	   end
			
   		default:
	   		begin
				
		         {N,Z,V,C,Y_hi,Y_lo} = 
		            {
  				         Nt,                             // Negative
   				      Zt,                             // Zero
	   			      Vt,                             // Overflow
   		   		   Ct,                             // Carry
	   		   	   Y_hi_t,                         // Y_hi
		   		      Y_lo_t                          // Y_lo				 
   		   		};
					 
	   	   end
			
   	endcase

   end

endmodule
