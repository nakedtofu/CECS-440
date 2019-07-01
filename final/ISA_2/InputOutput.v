`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DataMemory.v
 * Project:    CECS 440 Lab 4: Integer Datapath_2
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This is the 4098x8 bit readable/writable I/O memory module.
 *
 * Notes:      This module will be used to read and store I/O data.
 *             To read or write data, chip select "io_cs" must be set to 1.
 *             To read, "io_rd" must be set to 1. To write, "io_wr" must be
 *             set to 1. Data will be accessed through big endian format.
 *             
 ****************************************************************************/

module InputOutput(clk, Address, D_In, io_cs, io_wr, io_rd, D_Out, int_ack, intr);

   input             clk, io_cs, io_wr, io_rd;
   input             int_ack;
   input      [31:0] Address, D_In;  
	output     [31:0] D_Out;
   output reg        intr;
   
   //use 1024x32 'big endian' MSB goes to smaller address
   reg [7:0] IO [0:4095];  //4098x8 memory
   
   always @(posedge clk)   begin
      //write
      if(io_cs && io_wr)   begin
         IO[Address]     <= D_In[31:24];
         IO[Address + 1] <= D_In[23:16];
         IO[Address + 2] <= D_In[15:8];
         IO[Address + 3] <= D_In[7:0];
       end
    end
    
   //asynchronous continuous output READ
   assign D_Out = (io_cs && io_rd) ? 
                  {IO[Address], IO[Address + 1], IO[Address + 2], IO[Address + 3]} :
                  32'hZZZZ_ZZZZ;   //high impedance
      
   //Deassert Interrupt when Interrupt is acknowledged by the CPU   
   always @(posedge int_ack)
      intr <= 1'b0;
      
endmodule
