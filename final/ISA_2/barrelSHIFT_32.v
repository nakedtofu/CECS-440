`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  barrelSHIFT_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  11/20/2018
 *
 * Purpose:    Provides the ALU the ability to shift up to 32 times.
 *             The Barrel Shift can Shift Left Logical(SLL), Shift Right
 *             Logical(SRL) and Shift Right Arithmetic(SRA).
 *             
 ****************************************************************************/
module barrelSHIFT_32(D, shift_val, LRRA, Y, C_BS);
   input  [31:0] D;           //32-bit input to be shifted
   input   [4:0] shift_val;   //Amount of Shifts to be done
   input   [1:0] LRRA;        //Type of Shift
   
   output reg [31:0] Y;       //32-bit output of the Barrel Shift
   output reg    C_BS;        //Carry Flag from the Shifts
   
   always @(*)
      if(LRRA == 2'b00) begin       //Left Shift Logical
         case(shift_val)
            5'd1:  Y = { D[30:0],  1'b0 };    5'd17: Y = { D[14:0], 17'b0 };
            5'd2:  Y = { D[29:0],  2'b0 };    5'd18: Y = { D[13:0], 18'b0 };
            5'd3:  Y = { D[28:0],  3'b0 };    5'd19: Y = { D[12:0], 19'b0 };
            5'd4:  Y = { D[27:0],  4'b0 };    5'd20: Y = { D[11:0], 20'b0 };
            5'd5:  Y = { D[26:0],  5'b0 };    5'd21: Y = { D[10:0], 21'b0 };
            5'd6:  Y = { D[25:0],  6'b0 };    5'd22: Y = {  D[9:0], 22'b0 };
            5'd7:  Y = { D[24:0],  7'b0 };    5'd23: Y = {  D[8:0], 23'b0 };
            5'd8:  Y = { D[23:0],  8'b0 };    5'd24: Y = {  D[7:0], 24'b0 };
            5'd9:  Y = { D[22:0],  9'b0 };    5'd25: Y = {  D[6:0], 25'b0 };
            5'd10: Y = { D[21:0], 10'b0 };    5'd26: Y = {  D[5:0], 26'b0 };
            5'd11: Y = { D[20:0], 11'b0 };    5'd27: Y = {  D[4:0], 27'b0 };
            5'd12: Y = { D[19:0], 12'b0 };    5'd28: Y = {  D[3:0], 28'b0 };
            5'd13: Y = { D[18:0], 13'b0 };    5'd29: Y = {  D[2:0], 29'b0 };
            5'd14: Y = { D[17:0], 14'b0 };    5'd30: Y = {  D[1:0], 30'b0 };
            5'd15: Y = { D[16:0], 15'b0 };    5'd31: Y = {    D[0], 31'b0 };
            5'd16: Y = { D[15:0], 16'b0 };
            default: Y = Y;
         endcase
         C_BS = D[31];
       end
      else if(LRRA == 2'b01) begin  //Right Shift Logical
         case(shift_val)
            5'd1:  Y = {  1'b0,   D[31:1] };    5'd17: Y = { 17'b0,  D[31:17] };
            5'd2:  Y = {  2'b0,   D[31:2] };    5'd18: Y = { 18'b0,  D[31:18] };
            5'd3:  Y = {  3'b0,   D[31:3] };    5'd19: Y = { 19'b0,  D[31:19] };
            5'd4:  Y = {  4'b0,   D[31:4] };    5'd20: Y = { 20'b0,  D[31:20] };
            5'd5:  Y = {  5'b0,   D[31:5] };    5'd21: Y = { 21'b0,  D[31:21] };
            5'd6:  Y = {  6'b0,   D[31:6] };    5'd22: Y = { 22'b0,  D[31:22] };
            5'd7:  Y = {  7'b0,   D[31:7] };    5'd23: Y = { 23'b0,  D[31:23] };
            5'd8:  Y = {  8'b0,   D[31:8] };    5'd24: Y = { 24'b0,  D[31:24] };
            5'd9:  Y = {  9'b0,   D[31:9] };    5'd25: Y = { 25'b0,  D[31:25] };
            5'd10: Y = { 10'b0,  D[31:10] };    5'd26: Y = { 26'b0,  D[31:26] };
            5'd11: Y = { 11'b0,  D[31:11] };    5'd27: Y = { 27'b0,  D[31:27] };
            5'd12: Y = { 12'b0,  D[31:12] };    5'd28: Y = { 28'b0,  D[31:28] };
            5'd13: Y = { 13'b0,  D[31:13] };    5'd29: Y = { 29'b0,  D[31:29] };
            5'd14: Y = { 14'b0,  D[31:14] };    5'd30: Y = { 30'b0,  D[31:30] };
            5'd15: Y = { 15'b0,  D[31:15] };    5'd31: Y = { 31'b0,     D[31] };
            5'd16: Y = { 16'b0,  D[31:16] };
            default: Y = Y;
         endcase
         C_BS = D[0];
       end
      else if (LRRA == 2'b10) begin //Right Shift Arithmetic
         case(shift_val)            
            5'd1:  Y = {       D[31],  D[31:1] };
            5'd2:  Y = { { 2{D[31]}},  D[31:2] };
            5'd3:  Y = { { 3{D[31]}},  D[31:3] };
            5'd4:  Y = { { 4{D[31]}},  D[31:4] };
            5'd5:  Y = { { 5{D[31]}},  D[31:5] };
            5'd6:  Y = { { 6{D[31]}},  D[31:6] };
            5'd7:  Y = { { 7{D[31]}},  D[31:7] };
            5'd8:  Y = { { 8{D[31]}},  D[31:8] };
            5'd9:  Y = { { 9{D[31]}},  D[31:9] };
            5'd10: Y = { {10{D[31]}}, D[31:10] };
            5'd11: Y = { {11{D[31]}}, D[31:11] };
            5'd12: Y = { {12{D[31]}}, D[31:12] };
            5'd13: Y = { {13{D[31]}}, D[31:13] };
            5'd14: Y = { {14{D[31]}}, D[31:14] };
            5'd15: Y = { {15{D[31]}}, D[31:15] };
            5'd16: Y = { {16{D[31]}}, D[31:16] };
            5'd17: Y = { {17{D[31]}}, D[31:17] };
            5'd18: Y = { {18{D[31]}}, D[31:18] };
            5'd19: Y = { {19{D[31]}}, D[31:19] };
            5'd20: Y = { {20{D[31]}}, D[31:20] };
            5'd21: Y = { {21{D[31]}}, D[31:21] };
            5'd22: Y = { {22{D[31]}}, D[31:22] };
            5'd23: Y = { {23{D[31]}}, D[31:23] };
            5'd24: Y = { {24{D[31]}}, D[31:24] };
            5'd25: Y = { {25{D[31]}}, D[31:25] };
            5'd26: Y = { {26{D[31]}}, D[31:26] };
            5'd27: Y = { {27{D[31]}}, D[31:27] };
            5'd28: Y = { {28{D[31]}}, D[31:28] };
            5'd29: Y = { {29{D[31]}}, D[31:29] };
            5'd30: Y = { {30{D[31]}}, D[31:30] };
            5'd31: Y = { {31{D[31]}},    D[31] };
            default: Y = Y;
         endcase 
         C_BS = D[0];
       end
endmodule
