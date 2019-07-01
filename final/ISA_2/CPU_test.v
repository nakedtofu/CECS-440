`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:40:09 11/20/2018 
// Design Name: 
// Module Name:    CPU_test 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module CPU_test();

	// Inputs
	reg clk, reset;  
   reg intr;
   
	// Outputs
   //wire intr;
   wire int_ack;  //Interrupt Flags
	wire [31:0] D_IntToMem, Addr;
   wire [31:0] D_MemToInt;
   wire dm_cs, dm_wr, dm_rd; //Data Memory module
   
	// Instantiate the Unit Under Tests
   CPU               cpu(
                         .clk(clk),               .reset(reset),
                         .intr(intr),             .int_ack(int_ack),                
                         .D_MemToInt(D_MemToInt),
                         .Addr(Addr),             .D_IntToMem(D_IntToMem),
                         .dm_cs(dm_cs), .dm_wr(dm_wr), .dm_rd(dm_rd) 
                        );
   DataMemory  data_mem (
                         .clk(clk),          .Address({20'b0, Addr[11:0]}), 
                         .D_In(D_IntToMem), 
                         .dm_cs(dm_cs),      .dm_wr(dm_wr),  .dm_rd(dm_rd), 
                         .D_Out(D_MemToInt)
                        );
                                                   	


endmodule
