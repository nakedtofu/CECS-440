`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU_test1.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  11/8/2018
 *
 * Purpose:    This is the testbench that will instantiate and verify the
 *             correctness of the Central Processing Unit(CPU) with the Data
 *             Memory module.
 *
 * Notes:      This module will set an interrupt at 300ns in the middle of
 *             the Finite State Machine to test the validity of the 
 *             interrupt, and goes back to the original Program Counter
 *             before the interrupt occurs.
 *
 *             * This Project is for testing iMem 1-12 *
 * 
 ****************************************************************************/
module CPU_test1;

	// Inputs
	reg clk, reset;               //Clock and Reset
   reg intr;                     //Interrupt Request
   
	// Outputs
   wire int_ack;                 //Interrupt Acknowledge Flag
	wire [31:0] D_CPUToMem, Addr; //Output of the CPU to the Data Memory
   wire [31:0] D_MemToCPU;       //Output of the Data Memory to the CPU
   wire dm_cs, dm_wr, dm_rd;     //Data Memory flags
   
	// Instantiate the Unit Under Tests
   CPU            cpu(
                      .clk(clk),  .reset(reset),   //Clock and Reset
                      .intr(intr),                 //Interrupt Request
                      .int_ack(int_ack),           //Interrupt Acknowledge
                      .D_MemToInt(D_MemToCPU),     //Data Input from Memory
                      .Addr(Addr),                 //Data Address output of CPU
                      .D_IntToMem(D_CPUToMem),     //Data Output for Memory
                      .dm_cs(dm_cs),               //  \
                      .dm_rd(dm_rd),               // --> Data Memory Flags
                      .dm_wr(dm_wr)                //  /
                     );
   DataMemory  data_mem (
                      .clk(clk),                   //Clock
                      .Address( { 20'b0,           //Only takes first 12 bits
                                  Addr[11:0]}),    //of Address
                      .D_In(D_CPUToMem),           //Data Input from CPU
                      .D_Out(D_MemToCPU),          //Data Output to CPU
                      .dm_cs(dm_cs),               //  \
                      .dm_rd(dm_rd),               // --> Data Memory Flags
                      .dm_wr(dm_wr)                //  /
                     );
                                                   	
	// Create a 10 ns clock
   always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
      clk = 0;
      reset = 1;
      intr = 0;
      
      $timeformat( -9, 1, " ps", 9 );  //Display time in nanoseconds
      
      // store .dat files into their respective memories (Data and Instruction)
		$readmemh( "dMem_1.dat", data_mem.M ); //Test 1
      $readmemh( "iMem_1.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_2.dat", data_mem.M ); //Test 2
//      $readmemh( "iMem_2.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_3.dat", data_mem.M ); //Test 3
//      $readmemh( "iMem_3.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_4.dat", data_mem.M ); //Test 4
//      $readmemh( "iMem_4.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_5.dat", data_mem.M ); //Test 5
//      $readmemh( "iMem_5.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_6.dat", data_mem.M ); //Test 6
//      $readmemh( "iMem_6.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_7.dat", data_mem.M ); //Test 7
//      $readmemh( "iMem_7.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_8.dat", data_mem.M ); //Test 8
//      $readmemh( "iMem_8.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_9.dat", data_mem.M ); //Test 9
//      $readmemh( "iMem_9.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_10.dat", data_mem.M );//Test 10
//      $readmemh( "iMem_10.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_11.dat", data_mem.M );//Test 11
//      $readmemh( "iMem_11.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_12.dat", data_mem.M );//Test 12
//      $readmemh( "iMem_12.dat", cpu.IU.IM.IMem ); 
      
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
      $display("       CECS 440 - MIPS ISA Control Unit (Test for iM 1-12)        ");
      $display("******************************************************************");
      $display(" ");  

	end //initial 
   
endmodule
