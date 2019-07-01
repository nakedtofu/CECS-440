`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  TopLevel6_tb.v
 * Project:    CECS 440 Lab 6: MIPS Control Unit
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/15/2018
 *
 * Purpose:    This is the testbench that will instantiate and verify the
 *             correctness of the MCU, Instruction Unit, Integer Datapath,
 *             and Data Memory modules.
 *
 * Notes:      This module will set an interrupt at 250ns in the middle of
 *             the Finite State Machine to test the validity of the 
 *             interrupt, and goes back to the original Program Counter
 *             before the interrupt occurs.
 * 
 ****************************************************************************/
 
module TopLevel_ISA1_tb;

	// Inputs
	reg         clk, reset;
   reg         intr;       //interrupt of the MCU
   
	// Outputs
	wire        N, Z, C, V;
	wire [31:0] D_IntToMem, D_MemToInt, Addr;
   
   wire [31:0] IR_out;
   wire [31:0] PC_IUtoID, SE_16;
   
   //new with MCU (control words of state machine)
   wire int_ack;
   wire [4:0] FS;                //5-bit control word
   wire [2:0] Y_Sel;             //3-bit control word
   wire [1:0] pc_sel, DA_sel;    //2-bit control words
   wire pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr, 
        D_En, T_sel, HILO_LD, dm_cs, dm_rd, dm_wr;   
   
	// Instantiate the Unit Under Tests
   Instruction_Unit IU  (
                         .clk(clk),         .reset(reset),   .PC_in(Addr), 
                         .pc_sel(pc_sel),   .pc_ld(pc_ld),   .pc_inc(pc_inc),
                         .PC_out(PC_IUtoID),
                         .im_cs(im_cs),     .im_wr(),        .im_rd(im_rd),
                         .ir_ld(ir_ld),     .IR_out(IR_out), .SE_16(SE_16)
                        );
                        
   Integer_Datapath IDP (
                         .clk(clk),         .reset(reset),   .D_En(D_En), 
	                      .D_Addr(IR_out[15:11]),   
                         .S_Addr(IR_out[25:21]), 
                         .T_Addr(IR_out[20:16]), 
								 .DT(SE_16),        .DA_sel(DA_sel),
								 .T_Sel(T_Sel),   
                         .FS(FS), 
                         .N(N), .Z(Z),      .C(C), .V(V), 
                         .HILO_LD(HILO_LD), .DY(D_MemToInt), 
								 .PC_in(PC_IUtoID), .Y_Sel(Y_Sel),   .ALU_OUT(Addr), 
								 .D_OUT(D_IntToMem)
                        ); 
                        
   DataMemory  data_mem (
                         .clk(clk),          .Address({20'b0, Addr[11:0]}), 
                         .D_In(D_IntToMem), 
                         .dm_cs(dm_cs),      .dm_wr(dm_wr),    .dm_rd(dm_rd), 
                         .D_Out(D_MemToInt)
                        );
                        
   MCU         mips_ctrl(
                         .sys_clk(clk), .reset(reset), 
                         .intr(intr), 
                         .c(C), .n(N), .z(Z), .v(V),  //ALU status inputs
                         .IR(IR_out),                 //Instruction Register input
                         .int_ack(int_ack),           //output to I/O subsystem
                         //rest of control word fields
                         .FS(FS),
                         .pc_sel(pc_sel),   .pc_ld(pc_ld),   .pc_inc(pc_inc),
                         .ir_ld(ir_ld),
                         .im_cs(im_cs),     .im_rd(im_rd),   .im_wr(im_wr), 
                         .D_En(D_En),       .DA_sel(DA_sel), .T_sel(T_Sel),
                         .HILO_ld(HILO_LD), .Y_sel(Y_Sel),  
                         .dm_cs(dm_cs),     .dm_rd(dm_rd),   .dm_wr(dm_wr)
                        );                   	
   	
	// Create a 10 ns clock
   always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
      clk = 0;
      reset = 1;
      intr = 0;
      
      $timeformat( -9, 1, " ps", 9 );  //Display time in nanoseconds
      
      // store .dat files into their respective memories
//		$readmemh( "dMem_1.dat", data_mem.M ); //Test 1
//      $readmemh( "iMem_1.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_2.dat", data_mem.M ); //Test 2
//      $readmemh( "iMem_2.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_3.dat", data_mem.M ); //Test 3
//      $readmemh( "iMem_3.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_4.dat", data_mem.M ); //Test 4
//      $readmemh( "iMem_4.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_5.dat", data_mem.M ); //Test 5
//      $readmemh( "iMem_5.dat", IU.IM.IMem ); 
		$readmemh( "dMem_6.dat", data_mem.M ); //Test 6
      $readmemh( "iMem_6.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_7.dat", data_mem.M ); //Test 7
//      $readmemh( "iMem_7.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_8.dat", data_mem.M ); //Test 8
//      $readmemh( "iMem_8.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_9.dat", data_mem.M ); //Test 9
//      $readmemh( "iMem_9.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_10.dat", data_mem.M );//Test 10
//      $readmemh( "iMem_10.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_11.dat", data_mem.M );//Test 11
//      $readmemh( "iMem_11.dat", IU.IM.IMem ); 
//		$readmemh( "dMem_12.dat", data_mem.M );//Test 12
//      $readmemh( "iMem_12.dat", IU.IM.IMem ); 
      
		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
      
//      //Set interrupt to 1 at 150ns 
//      #300;
//      intr = 1;
//      
//      @(posedge int_ack)
//         intr = 0;
      
      $display(" "); $display(" ");
      $display("******************************************************************");
      $display("           CECS 440 - MIPS ISA Control Unit (x Test)              ");
      $display("******************************************************************");
      $display(" ");  

	end //initial
      
endmodule
