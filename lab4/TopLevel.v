`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  TopLevel.v
 * Project:    lab 4
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This is the top level module.
 *
 * Notes:      This module will instantiate the integer datapath module and
 *             the data memory module.
 *             
 ****************************************************************************/

module TopLevel(clk, reset, D_En, D_Addr, S_Addr, T_Addr, 
                T_Sel, FS, HILO_LD, Y_Sel, PC_in, DT,
                dm_cs, dm_wr, dm_rd,
                N, Z, C, V);
                       
   input        clk, reset, D_En, T_Sel, HILO_LD, dm_cs, dm_wr, dm_rd;
   input  [2:0] Y_Sel;
	input  [4:0] D_Addr, S_Addr, T_Addr, FS;
	input [31:0] DT, PC_in;
   
	output       N, Z, C, V;
   
   wire [31:0] D_IntToMem, D_MemToInt, Mem_Addr;
   
   Integer_Datapath IDP( .clk(clk), .reset(reset), .D_En(D_En), 
	                      .D_Addr(D_Addr), .S_Addr(S_Addr), .T_Addr(T_Addr), 
								 .DT(DT), .T_Sel(T_Sel), .FS(FS), .N(N), .Z(Z), .C(C), 
								 .V(V), .HILO_LD(HILO_LD), .DY(D_MemToInt), 
								 .PC_in(PC_in), .Y_Sel(Y_Sel), .ALU_OUT(Mem_Addr), 
								 .D_OUT(D_IntToMem) );
                           
   DataMemory data_mem( .clk(clk), .Address({20'b0,Mem_Addr[11:0]}), .D_In(D_IntToMem), 
                        .dm_cs(dm_cs), .dm_wr(dm_wr), .dm_rd(dm_rd), 
                        .D_Out(D_MemToInt) );

endmodule
