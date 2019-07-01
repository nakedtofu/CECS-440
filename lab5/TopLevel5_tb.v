`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  TopLevel5_tb.v
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
 
module TopLevel5_tb;

	// Inputs
	reg         clk, reset, D_En, DA_sel, T_Sel, HILO_LD, dm_cs, dm_wr, dm_rd;
   reg   [2:0] Y_Sel;
   reg         pc_ld, pc_inc, im_cs, im_rd, im_wr;   //im_wr deasserted
   reg         ir_ld;
   
	// Outputs
	wire        N, Z, C, V;
	wire [31:0] D_IntToMem, D_MemToInt, Addr;
   
   //IR_out used bits 31-27, 25-11 (20 bits) 
   //       not using 26, 10-0     (12 bits)
   wire [31:0] IR_out;
   wire [31:0] PC_IUtoID, SE_16;
	
	integer i;

	// Instantiate the Unit Under Tests
   Instruction_Unit IU  (
                         .clk(clk),         .reset(reset),   .PC_in(Addr), 
                         .pc_ld(pc_ld),     .pc_inc(pc_inc), .PC_out(PC_IUtoID),
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
                         .FS(IR_out[31:27]), 
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
	

   // Register Dump Task
   task Reg_Dump;
      //Output register values
      for( i = 0; i < 16; i = i + 1 )
       begin
         @(negedge clk)
          begin
            {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
            {dm_cs, dm_rd, dm_wr}                        = 3'b0_0_0;
            {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr}  = 6'b0_0_0_0_0_0;        
            @(negedge clk)
               $display( "t=%t, $r%0h = 0x%h",
                          $time, i, IDP.regfile.regs[i]);
          end
       end
   endtask
	
	// Create a 10 ns clock
   always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
		
		//Clock and Reset
		{clk, reset} = 2'b0_1;
		// Instruction Unit Control
		{pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		// Datapath Control
      {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
		//Data Memory Control
      {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0; 

      // store .dat files into ther respective files
		$readmemh( "./IntReg_Lab5.dat", IDP.regfile.regs );
		$readmemh( "./dMem_Lab5.dat", data_mem.M );
      $readmemb( "./iMem_Lab5.dat", IU.IM.IMem );		
      $timeformat( -9, 1, " ps", 9 );    //Display time in nanoseconds
      
		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
      
      $display(" "); $display(" ");
      $display("******************************************************************");
      $display("           CECS 440 - Lab 5  Instruction Unit                     ");
      $display("******************************************************************");
      $display(" ");  

      // Read initialized regfile data through ALU_OUT
		$display("******Contents of initialized registers******");		
		Reg_Dump();


      //***************MICRO-OPERATIONS***************
      
      // 1 - instruction being read from InstructionMemory into the IR
      // 2 - 3 or more subsequent microops to obtain the operands,
      //     execute the operation and finally return the results
      
      // a.) $r1 <- $r3 | $r4       (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
		   // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;  
       end         
         
      //     $r1 <- $r3 | $r4       (4 uOP)  2
      //       RS <- $r3, RT <- $r4
      @(negedge clk)
       begin
		   // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;         
       end  

      //     $r1 <- $r3 | $r4       (4 uOP)  3
      //       ALU_Out <- RS(r3) | RT(r4)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r1 <- $r3 | $r4       (4 uOP)  4
      //       $r1 <- ALU_Out(r3 | r4)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  
       
      // b.) $r2 <- $r1 - $r14      (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  

      //     $r2 <- $r1 - $r14      (4 uOP)  2
      //       RS <- $r1, RT <- $r14
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  
       
      //     $r2 <- $r1 - $r14      (4 uOP)  3
      //       ALU_Out <- RS(r1) - RT(r14)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  
      
      //     $r2 <- $r1 - $r14      (4 uOP)  4
      //       $r2 <- ALU_Out(r1 - r14)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      // c.) $r3 <- SHR $r4         (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     $r3 <- SHR $r4         (4 uOP)  2
      //       RT <- $r4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  

      //     $r3 <- SHR $r4         (4 uOP)  3    
      //       ALU_Out <- RT(r4) >> 1
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     $r3 <- SHR $r4         (4 uOP)  4      
      //       $r3 <- ALU_Out(r4 >> 1)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // d.) $r4 <- SHL $r5         (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     $r4 <- SHL $r5         (4 uOP)  2
      //       RT <- $r5
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end  

      //     $r4 <- SHL $r5         (4 uOP)  3
      //       ALU_Out <- RT(r5) << 1
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     $r4 <- SHL $r5         (4 uOP)  4
      //       $r4 <- ALU_Out(r5 << 1)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // e.) {r6, r5} = $r15/$r14   (7 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r6, r5} = $r15/$r14   (7 uOP)  2
      //       RS <- $r15, RT <- $r14
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r6, r5} = $r15/$r14   (7 uOP)  3
      //       HILO <- RS(r15) / RT(r14)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_1_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r6, r5} = $r15/$r14   (7 uOP)  4
      //       IR <- iM[PC], PC <- PC + 4    - gets $rd for $r6
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     {r6, r5} = $r15/$r14   (7 uOP)  5
      //       $r6 <- HI
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_001;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r6, r5} = $r15/$r14   (7 uOP)  6
      //       IR <- iM[PC], PC <- PC + 4    - gets $rd for $r5
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r6, r5} = $r15/$r14   (7 uOP)  7
      //       $r5 <- LO
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_010;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // f.) {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  2
      //       RS <- $r11, RT <- DT(SE_16)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}        = 7'b0_0_1_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  3
      //       HILO <- RS(r11) / RT(0xFFFF_FFFB)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_1_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  4
      //       IR <- iM[PC], PC <- PC + 4    - gets $rd for $r8
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  5
      //       $r8 <- HI
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_001;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  6
      //       IR <- iM[PC], PC <- PC + 4    - gets $rd for $r7
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     {r8, r7} = $r11 * 0xFFFF_FFFB   (7 uOP)  7
      //       $r7 <- LO
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_010;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // g.) $r12 = M[$r15 + 0]     (5 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r12 = M[$r15 + 0]     (5 uOP)  2
      //       RS <- R15(r15), RT <- DT(0)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_1_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end

      //     $r12 = M[$r15 + 0]     (5 uOP)  3
      //       ALU_Out <- RS(r15) + RT(0)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r12 = M[$r15 + 0]     (5 uOP)  4
      //       D_in <- M[$r15 + 0]
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b1_1_0;
       end
              
      //     $r12 = M[$r15 + 0]     (5 uOP)  5
      //       $r12 <- D_in(M[r15 + 0])
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_1_0_0_011;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // h.) $r11 = $r0 NOR $r11    (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r11 = $r0 NOR $r11    (4 uOP)  2
      //       RS <- R0(r0), RT <- R11(r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r11 = $r0 NOR $r11    (4 uOP)  3
      //       ALU_Out <- RS(r0) NOR RT(r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r11 = $r0 NOR $r11    (4 uOP)  4
      //       $r11 <- ALU_Out(r0 NOR r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // i.) $r10 = $r0 - $r10    (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r10 = $r0 - $r10    (4 uOP)  2
      //       RS <- R0(r0), RT <- R10(r10)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r10 = $r0 - $r10    (4 uOP)  3
      //       ALU_Out <- RS(r0) - RT(r10)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r10 = $r0 - $r10    (4 uOP)  4
      //       $r10 <- ALU_Out(r0 - r10)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end       
       
      // j.) $r9 = $r10 + $r11    (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r9 = $r10 + $r11    (4 uOP)  2
      //       RS <- R10(r10), RT <- R11(r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r9 = $r10 + $r11    (4 uOP)  3
      //       ALU_Out <- RS(r10) + RT(r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      //     $r9 = $r10 + $r11    (4 uOP)  4
      //       $r9 <- ALU_Out(r10 + r11)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b1_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
      // k.) M[$r14 + 0] = $r12  (4 uOP)  1
      //       IR <- iM[PC], PC <- PC + 4
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
       //    M[$r14 + 0] = $r12  (4 uOP)  2
       //       RS <- R14(r14), RT <- DT(0)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_1_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
       //    M[$r14 + 0] = $r12  (4 uOP)  3
       //       ALU_Out <- RS(r14) + RT(0)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b0_0_0;
       end
       
       //    M[$r14 + 0] = $r12  (4 uOP)  4
       //       M[$r14 + 0] <- RT(r12)
      @(negedge clk)
       begin
         // Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
			// Datapath Control
         {D_En, DA_sel, T_Sel, HILO_LD, Y_Sel}       = 7'b0_0_0_0_000;
			//Data Memory Control
         {dm_cs, dm_rd, dm_wr}                       = 3'b1_0_1;
       end
       
          
      //**********END OF MICRO-OPERATIONS**********
		
		// Read updated regfile data
		$display("");
		$display("******Contents of updated registers******");
		Reg_Dump();
		
		// Read updated memory data
		$display("");
		$display("******Content of Memory Address FF8******");
      @(negedge clk)
         $display( "t=%t, $M[%h] = 0x%h%h%h%h",
                       $time, 12'hFF8, data_mem.M[ 12'hFF8 ]
                       ,data_mem.M[ 12'hFF8 + 1 ]
                       ,data_mem.M[ 12'hFF8 + 2 ]
                       ,data_mem.M[ 12'hFF8 + 3 ]);

	end //initial
      
endmodule
