`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  InstructionMemory.v
 * Project:    CECS 440 Lab 5: Instruction Unit
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/9/2018
 *
 * Purpose:    This is the 4098x8 bit readable/writable instruction 
 *             memory module.
 *
 * Notes:      This module will have the memory that holds the Instruction 
 *             for the Datapath. To read or write the instruction, 
 *             chip select "im_cs" must be set to 1. To read, "im_rd" must be
 *             set to 1. To write, "im_wr" must be set to 1. Data will be 
 *             accessed through big endian format.
 *             
 ****************************************************************************/

module InstructionMemory(clk, Address, D_In, im_cs, im_wr, im_rd, D_Out);

   input         clk, im_cs, im_wr, im_rd;
   input  [31:0] Address, D_In;
   output [31:0] D_Out;
   
   //use 1024x32 'big endian' MSB goes to smaller address
   reg     [7:0] IMem [0:4095];  //4098x8 memory

   always @(posedge clk)   begin
      //write
      if(im_cs && im_wr)   begin
         IMem[Address]     <= D_In[31:24];
         IMem[Address + 1] <= D_In[23:16];
         IMem[Address + 2] <= D_In[15:8];
         IMem[Address + 3] <= D_In[7:0];
       end    
    end
    
   //asynchronous continuous output READ         
   assign D_Out = (im_cs && im_rd) ? 
                  {  IMem[Address], IMem[Address + 1],
                     IMem[Address + 2], IMem[Address + 3]} :
                  32'hZZZZ_ZZZZ;          //high impedance

endmodule
