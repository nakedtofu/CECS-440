`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
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
   input [31:0] S, T;
   input [4:0] FS;
   output reg [31:0] Y_hi, Y_lo;
   output reg N, Z, V, C;
   
   reg neg, zero, ovf, carry;
   
   //cast S and T as integers for the SLT op
   integer inta, intb;
            
   //always @(S, T, FS)   //any change of the inputs(S, T or FS) 
   always @(*)
      begin      
         case(FS)
            5'h00: begin //PASS_S   (Y_lo = S)
                      Y_lo = S;
                      if (S[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (S     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end    
            5'h01: begin //PASS_T   (Y_lo = T)
                      Y_lo = T;
                      if (T[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (T     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end 
            5'h02: begin //ADD      (Y_lo = S + T)
                      {carry, Y_lo} = S + T;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};
                   end
            5'h03: begin //SUB      (Y_lo = S - T)
                      {carry, Y_lo} = S - T; 
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};                      
                   end
            5'h04: begin //ADDU     (Y_lo = S + T) unsigned
                      {carry, Y_lo} = S + T;      
                      if (Y_lo == 32'b0) zero = 1; else zero = 0;                    
                      ovf = carry;                     
                      {N, Z, V, C} = {1'b0, zero, ovf, carry};                      
                   end
            5'h05: begin //SUBU     (Y_lo = S - T) unsigned
                      Y_lo = S - T;
                      if (S < T)         neg  = 1;  else neg  = 0;
                      if (Y_lo == 32'b0) zero = 1;  else zero = 0;
                      if (T > S)         carry = 1; else carry = 0;
                      ovf = carry;                 
                      {N, Z, V, C} = {1'b0, zero, ovf, carry};                      
                   end
            5'h06: begin //SLT      (if S < T -> Y_lo = 1, else Y_lo = 0)
                      //S and T are casted as integers to compare 
                      //signed integers
                      inta = S;
                      intb = T;
                      if(inta < intb)  Y_lo = 32'd1;
                      else             Y_lo = 32'b0;                    
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end
            5'h07: begin //SLTU     (if S < T -> Y_lo = 1, else Y_lo = 0) unsigned
                      if(S < T)  Y_lo = 32'd1;
                      else       Y_lo = 32'b0;                      
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {1'b0, zero, 2'bxx};
                   end
            5'h08: begin //AND      (Y_lo = S & T)
                      Y_lo = S & T;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end    
            5'h09: begin //OR       (Y_lo = S | T)
                      Y_lo = S | T;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end    
            5'h0A: begin //XOR      (Y_lo = S ^ T)
                      Y_lo = S ^ T;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end    
            5'h0B: begin //NOR      (Y_lo = ~(S | T))
                      Y_lo = ~(S | T);
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end    
            5'h0C: begin //SLL      (Y_lo = T < 1) with 0 fill  
                      Y_lo = {T[30:0], 1'b0};
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 1'bx, T[31]};
                   end    
            5'h0D: begin //SRL      (Y_lo = T > 1) with 0 fill  
                      Y_lo = {1'b0, T[31:1]};
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 1'bx, T[0]};             
                   end
            5'h0E: begin //SRA(keeps MSB and shifts to the right)
                      Y_lo = {T[31], T[31:1]};
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 1'bx, T[0]};
                   end                     
            5'h0F: begin //INC      (Y_lo = S + 1)
                      {carry, Y_lo} = S + 1'b1;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};
                   end
            5'h10: begin //DEC      (Y_lo = S - 1)
                      Y_lo = S - 1'b1;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if (S == 32'b0)        carry = 1; else carry = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};
                   end
            5'h11: begin //INC4     (Y_lo = S + 4)
                      {carry, Y_lo} = S + 3'd4;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};
                   end
            5'h12: begin //DEC4     (Y_lo = S - 4)
                      Y_lo = S - 3'd4;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      if (S > 32'hFFFF_FFFB) carry = 1; else carry = 0;
                      if ( (S[31] == 1'b0) & (T[31] == 1'b0) & 
                           (Y_lo[31] == 1'b1) )
                        ovf = 1'b1;
                      else if ( (S[31] == 1'b1) & (T[31] == 1'b1) & 
                                (Y_lo[31] == 1'b0) )
                        ovf = 1'b1;
                      else
                        ovf = 1'b0;
                      {N, Z, V, C} = {neg, zero, ovf, carry};
                   end
            5'h13: begin //ZEROS    (Y_lo = 0)
                      Y_lo = 32'h0;
                      {N, Z, V, C} = 4'b01xx;                                   
                   end
            5'h14: begin //ONES     (Y_lo = FFFF_FFFF)
                      Y_lo = 32'hFFFF_FFFF;
                      {N, Z, V, C} = 4'b10xx;                                   
                   end
            5'h15: begin //SP_INIT  (Y_lo = 32'h3FC)
                      Y_lo = 32'h3FC;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end
            5'h16: begin //ANDI     (Y_lo = ( S & {16'h0, T[15:0]} ))
                      Y_lo = ( S & {16'h0, T[15:0]} );
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end
            5'h17: begin //ORI      (Y_lo = ( S | {16'h0, T[15:0]} ))
                      Y_lo = ( S | {16'h0, T[15:0]} );
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end
            5'h18: begin //LUI      (Y_lo = {T[15:0], 16'h0})
                      Y_lo = {T[15:0], 16'h0};
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end
            5'h19: begin //XORI     (Y_lo = ( S ^ {16'h0, T[15:0]} ))
                      Y_lo = ( S ^ {16'h0, T[15:0]} );
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                   end            
            default: begin //default set to the PASS_S function
                      Y_lo = S;
                      if (Y_lo[31] == 1'b1)  neg  = 1; else neg  = 0;
                      if (Y_lo     == 32'b0) zero = 1; else zero = 0;
                      {N, Z, V, C} = {neg, zero, 2'bxx};
                     end    
         endcase
         
         //since Y_hi is never used in MIPS, set it to 0
         Y_hi = 32'b0;       
      end
      
endmodule
