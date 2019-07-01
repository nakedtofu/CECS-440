`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  alu_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2018
 *
 * Purpose:    This module will instantiate three modules:
 *             MIPS_32, DIV_32, and MPY_32.
 *
 * Notes:      This is the Arithmetic Logic Unit module. It will act as a 
 *             wrapper instantiating MIPS_32, DIV_32, and MPY_32 modules.
 *             5 bit function select "FS" will select which wires to use for
 *             this module's outputs.
 *
 * Revision Notes:
 *             1.2:  Added input shift_val - Shift Value for Barrel Shift
 *             
 ****************************************************************************/
module alu_32( FS, S, T, N, Z, V, C, Y_hi, Y_lo, shift_val );

   input wire [4:0] FS;          // function select
	input wire [31:0] S, T;       // two 32 bit inputs
   
   input [4:0] shift_val;        //Added for Rev 1.2
   
	output reg N, Z, V, C;        // negative, zero, overflow, carry flags
	output reg [31:0] Y_hi, Y_lo; // two 32 bit outputs
	
   //Temporary Wires
   wire [63:0] Y_mips, Y_mul, Y_div;   //Y values of MIPS, MPY and DIV
   wire N_mps, Z_mps, V_mps, C_mps;    //All flags of the MIPS module
   wire N_mul, Z_mul, V_mul, C_mul;    //All flags of the MPY module
   wire N_div, Z_div, V_div, C_div;    //All flags of the DIV module
   
   //Added Wires for Rev 1.2
   wire [31:0] Y_BS;
   wire        C_BS;
	
   // instantiate MIPS, DIV, and MPY modules
   MIPS_32  MOD_1    (
                      .S(S),                 //32-bit Input S
                      .T(T),                 //32-bit Input T
                      .FS(FS),               //Function Select
                      .Y_hi(Y_mips[63:32]),  //32-bit upper output from MIPS
                      .Y_lo(Y_mips[31:0]),   //32-bit lower output from MIPS
                      .N(N_mps),             //Negative flag output of MIPS
                      .Z(Z_mps),             //Zero     flag output of MIPS
                      .V(V_mps),             //Overflow flag output of MIPS
                      .C(C_mps)              //Carry    flag output of MIPS
                     ); 
   MPY_32   MOD_2    (
                      .S(S),                 //32-bit Input S
                      .T(T),                 //32-bit Input T
                      .Y_hi(Y_mul[63:32]),  //32-bit upper output from MPY
                      .Y_lo(Y_mul[31:0]),   //32-bit lower output from MPY
                      .N(N_mul),             //Negative flag output of MPY
                      .Z(Z_mul),             //Zero     flag output of MPY
                      .V(V_mul),             //Overflow flag output of MPY
                      .C(C_mul)              //Carry    flag output of MPY
                     ); 
   DIV_32   MOD_3    (
                      .S(S),                 //32-bit Input S
                      .T(T),                 //32-bit Input T
                      .Y_hi(Y_div[63:32]),   //32-bit upper output from MPY
                      .Y_lo(Y_div[31:0]),    //32-bit upper output from MPY   
                      .N(N_div),             //Negative flag output of DIV
                      .Z(Z_div),             //Zero     flag output of DIV
                      .V(V_div),             //Overflow flag output of DIV
                      .C(C_div)              //Carry    flag output of DIV
                     );
   barrelSHIFT_32 BS_32(
                      .D(T),                //32-bit Input T
                      .shift_val(shift_val),//Shift value
                      .LRRA(FS[1:0]),       //Select for shift type
                      .Y(Y_BS),             //32-bit Output of Barrel Shift
                      .C_BS(C_BS)           //Carry of Barrel Shift
                     );
	
   //sets the ALU Y value to the Y value from its needed module.
   always @(*) begin
       //Barrel Shift
      if( (FS == 5'h0C) | (FS == 5'h0D) | (FS == 5'h0E) ) begin
         {Y_hi, Y_lo} = {32'b0, Y_BS};
         {N, Z, V, C} = {
                           (Y_BS[31]) ? 1'b1:1'b0,       //Negative
                           (Y_BS == 32'h0) ? 1'b1:1'b0,  //Zero
                           1'bx,                         //Overflow
                           C_BS                          //Carry
                        };
         end
       //Multiply
      else if(FS == 5'h1E)      begin 
         {Y_hi, Y_lo} = Y_mul;
         {N, Z, V, C} = {N_mul, Z_mul, 1'bx, 1'bx};
         end
       //Divide
      else if(FS == 5'h1F) begin
         {Y_hi, Y_lo} = Y_div;
         {N, Z, V, C} = {N_div, Z_div, V_div, 1'bx};
         end
       //MIPS 
      else                 begin
         {Y_hi, Y_lo} = Y_mips;
         {N, Z, V, C} = {N_mps, Z_mps, V_mps, C_mps};
         end
   end //always
   
endmodule
