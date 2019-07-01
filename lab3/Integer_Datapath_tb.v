`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Integer_Datapath_tb.v
 * Project:    lab 3
 * Designer:   Naoaki Takatsu
 * Email:      naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/1/2018
 *
 * Purpose:    This is the integer datapath module testbench.
 *
 * Notes:      This module will test for the following cases:
 *             Logical OR, Subtraction, Logical Shift Right, 
 *             Logical Shift Left, Division, Multiplication using DT,
 *             Register Init using DY, 1's Complement, 2's Complement,
 *             Addition, and Pass using PC_in.
 *             
 ****************************************************************************/
 
module Integer_Datapath_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [4:0] S_Addr;
	reg [4:0] T_Addr;
	reg [4:0] D_Addr;
	reg D_En;
	reg [31:0] DT;
	reg T_Sel;
	reg HILO_LD;
	reg [4:0] FS;
	reg [31:0] DY;
	reg [31:0] PC_in;
	reg [2:0] Y_Sel;

	// Outputs
	wire C;
	wire V;
	wire N;
	wire Z;
	wire [31:0] ALU_OUT;
	wire [31:0] D_OUT;
	
	integer i;

	// Instantiate the Unit Under Test (UUT)
	Integer_Datapath uut (
		.clk(clk), 
		.reset(reset), 
		.S_Addr(S_Addr), 
		.T_Addr(T_Addr), 
		.D_Addr(D_Addr), 
		.D_En(D_En), 
		.DT(DT), 
		.T_Sel(T_Sel), 
		.HILO_LD(HILO_LD), 
		.FS(FS), 
		.DY(DY), 
		.PC_in(PC_in), 
		.Y_Sel(Y_Sel), 
		.C(C), 
		.V(V), 
		.N(N), 
		.Z(Z), 
		.ALU_OUT(ALU_OUT), 
		.D_OUT(D_OUT)
	);
	
	task Reg_Dump;
		
		begin
	
         //Read initial regfile data through ALU_OUT
		   for( i = 0; i < 16; i = i + 1 )
		   begin
		
		      @ (negedge clk)
		      begin
		
   			reset = 1'b0; 
				
				// Regfile related control signals
			   { D_En, D_Addr, S_Addr, T_Addr } = 
			   { 1'b0, 5'h00,  i,      5'h00  };
			
		   	// ALU related control signals
			   { T_Sel, FS,    HILO_LD } = 
			   { 1'b0,  5'h00, 1'b0    };
			
			   // Y-MUX related control signals
			   { DT,            DY,            PC_in,         Y_Sel } = 
			   { 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
		   
				// clk D to S
				@ ( negedge clk )
	   		$display( "t=%t, r%0d = 0x%h",
		   	          $time, i, ALU_OUT);
						 
		      end
		
		   end

	   end
	
	endtask
	
	// Create a 10 ns clock
   always
   #5 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1'b1;
			
		// Regfile related control signals
		{ D_En, D_Addr, S_Addr, T_Addr } = 
		{ 1'b0, 5'h00,  5'h00,  5'h00  };
			
		// ALU related control signals
		{ T_Sel, FS,    HILO_LD } = 
		{ 1'b0,  5'h00, 1'b0    };
			
		// Y-MUX related control signals
		{ DT,            DY,            PC_in,         Y_Sel } = 
		{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h0  };
		
		// store .dat file data to regfile
		$readmemh( "./IntReg_Lab3.dat", uut.regfile.regs );
		$timeformat( -9, 1, " ps", 9 );    //Display time in nanoseconds

		// Wait 100 ns for global reset to finish
		#100;
		reset = 0;
		
		// Read initialized regfile data through ALU_OUT
		$display("******Contents of initialized registers******");		
		Reg_Dump();		
		
		// OR
		// $r1 <- $r3 | $r4
		@ (negedge clk)
		begin
		
			reset = 1'b0;
			
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h01,  5'h03,  5'h04  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h09, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// Signed SUB
		// $r2 <- $r1 - $r14
		@ (negedge clk)
		begin
	
			reset = 1'b0;
			
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h02,  5'h01,  5'h0E  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h03, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// SRL
		// $r3 <- SRL $r4
		@ (negedge clk)
		begin
	
			reset = 1'b0;
			
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h03,  5'h00,  5'h04  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h0D, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// SRL
		// $r4 <- SLL $r5
		@ (negedge clk)
		begin
	
			reset = 1'b0;
			
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h04,  5'h00,  5'h05  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h0C, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// DIV part 1
		// $LO <- $r15 / $r14
		// $HI <- $r15 % $r14
		@ (negedge clk)
		begin
		
		   reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b0, 5'h00,  5'h0F,  5'h0E  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h1F, 1'b1    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// DIV part 2
		// $r6 <- $HI
		@ (negedge clk)
		begin
		
		   reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h06,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h0  };
					 
		end
		
		// DIV part 3
		// $r5 <- $LO
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h05,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h1  };
					 
		end
		
		// MPY part 1
		// $LO <- $r11 * 0xFFFF_FFFB (lower 32 bit)
		// $HI <- $r11 * 0xFFFF_FFFB (upper 32 bit)
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b0, 5'h00,  5'h0B,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b1,  5'h1E, 1'b1    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'hFFFF_FFFB, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// MPY part 2
		// $r8 <- $HI
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h08,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h0  };
					 
		end
		
		// MPY part 3
		// $r7 <- $LO
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h07,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h1  };
					 
		end
		
		// SW immediate (DY_Load)
		// $r12 <- 0xABCD_EF01
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h0C,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'hABCD_EF01, 32'h0000_0000, 3'h3  };
					 
		end
		
		// NOR (1's complement)
		// $r11 <- $r0 NOR $r11
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h0B,  5'h00,  5'h0B  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h0B, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// SUB (2's complement)
		// $r10 <- $r0 - $r10
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h0A,  5'h00,  5'h0A  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h03, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
					 
		end
		
		// ADD
		// $r9 <- $r10 + $r11
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h09,  5'h0A,  5'h0B  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h02, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 3'h2  };
	 
		end
		
		// SW immediate (PC_Load)
		// $r13 <- 0x1001_00C0
		@ (negedge clk)
		begin
	
			reset = 1'b0;
	
			// Regfile related control signals
			{ D_En, D_Addr, S_Addr, T_Addr } = 
			{ 1'b1, 5'h0D,  5'h00,  5'h00  };
			
			// ALU related control signals
			{ T_Sel, FS,    HILO_LD } = 
			{ 1'b0,  5'h00, 1'b0    };
			
			// Y-MUX related control signals
			{ DT,            DY,            PC_in,         Y_Sel } = 
			{ 32'h0000_0000, 32'h0000_0000, 32'h1001_00C0, 3'h4  };

		end
		
		// Read updated regfile data through ALU_OUT
		$display("******Contents of updated registers******");
		Reg_Dump();

	end

endmodule

