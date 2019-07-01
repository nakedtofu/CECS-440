`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  rotate_32.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  11/20/2018
 *
 * Purpose:    Provides the ALU the ability to rotate up to 31 times.
 *             The Rotate module can rotate left and right.
 *             
 ****************************************************************************/
module rotate_32(D, shift_val, LorR, Y);
   input  [31:0] D;           //32-bit input to be rotated
   input   [4:0] shift_val;   //Amount of Shifts to be done
   input         LorR;        //Rotate rule
   
   output reg [31:0] Y;       //32-bit output of the Barrel Shift
   
   always @(*) begin
      if(LorR == 1'b0)   //Rotate Left
         case(shift_val)
            5'd1:  Y = { D[30:0],    D[31] };  5'd17: Y = { D[14:0], D[31:15] };
            5'd2:  Y = { D[29:0], D[31:30] };  5'd18: Y = { D[13:0], D[31:14] };
            5'd3:  Y = { D[28:0], D[31:29] };  5'd19: Y = { D[12:0], D[31:13] };
            5'd4:  Y = { D[27:0], D[31:28] };  5'd20: Y = { D[11:0], D[31:12] };
            5'd5:  Y = { D[26:0], D[31:27] };  5'd21: Y = { D[10:0], D[31:11] };
            5'd6:  Y = { D[25:0], D[31:26] };  5'd22: Y = {  D[9:0], D[31:10] };
            5'd7:  Y = { D[24:0], D[31:25] };  5'd23: Y = {  D[8:0],  D[31:9] };
            5'd8:  Y = { D[23:0], D[31:24] };  5'd24: Y = {  D[7:0],  D[31:8] };
            5'd9:  Y = { D[22:0], D[31:23] };  5'd25: Y = {  D[6:0],  D[31:7] };
            5'd10: Y = { D[21:0], D[31:22] };  5'd26: Y = {  D[5:0],  D[31:6] };
            5'd11: Y = { D[20:0], D[31:21] };  5'd27: Y = {  D[4:0],  D[31:5] };
            5'd12: Y = { D[19:0], D[31:20] };  5'd28: Y = {  D[3:0],  D[31:4] };
            5'd13: Y = { D[18:0], D[31:19] };  5'd29: Y = {  D[2:0],  D[31:3] };
            5'd14: Y = { D[17:0], D[31:18] };  5'd30: Y = {  D[1:0],  D[31:2] };
            5'd15: Y = { D[16:0], D[31:17] };  5'd31: Y = {    D[0],  D[31:1] };
            5'd16: Y = { D[15:0], D[31:16] };
            default: Y = Y;
         endcase
      else              //Rotate Right
         case(shift_val)
            5'd1:  Y = {    D[0],  D[31:1] };  5'd17: Y = { D[16:0], D[31:17] };
            5'd2:  Y = {  D[1:0],  D[31:2] };  5'd18: Y = { D[17:0], D[31:18] };
            5'd3:  Y = {  D[2:0],  D[31:3] };  5'd19: Y = { D[18:0], D[31:19] };
            5'd4:  Y = {  D[3:0],  D[31:4] };  5'd20: Y = { D[19:0], D[31:20] };
            5'd5:  Y = {  D[4:0],  D[31:5] };  5'd21: Y = { D[20:0], D[31:21] };
            5'd6:  Y = {  D[5:0],  D[31:6] };  5'd22: Y = { D[21:0], D[31:22] };
            5'd7:  Y = {  D[6:0],  D[31:7] };  5'd23: Y = { D[22:0], D[31:23] };
            5'd8:  Y = {  D[7:0],  D[31:8] };  5'd24: Y = { D[23:0], D[31:24] };
            5'd9:  Y = {  D[8:0],  D[31:9] };  5'd25: Y = { D[24:0], D[31:25] };
            5'd10: Y = {  D[9:0], D[31:10] };  5'd26: Y = { D[25:0], D[31:26] };
            5'd11: Y = { D[10:0], D[31:11] };  5'd27: Y = { D[26:0], D[31:27] };
            5'd12: Y = { D[11:0], D[31:12] };  5'd28: Y = { D[27:0], D[31:28] };
            5'd13: Y = { D[12:0], D[31:13] };  5'd29: Y = { D[28:0], D[31:29] };
            5'd14: Y = { D[13:0], D[31:14] };  5'd30: Y = { D[29:0], D[31:30] };
            5'd15: Y = { D[14:0], D[31:15] };  5'd31: Y = { D[30:0],    D[31] };
            5'd16: Y = { D[15:0], D[31:16] };           
            default: Y = Y;
         endcase
    end
    
endmodule
