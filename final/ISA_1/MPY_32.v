`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MPY_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
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
module MPY_32(S, T, Y_hi, Y_lo, N, Z, V, C);
   input [31:0] S, T;
   output reg [31:0] Y_hi, Y_lo;
   output reg N, Z, V, C;
   
   //cast S and T into the following integers
   integer inta, intb;
   
   reg neg, zero;
   reg [63:0] mul;
   
   always @(*)  begin
      inta = S;
      intb = T;
      mul = inta * intb;
      {Y_hi, Y_lo} = mul;                             //Product
      if (mul[31] == 1'b1) neg  = 1;                  //Negative flag
      else                 neg  = 0;   
      if ( (S == 32'b0) & (T == 32'b0) )              //Zero flag
         zero = 1;
      else
         zero = 0;        
      {N, Z, V, C} = {neg, zero, 2'bxx};              //Set the output flags
   end
   
endmodule
