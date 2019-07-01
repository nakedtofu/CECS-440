`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  regfile_32.v
 * Project:    lab 3
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This is the 32 bit register file module.
 *
 * Notes:      This 32 bit register file module will store 32 registers of 
 *             size 32 bit. D is the incoming 32 bit data. S and T are 32 bit
 *             data outputs of the module. D_Addr, S_Addr, and T_Addr 
 *             will address which register to select respectively for D, S,
 *             and T. D_En will act as a write enable. S and T are 
 *             asynchronous outputs while D will be a synchronous input.
 *             
 ****************************************************************************/
 
module regfile_32(clk, reset, D, D_En, D_Addr, S_Addr, T_Addr, S, T);

   input clk, reset, D_En;
	input [4:0] S_Addr, D_Addr, T_Addr;
	input [31:0] D;
	
	output reg [31:0] S, T;
	
	reg [31:0] regs [31:0];
	
	always @ (*)
	begin
	
	   S <= regs[S_Addr];
	   T <= regs[T_Addr];

	end
	
	always @ ( posedge clk, posedge reset )
	begin
	
	   if ( reset == 1'b1 )
			regs[0] <= 32'h0;
		
		else if ( D_En && ( D_Addr != 5'h0 ) )
		   regs[D_Addr] <= D;
			
		else
		   regs[D_Addr] <= regs[D_Addr];
	
	end

endmodule
