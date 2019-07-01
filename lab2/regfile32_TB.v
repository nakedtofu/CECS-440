`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  regfile32_TB.v
 * Project:    lab 2
 * Designer:   Naoaki Takatsu
 * Email:      naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  09/20/2018
 *
 * Purpose:    This is the testbench for regfile_32 module.
 *
 * Notes:      This module will first initialize the 32 registers by executing 
 *             a memory read from the IntReg_Lab2.dat file. It will then 
 *             output the initial contents. Next, we will overwrite the 
 *             registers by the following formula, 
 *             D = ( (~i) << 8 ) + ( -65536 * i ) + i
 *             Lastly, we will display the updated register contents.
 *             
 ****************************************************************************/

module regfile32_TB;

	// Inputs
	reg clk;
	reg reset;
	reg [31:0] D;
	reg D_En;
	reg [4:0] D_Addr;
	reg [4:0] S_Addr;
	reg [4:0] T_Addr;

	// Outputs
	wire [31:0] S;
	wire [31:0] T;
	
	integer i;

	// Instantiate the Unit Under Test (UUT)
	regfile_32 uut (
		.clk(clk), 
		.reset(reset), 
		.D(D), 
		.D_En(D_En), 
		.D_Addr(D_Addr), 
		.S_Addr(S_Addr), 
		.T_Addr(T_Addr), 
		.S(S), 
		.T(T)
	);


   // Create a 10 ns clock
   always
   #5 clk = ~clk;

	// Add stimulus here

   initial
	begin

		clk = 0;
		reset = 1;
		D = 0;
		D_En = 0;
		D_Addr = 0;
		S_Addr = 0;
		T_Addr = 0;
		$readmemh( "./IntReg_Lab2.dat",uut.regs );
		$timeformat( -9, 1, " ps", 9 );    //Display time in nanoseconds
		
		// Wait 100 ns for global reset to finish
		#100;
		
		reset = 0;
		
		#1 $display("******Contents of initialized registers******");
		
		//Read initial data through S and T
		for( i = 0; i < 16; i = i + 1 )
		begin
		
		   S_Addr = i;
			T_Addr = i+16;
		   #1 $display( "t=%t, S_Addr=0x%h, S=0x%h, T_Addr=0x%h, T=0x%h",
			             $time, S_Addr, S, T_Addr, T );
		
		end
		
		#1 $display("******Updating registers******");
		
		//enable writing
		D_En = 1;
		
		//Write data though D

		for( i = 1; i < 32; i = i + 1 )
		begin

   		   D_Addr = i;
			   D = ( (~i) << 8 ) + ( -65536 * i ) + i;
				#10 $display( "t=%t, D_En=0x%h, D_Addr=0x%h, D=0x%h, regs[%d]=0x%h",
               		     $time, D_En, D_Addr, D, i, uut.regs[i] );

		end

		//disable writing
		D_En = 0;
		
		#1 $display("******Contents of updated registers******");
		
		//Read modified data through S and T
		for( i = 0; i < 16; i = i + 1 )
		begin
		
		   S_Addr = i;
			T_Addr = i+16;
		   #1 $display( "t=%t, S_Addr=0x%h, S=0x%h, T_Addr=0x%h, T=0x%h", 
			             $time, S_Addr, S, T_Addr, T );
		
		end

	end
      
endmodule

