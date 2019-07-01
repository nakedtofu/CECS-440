`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Integer_Datapath.v
 * Project:    lab 4
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This top level module will instantiate two modules:
 *             regfile_32 and alu_32. This module contains two MUX and two
 *             32 bit register blocks for HI and LO.
 *
 * Notes:      This is the integer datapath module. It will connect the 32 bit 
 *             regfile module with the 32 bit alu module. Within the T-Mux, 
 *             T_Sel will be used to select T data from two choices: regfile T
 *             and immediate 32 bit value DT. Multiplication and Division 
 *             outputs will be stored in HI LO register blocks. Within the 
 *             Y-Mux, Y_Sel will select ALU_OUT from five choices: HI, LO, 
 *             Y_lo, 32 bit immediate DY, and 32 bit immediate PC_in. ALU_OUT
 *             will be stored in register specified by address D_Addr when
 *             D_En is enabled.
 *             
 ****************************************************************************/

module Integer_Datapath( clk, reset, S_Addr, T_Addr, D_Addr, D_En, DT, T_Sel, 
                         HILO_LD, FS, DY, PC_in, Y_Sel,
								 C, V, N, Z, ALU_OUT, D_OUT );

	input        clk, reset, D_En, T_Sel, HILO_LD;							
	input  [2:0] Y_Sel;
	input  [4:0] S_Addr, T_Addr, D_Addr, FS;
	input [31:0] DT, DY, PC_in;
	
	output            C, V, N, Z;
	output reg [31:0] ALU_OUT, D_OUT;
	
	wire [31:0] S, T, Y_hi, Y_lo;
	reg  [31:0] HI, LO, RS, RT, ALU_reg, D_in;

	regfile_32 regfile( .clk(clk), .reset(reset), .D(ALU_OUT), .D_En(D_En), 
	                    .D_Addr(D_Addr), .S_Addr(S_Addr), .T_Addr(T_Addr),
					        .S(S), .T(T) );	
					
	alu_32 alu( .FS(FS), .S(RS), .T(RT), .N(N), .Z(Z), .V(V), .C(C), 
	            .Y_hi(Y_hi), .Y_lo(Y_lo) );

	// T-Mux
	always @ (*)
	begin
	
	   if( T_Sel )
		   D_OUT = DT;
		else
		   D_OUT = T;
			
	end
	
	always @(posedge clk, posedge reset)
      if(reset)
         {RS, RT, HI, LO, ALU_reg, D_in, ALU_OUT, D_OUT} <= 256'h0;
			
      else  if (HILO_LD)
		begin
		
         { RS, RT } <= { S, D_OUT };
			{ HI,   LO,   ALU_reg, D_in } <= 
			{ Y_hi, Y_lo, Y_lo,    DY   };

       end
		 
		 else
		 begin
		 
		   { RS, RT } <= { S, D_OUT };
			{ HI, LO, ALU_reg, D_in } <= 
			{ HI, LO, Y_lo,    DY   };
		 
		 end

	// Y-Mux
	always @ (*)
	begin
	
	   case( Y_Sel )
		   3'b000  : ALU_OUT = ALU_reg; // pass SA
		   3'b001  : ALU_OUT = HI;      // pass SB
		   3'b010  : ALU_OUT = LO;      // pass SA
		   3'b011  : ALU_OUT = D_in;    // pass SB
   		3'b100  : ALU_OUT = PC_in;   // pass SB
	      default : ALU_OUT = 32'b0;   // pass 32 bits of 0s
		endcase
		 
   end

endmodule
