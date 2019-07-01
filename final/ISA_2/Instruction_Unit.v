`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  InstructionUnit.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.2
 * Rev. Date:  11/8/2018
 *
 * Purpose:    This is the Instruction Unit that holds and controls the 
 *             Program Counter, Instruction Memory and the Instruction Register.
 * Notes:      This module holds the 32-bit Program Counter, the Instruction
 *             Memory following the MIPS Instruction Formats, and the
 *             32-bit Instruction Register for the Datapath.
 *                IR_out[25:21] -> S_Addr for the Datapath
 *                IR_out[20:16] -> T_Addr for the Datapath
 *                IR_out[15:11] -> D_Addr for the Datapath
 * 
 ****************************************************************************/
module Instruction_Unit(clk, reset, PC_in, pc_sel, pc_ld, pc_inc, PC_out,
                        im_cs, im_wr, im_rd,
                        ir_ld, IR_out, SE_16);
   input clk, reset;          //Clock and Reset
   input [31:0] PC_in;        //Value to change PC
   input  [1:0] pc_sel;       //Select for new PC value
   input pc_ld, pc_inc;       //PC write enable and increment flag
   input         ir_ld;       //Instruction Register Load Enable
   input im_cs, im_wr, im_rd; //Instruction Memory Flags
   output [31:0] PC_out;      //Output current PC
   output [31:0] IR_out,      //Output current IR
                  SE_16;      //Output sign extended IR
   
   reg [31:0] PC, IR;         //PC and IR register
   
   wire [31:0] IMem_to_IR;    //Data from I-Memory to IR if ir_ld is 1
   
   InstructionMemory IM (
                      .clk(clk),                   //Clock
                      .Address( { 20'b0,           //Only takes first 12 bits
                                  PC_out[11:0]}),  //of Address
                      .D_In(32'h0),                //Handled by $readmemh in TB
                      .im_cs(im_cs),               //  \
                      .im_rd(im_rd),               // --> Instruction Memory Flags
                      .im_wr(),                    //  /
                      .D_Out(IMem_to_IR)
                     );
   
   always @(posedge clk, posedge reset)
      if(reset)
         {PC, IR} <= 64'b0;      //Reset PC and IR values
      else  
       begin
         //Program Counter Input Logic      
         if(pc_ld)
            case(pc_sel)
               2'b00:   PC <= PC + { SE_16[29:0], 2'b00 };     //for Branches
               2'b01:   PC <= { PC[31:28], IR[25:0], 2'b00 };  //for Jumps
               2'b10:   PC <= PC_in;                           //for Returns
               default: PC <= PC;
            endcase
         else
            if(pc_inc)     //Increment PC
               PC <= PC + 32'd4;
            else
               PC <= PC;
               
         //IR
         if(ir_ld)   IR <= IMem_to_IR;
         else        IR <= IR;
       end
       
   // Asynchronous Outputs of PC, IR and SE    
   assign PC_out = PC;
   assign IR_out = IR;
   assign SE_16 = { {16{IR[15]}} , IR[15:0] };  //sign extended Instruction Register
   
endmodule
