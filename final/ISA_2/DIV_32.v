`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DIV_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
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
module DIV_32(S, T, Y_hi, Y_lo, N, Z, V, C);
   input [31:0] S, T;
   output reg [31:0] Y_hi, Y_lo;
   output reg N, Z, V, C;
   
   reg neg, zero;
   reg [31:0] quot, rem;
   
   //cast S and T into the following integers
   integer inta;
   integer intb;
   
   always @(*) begin
      inta = S;
      intb = T;
      quot = inta / intb;
      rem  = inta % intb;

      {Y_hi, Y_lo} = {rem, quot};                        //Quotient
      if (quot[31] == 1'b1)   neg  = 1; else neg  = 0;   //Negative flag
      if (Y_lo     == 32'b0)  zero = 1; else zero = 0;   //Zero flag
      {N, Z, V, C} = {neg, zero, 2'bxx};                 //Set the output flags
   end
   
endmodule
