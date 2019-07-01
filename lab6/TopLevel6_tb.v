`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  TopLevel6_tb.v
 * Project:    CECS 440 Lab 5: Instruction Unit
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/11/2018
 *
 * Purpose:    This is the testbench that will instantiate and verify the
 *             correctness of the Instruction Unit, Integer Datapath,
 *             and Data Memory modules.
 *
 * Notes:      This module will test for the following cases:
 *             Logical OR, Subtraction, Logical Shift Right, 
 *             Logical Shift Left, Division, Multiplication using DT,
 *             Load Word, 1's Complement, 2's Complement,
 *             Addition, and Store Word.
 *             
 ****************************************************************************/
 
module TopLevel6_tb;

	// Inputs
	reg         clk, reset, intr;
	wire        D_En, T_Sel, HILO_LD, dm_cs, dm_wr, dm_rd, pc_ld, 
	            pc_inc, im_cs, im_rd, im_wr, ir_ld, N, Z, C, V, int_ack;
	wire  [1:0] DA_sel, pc_sel;
	wire  [4:0] FS;
   wire  [2:0] Y_sel;     
	wire [31:0] D_IntToMem, D_MemToInt, Addr, IR, PC_IUtoID, SE_16;
	
	integer i;

	// Instantiate the Unit Under Tests
	MCU              mcu (
	                      .sys_clk(clk), .reset(reset), .intr(intr), 
	                      .c(C), .n(N), .z(Z), .v(V), .IR(IR), 
								 .int_ack(int_ack), .FS(FS), .pc_sel(pc_sel), 
								 .pc_ld(pc_ld), .pc_inc(pc_inc), .ir_ld(ir_ld), 
								 .im_cs(im_cs), .im_rd(im_rd), .im_wr(im_wr), 
								 .D_En(D_En), .DA_sel(DA_sel), .T_sel(T_Sel), 
								 .HILO_ld(HILO_LD), .Y_sel(Y_sel), .dm_cs(dm_cs), 
								 .dm_rd(dm_rd), .dm_wr(dm_wr)
								);
								
   Instruction_Unit IU  (
                         .clk(clk),          .reset(reset),   .PC_in(Addr), 
								 .pc_sel(pc_sel),    .pc_ld(pc_ld),   .pc_inc(pc_inc), 
								 .PC_out(PC_IUtoID), .im_cs(im_cs),   .im_wr(im_wr),
								 .im_rd(im_rd),      .ir_ld(ir_ld),   .IR_out(IR), 
								 .SE_16(SE_16)
                        );
								
   Integer_Datapath IDP (
                         .clk(clk),          .reset(reset),      .D_En(D_En), 
	                      .D_Addr(IR[15:11]), .S_Addr(IR[25:21]), 
								 .T_Addr(IR[20:16]), .DT(SE_16),        
								 .DA_sel(DA_sel),    .T_Sel(T_Sel),      .FS(FS), 
                         .N(N), .Z(Z),       .C(C), .V(V), 
                         .HILO_LD(HILO_LD), .DY(D_MemToInt), 
								 .PC_in(PC_IUtoID), .Y_Sel(Y_sel),   .ALU_OUT(Addr), 
								 .D_OUT(D_IntToMem)
                        );
                           
   DataMemory  data_mem (
                         .clk(clk),          .Address(Addr[31:0]), 
                         .D_In(D_IntToMem), 
                         .dm_cs(dm_cs),      .dm_wr(dm_wr),    .dm_rd(dm_rd), 
                         .D_Out(D_MemToInt)
                        );

   // Register Dump Task
   task Reg_Dump;
      //Output register values
      for( i = 0; i < 16; i = i + 1 )
         $display( "t=%t, $r%0h = 0x%h",
                   $time, i, IDP.regfile.regs[i]);
   endtask
	
	// Create a 10 ns clock
   always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
		//Clock, Reset, Interrupt
		{clk, reset, intr} = 3'b0_1_0;

      // store .dat files into ther respective files
		$readmemh( "./dMem_Lab6.dat", data_mem.M );
      $readmemh( "./iMem_Lab6.dat", IU.IM.IMem );		
      $timeformat( -9, 1, " ps", 9 );    //Display time in nanoseconds
      
		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
      
      $display(" "); $display(" ");
      $display("******************************************************************");
      $display("           CECS 440 - Lab 6  Instruction Unit                     ");
      $display("******************************************************************");
      $display(" ");  
		
		/*
		//interrupt find #value
		#400 intr = 1'b1;
		@(posedge int_ack)
		intr = 1'b0;
		//wait until finished
		*/
		
		@(mcu.state == 510)
		
		// Read updated regfile data
		$display("");
		$display("******Contents of updated registers******");
		Reg_Dump();
		
		// Read updated memory data
		$display("");
		$display("******Content of Memory Address FF8******");
      /*@(negedge clk)
         $display( "t=%t, $M[%h] = 0x%h%h%h%h",
                       $time, 12'hFF8, data_mem.M[ 12'hFF8 ]
                       ,data_mem.M[ 12'hFF8 + 1 ]
                       ,data_mem.M[ 12'hFF8 + 2 ]
                       ,data_mem.M[ 12'hFF8 + 3 ]);
*/
	end //initial
      
endmodule
