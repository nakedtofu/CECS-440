`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DataMemory.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This is the 4098x8 bit readable/writable data memory module.
 *
 * Notes:      This module will be used to read and store memory data.
 *             To read or write data, chip select "dm_cs" must be set to 1.
 *             To read, "dm_rd" must be set to 1. To write, "dm_wr" must be
 *             set to 1. Data will be accessed through big endian format.
 *             
 ****************************************************************************/
module DataMemory(clk, Address, D_In, dm_cs, dm_wr, dm_rd, D_Out);

   input             clk, dm_cs, dm_wr, dm_rd;
   input      [31:0] Address, D_In;
	output     [31:0] D_Out;
   
   //use 1024x32 'big endian' MSB goes to smaller address
   reg [7:0] M [0:4095];  //4098x8 memory
   
   always @(posedge clk)   begin
      //write
      if(dm_cs && dm_wr)   begin
         M[Address]     <= D_In[31:24];
         M[Address + 1] <= D_In[23:16];
         M[Address + 2] <= D_In[15:8];
         M[Address + 3] <= D_In[7:0];
       end    
    end
    
   //asynchronous continuous output READ
   assign D_Out = (dm_cs && dm_rd) ? 
                  {M[Address], M[Address + 1], M[Address + 2], M[Address + 3]} :
                  32'hZZZZ_ZZZZ;   //high impedance


endmodule
