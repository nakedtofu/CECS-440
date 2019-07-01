`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  TopLevel_tb.v
 * Project:    lab 4
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjamin.santos@student.csulb.edu
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/1/2018
 *
 * Purpose:    This is the testbench for the Integer Datapath and the Data Memory
 *
 * Notes:      This module will test for the following cases:
 *             Logical OR, Subtraction, Logical Shift Right, 
 *             Logical Shift Left, Division, Multiplication using DT,
 *             Memory Read, 1's Complement, 2's Complement,
 *             Addition, and Memory Write.
 *             
 ****************************************************************************/

module TopLevel_tb;

	// Inputs
	reg        clk, reset, D_En, T_Sel, HILO_LD, dm_cs, dm_wr, dm_rd;
   reg [2:0]  Y_Sel;
   reg [4:0]  D_Addr, S_Addr, T_Addr, FS;
	reg [31:0] DT, PC_in;
   
	// Outputs
	wire N, Z, C, V;
	wire [31:0] D_IntToMem, D_MemToInt, Addr;
	
	integer i;

	// Instantiate the Unit Under Tests
   Integer_Datapath IDP (
                           .clk(clk),         .reset(reset),   .D_En(D_En), 
	                        .D_Addr(D_Addr),   .S_Addr(S_Addr), .T_Addr(T_Addr), 
								   .DT(DT),           .T_Sel(T_Sel),   .FS(FS), 
                           .N(N), .Z(Z),      .C(C), .V(V), 
                           .HILO_LD(HILO_LD), .DY(D_MemToInt), 
								   .PC_in(PC_in),     .Y_Sel(Y_Sel),   .ALU_OUT(Addr), 
								   .D_OUT(D_IntToMem)
                        );
                           
   DataMemory  data_mem (
                         .clk(clk),          .Address({20'b0, Addr[11:0]}), 
                         .D_In(D_IntToMem), 
                         .dm_cs(dm_cs),      .dm_wr(dm_wr),      .dm_rd(dm_rd), 
                         .D_Out(D_MemToInt)
                        );
	
	// Register Dump Task
	task Reg_Dump;	
      //Read initial regfile data through ALU_OUT
      for( i = 0; i < 16; i = i + 1 )
       begin
         @ (negedge clk)
          begin
            // Regfile related control signals
            {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00,  5'h00,  i};
            // ALU related control signals
            {T_Sel, FS, HILO_LD}           = {1'b0, 5'h01, 1'b0};
            // Y-MUX related control signals
            {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
            // Memory related control signals
            {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
            @ (negedge clk)
               $display( "t=%t, $r%0d = 0x%h",
                    $time, i, IDP.regfile.T );				
          end		
       end
	endtask
	
	// Create a 10 ns clock
   always #5 clk = ~clk;

	initial begin
	
   	// Initialize Inputs
		clk = 0;
		reset = 1'b1;
	
      // Regfile related control signals
      {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00,  5'h00,  5'h00};
      // ALU related control signals
      {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
      // Y-MUX related control signals
      {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
      // Memory related control signals
      {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		
		// store .dat file data to regfile
		$readmemh( "./IntReg_Lab4.dat", IDP.regfile.regs );
		$readmemh( "./dMem_Lab4.dat", data_mem.M );
		$timeformat( -9, 1, " ps", 9 );    //Display time in nanoseconds

		// Wait 100 ns for global reset to finish
		#100;
		reset = 0;
		     
      $display(" "); $display(" ");
      $display("******************************************************************");
      $display("           CECS 440 - Lab 4 Integer Datapath 2                    ");
      $display("******************************************************************");
      $display(" ");    

		// Read initialized regfile data through ALU_OUT
		$display("******Contents of initialized registers******");		
		Reg_Dump();		
      
      //***************MICRO-OPERATIONS***************
		
		// a.)   OR $r1 <- $r3 | $r4 
		//       1. $RS <- $S(r3), $RT <- $T(r4)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h03, 5'h04};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};       
		 end
		
		//       OR $r1 <- $r3 | $r4 
		//       2. $ALU_OUT <- $RS(r3) | $RT(r4)
		@ (negedge clk)
		 begin			
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h09, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       OR $r1 <- $r3 | $r4 
		//       3. $D(r1) <- $ALU_OUT(r3 | r4)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h01, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		// b.)   Signed SUB $r2 <- $r1 - $r14
		//       1. $RS <- $S(r1), $RT <- $T(r14)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h01, 5'h0E};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       Signed SUB $r2 <- $r1 - $r14
		//       2. $ALU_OUT <- $RS(r1) - $RT(r14)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h03, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       Signed SUB $r2 <- $r1 - $r14
		//       3. $D(r2) <- $ALU_OUT(r1 - r14)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h02, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		// c.)   SRL $r3 <- SRL $r4
		//       1. $RT <- $T(r4)
		@ (negedge clk)
		 begin			
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h04};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       SRL $r3 <- SRL $r4
		//       2. $ALU_OUT <- $RT(r14) >> 1
		@ (negedge clk)
  		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h0D, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       SRL $r3 <- SRL $r4
		//       3. $D(r3) <- $ALU_OUT(r14 >> 1)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h03, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		// d.)   SLL $r4 <- SLL $r5
		//       1. $RT <- $T(r5)
		@ (negedge clk)
		 begin			
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h05};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};			
		 end
		
		//       SLL $r4 <- SLL $r5
		//       2. $ALU_OUT <- $RT(r14) << 1
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h0C, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		//       SLL $r4 <- SLL $r5
		//       3. $D(r4) <- $ALU_OUT(r5 << 1)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h04, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		// e.)   DIV $r5 <- $r15 / $r14, $r6 <- $r15 % $r14		
		//       1. $RS <- $S(r15), $RT <- $T(r14)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h0F, 5'h0E};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		//       DIV $r5 <- $r15 / $r14, $r6 <- $r15 % $r14
		//       2. $HI <- $RS(r15) % $RT(r14)
		//          $LO <- $RS(r15) / $RT(r14)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h1F, 1'b1};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end

		//       DIV $r5 <- $r15 / $r14, $r6 <- $r15 % $r14
		//       3. $D(r6) <- $HI(r15 % r14)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h06, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h1};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
 		 end

		//       DIV $r5 <- $r15 / $r14, $r6 <- $r15 % $r14
		//       4. $D(r5) <- $LO(r15 / r14)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h05, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h2};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// f.)      MPY
		//          $r7 <- $r11 * 0xFFFF_FFFB (lower 32 bit)
		//          $r8 <- $r11 * 0xFFFF_FFFB (upper 32 bit)		
		//          1. $RS <- $S(r11)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h0B, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b1, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'hFFFF_FFFB, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};        
		 end

		//          MPY
      //          $r7 <- $r11 * 0xFFFF_FFFB (lower 32 bit)
		//          $r8 <- $r11 * 0xFFFF_FFFB (upper 32 bit)		
		//          2. $HI <- $RS(r11) * $RT(0xFFFF_FFFB) (upper 32 bits)
		//             $LO <- $RS(r11) * $RT(0xFFFF_FFFB) (lower 32 bits)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h1E, 1'b1};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};      
		 end
		
		//          MPY 
		//          $r7 <- $r11 * 0xFFFF_FFFB (lower 32 bit)
		//          $r8 <- $r11 * 0xFFFF_FFFB (upper 32 bit)
		//          3. $D(r8) <- $HI($r11 * 0xFFFF_FFFB)
		@ (negedge clk)
		begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h08, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h1};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		//          MPY 
		//          $r7 <- $r11 * 0xFFFF_FFFB (lower 32 bit)
		//          $r8 <- $r11 * 0xFFFF_FFFB (upper 32 bit)
		//          4. $D(r7) <- $LO($r11 * 0xFFFF_FFFB)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h07, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h2};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// g.)   Memory read $r12 <- M[r15]
		//       1. $RS <- $S(r15)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h0F, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};        
		 end
		
		//       Memory read $r12 <- M[r15]
		//       2. $ALU_OUT <- $RS(r15)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};
		 end
		
		//       Memory read $r12 <- M[r15]
		//       3. $DY <- M[$ALU_OUT(r15)]
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b1,  1'b0,  1'b1};
		 end

		//       Memory read $r12 <- M[r15]
		//       4. $D <- $DY(M[r15])
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h0C, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h3};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// h.)   NOR (1's complement) $r11 <- $r0 NOR $r11
		//       1. $RS <- $S(r0), $RT <- $T(r11)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h0B};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		//       NOR (1's complement) $r11 <- $r0 NOR $r11
		//       2. $ALU_OUT <- ~( $RS(r0) | $RT(r11) )
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h0B, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end

		//       NOR (1's complement) $r11 <- $r0 NOR $r11
		//       3. $D <- $ALU_OUT(~( r0 | r11 ))
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h0B, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// i.)   SUB (2's complement) $r10 <- $r0 - $r10
		//       1. $RS <- $S(r0), $RT <- $T(r10)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h0A};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		//       SUB (2's complement) $r10 <- $r0 - $r10
		//       2. $ALU_OUT <- $RS(r0) - $RT(r10)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h03, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end

		//       SUB (2's complement) $r10 <- $r0 - $r10
		//       3. $D <- $ALU_OUT($r0 - $r10)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h0A, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// j.)   ADD $r9 <- $r10 + $r11
		//       1. $RS <- $S(r10), $RT <- $T(r11)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h0A, 5'h0B};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end

		//       ADD $r9 <- $r10 + $r11
		//       2. $ALU_OUT <- $RS(r0) - $RT(r10)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h02, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		//       ADD $r9 <- $r10 + $r11
		//       3. $D <- $ALU_OUT($r10 + $r11)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h09, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// k.)   SW immediate (PC_Load) $r13 <- 0x1001_00C0
		//       $D <- $PC_in(0x1001_00C0)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b1, 5'h0D, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h1001_00C0, 3'h4};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		// l.)   write memory M[r14] <- R12
		//       1. $RS <- $S(r14), RT <- $T(r12)
		@ (negedge clk)
		 begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h0E, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		//       write memory M[r14] <- R12
		//       2. $ALU_OUT <- $RS(r12)
		@ (negedge clk)
		 begin
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h00};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b0,  1'b0,  1'b0};         
		 end
		
		//       write memory M[r14] <- R12
		//       3. $M[r14] <- $ALU_OUT(r12)
		@ (negedge clk)
		begin	
         // Regfile related control signals
         {D_En, D_Addr, S_Addr, T_Addr} = {1'b0, 5'h00, 5'h00, 5'h0C};
         // ALU related control signals
         {T_Sel, FS, HILO_LD}           = {1'b0, 5'h00, 1'b0};
         // Y-MUX related control signals
         {DT, PC_in, Y_Sel}             = {32'h0000_0000, 32'h0000_0000, 3'h0};
         // Memory related control signals
         {dm_cs, dm_wr, dm_rd}          = {1'b1,  1'b1,  1'b0};         
		end
      
      //**********END OF MICRO-OPERATIONS**********
		
		// Read updated regfile data through ALU_OUT
		$display("");
		$display("******Contents of updated registers******");
		Reg_Dump();
		
		$display("");
		$display("******Content of Memory Address R14******");
      @(negedge clk)
         $display( "t=%t, $M[%h] = 0x%h%h%h%h",
                       $time, 12'hFF8, data_mem.M[ 12'hFF8 ]
                       ,data_mem.M[ 12'hFF8 + 1 ]
                       ,data_mem.M[ 12'hFF8 + 2 ]
                       ,data_mem.M[ 12'hFF8 + 3 ]);
		
	end //initial

endmodule
