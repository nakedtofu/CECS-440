`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU_test3.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.3
 * Rev. Date:  11/8/2018
 *
 * Purpose:    This is the testbench that will instantiate and verify the
 *             correctness of the Central Processing Unit(CPU) with the Data
 *             Memory module and the InputOutput.v module.
 *
 * Notes:      This module will set an interrupt at 150ns in the middle of
 *             the Finite State Machine to test the validity of the 
 *             interrupt, and goes back to the original Program Counter
 *             before the interrupt occurs.
 *
 *             * This Project is for testing iMem 14 *
 * Revision Notes:
 *             1.2: (Revised from CPU_test1.v testbench module)
 *                  Added IO module for testing the Input and Output
 *                  instructions
 *             1.3: Changed to work for iMem 14
 * 
 ****************************************************************************/
module CPU_test3;

	// Inputs
	reg clk, reset;               //Clock and Reset
   reg intr;                     //Interrupt Request
   
	// Outputs
   wire int_ack;                 //Interrupt Acknowledge Flag
	wire [31:0] D_MemToInt;       //Data from DM to Datapath
   wire [31:0] D_IOToInt;        //Data from IO to Datapath
   wire [31:0] D_MemOrIO, Addr;  //Data Output from Datapath
   wire dm_cs, dm_wr, dm_rd;     //Data Memory flags
   wire io_cs, io_wr, io_rd;     //IO module flags
   
	// Instantiate the Unit Under Tests
   CPU            cpu(
                      .clk(clk),  .reset(reset),   //Clock and Reset
                      .intr(intr),                 //Interrupt Request
                      .int_ack(int_ack),           //Interrupt Acknowledge
                      .D_MemToInt(D_MemToInt),     //Data Input from Memory
                      .D_IOToInt(D_IOToInt),       //Data Input from IO
                      .Addr(Addr),                 //Data Address output of CPU
                      .D_OUT(D_MemOrIO),           //Data Output for Memory or IO
                      .dm_cs(dm_cs),               //  \
                      .dm_rd(dm_rd),               // --> Data Memory Flags
                      .dm_wr(dm_wr),               //  /
                      .io_cs(io_cs),               //  \
                      .io_rd(io_rd),               // --> I/O Module Flags
                      .io_wr(io_wr)                //  /
                     );
                     
   DataMemory  data_mem (
                      .clk(clk),                   //Clock
                      .Address( { 20'b0,           //Only takes first 12 bits
                                  Addr[11:0]}),    //of Address
                      .D_In(D_MemOrIO),            //Data Input from CPU
                      .D_Out(D_MemToInt),          //Data Output to CPU
                      .dm_cs(dm_cs),               //  \
                      .dm_rd(dm_rd),               // --> Data Memory Flags
                      .dm_wr(dm_wr)                //  /
                     );
                                                
   InputOutput in_out (
                      .clk(clk),                   //Clock
                      .Address( { 20'b0,           //Only takes first 12 bits
                                  Addr[11:0]}),    //of Address
                      .D_In(D_MemOrIO),            //Data Input from CPU
                      .D_Out(D_IOToInt),           //Data Output to CPU
                      .io_cs(io_cs),               //  \
                      .io_rd(io_rd),               // --> Data Memory Flags
                      .io_wr(io_wr),               //  /
                      .int_ack(int_ack)            //Interrupt Acknowledge
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
		$readmemh( "dMem_14.dat", data_mem.M );      //Test 14
      $readmemh( "iMem_14.dat", cpu.IU.IM.IMem ); 
//		$readmemh( "dMem_rotright.dat", data_mem.M );      //Enhanced Instruction
//      $readmemh( "iMem_rotright.dat", cpu.IU.IM.IMem ); 

      
		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
      
      //Set interrupt to 1 at 150ns 
      #300;
      intr = 1;
      
      @(posedge int_ack)
         intr = 0;
      
      $display(" "); $display(" ");
      $display("******************************************************************");
      $display("           CECS 440 - MIPS ISA Control Unit (Test for iMem 14)    ");
      $display("******************************************************************");
      $display(" ");  

	end //initial
      
endmodule
