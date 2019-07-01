`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  InstructionUnit.v
 * Project:    CECS 440 Lab 6: MIPS Control Unit
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/9/2018
 *
 * Purpose:    This is the Instruction Unit that holds and controls the 
 *             Program Counter, Instruction Memory and the Instruction Register.
 * Notes:      This module holds the 32-bit Program Counter, the Instruction
 *             Memory following the MIPS Instruction Formats, and the
 *             32-bit Instruction Register for the Datapath.
 *                IR_out[31:27] -> FS control for the ALU
 *                IR_out[25:21] -> S_Addr for the Datapath
 *                IR_out[20:16] -> T_Addr for the Datapath
 *                IR_out[15:11] -> D_Addr for the Datapath
 * 
 ****************************************************************************/
module Instruction_Unit(clk, reset, PC_in, pc_sel, pc_ld, pc_inc, PC_out,
                        im_cs, im_wr, im_rd,
                        ir_ld, IR_out, SE_16);
   input clk, reset;
   //Program Counter I/O
   input [31:0] PC_in;
   input  [1:0] pc_sel;
   input pc_ld, pc_inc;
   output [31:0] PC_out;
   //Instruction Memory I/O
   input im_cs, im_wr, im_rd;
   //Instruction Register I/O
   output        ir_ld;
   output [31:0] IR_out, SE_16;
   
   reg [31:0] PC, IR;   //synchronous registers
   
   wire [31:0] IMem_to_IR;
   
   InstructionMemory    IM (
                            .clk(clk),
                            .Address(PC_out), 
                            .D_In(32'h0),       //Write is deasserted so D_In is 0
                            .im_cs(im_cs), 
                            .im_wr(),           //Write is deasserted
                            .im_rd(im_rd), 
                            .D_Out(IMem_to_IR)
                           );
   
   always @(posedge clk, posedge reset)
      if(reset)
         {PC, IR} <= 64'b0;
      else  
       begin
         //PC         
         if(pc_ld)
            case(pc_sel)
               2'b00:   PC <= PC + { SE_16[29:0], 2'b00 }; //sll 2
               2'b01:   PC <= { PC[31:28], IR[25:0], 2'b00 };
               2'b10:   PC <= PC_in;
               default: PC <= PC;
            endcase
         else
            if(pc_inc)
               PC <= PC + 32'd4;
            else
               PC <= PC;
               
         //IR
         if(ir_ld)   IR <= IMem_to_IR;
         else        IR <= IR;
       end
       
   assign PC_out = PC;
   assign IR_out = IR;
   assign SE_16 = { {16{IR[15]}} , IR[15:0] };  //sign extended IR  
   
endmodule
