`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  InstructionUnit.v
 * Project:    CECS 440 Lab 6: MIPS Control Unit
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/15/2018
 *
 * Purpose:    A state machine implementing the MIPS Control Unit (MCU) for the 
 *             major cycles of fetch, execute and some MIPS instructions from 
 *             memory, including checking for interrupts.
 * 
 * Notes:      MCU Control Word:
 *
 * {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
 * {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
 * {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
 * {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
 * 
 ****************************************************************************/
module MCU  (sys_clk, reset, intr,     //system inputs
             c, n, z, v,               //ALU status inputs
             IR,                       //Instruction Register input
             int_ack,                  //output to I/O subsystem
             //rest of control word fields
             FS,
             pc_sel, pc_ld, pc_inc, ir_ld,         //PC and IR control words
             im_cs, im_rd, im_wr,                  //Inst. Memory control words
             D_En, DA_sel, T_sel, HILO_ld, Y_sel,  
             dm_cs, dm_rd, dm_wr                   //Data memory control words
            );
   input sys_clk, reset, intr;
   input c, n, z, v;
   input [31:0] IR;
   output reg int_ack;
   
   //control words
   output reg [4:0] FS;                //5-bit control word
   output reg [2:0] Y_sel;             //3-bit control word
   output reg [1:0] pc_sel, DA_sel;    //2-bit control words
   output reg pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr, 
              D_En, T_sel, HILO_ld, dm_cs, dm_rd, dm_wr;   
   
   //****************************
   // Internal Data Structures
   //****************************

   //state assignments
   parameter
      RESET      = 00,  FETCH  = 01,  DECODE = 02,
      ADD        = 10,  ADDU   = 11,  AND    = 12, OR    = 13, NOR = 14,
      ORI        = 20,  LUI    = 21,  LW     = 22, SW    = 23,
      WB_alu     = 30,  WB_imm = 31,  WB_Din = 32,
      WB_hi      = 33,  WB_lo = 34,   WB_mem = 35, 
      INTR_1     = 501, INTR_2 = 502, INTR_3 = 503,
      BREAK      = 510, 
      ILLEGAL_OP = 511;
   
   //state register (up to 512 states)
   reg [8:0] state;
   //reg psi, psc, psv, psn, psz, nsi, nsc, nsv, nsn, nsz;
     
   //***********************************************
   // 440 MIPS Control Unit (Finite State Machine)
   //***********************************************
   //Next State Logic
   always @(posedge sys_clk, posedge reset)
      if(reset)
         begin
            // control word assignments for the reset condition should be here
            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
            state = RESET;
         end
      else
         case(state)
            FETCH:   @(negedge sys_clk)
                     if(int_ack == 0 & intr == 1) begin
                        // control word assignments for 'deasserting' everything
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
                        state = INTR_1;
                     end
							
                     else begin
                        if(int_ack == 1 & intr == 0)
								   int_ack = 0;	
									
								// control word assignments for IR <- iM[PC]; PC <- PC+4
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_1_1;
                           {im_cs, im_rd, im_wr}                  = 3'b1_1_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           state = DECODE;
                     end
							
            RESET:   @(negedge sys_clk)
                     begin
                        // control word assignments for $sp <- ALU_Out(32'h3FC)  //R31 is SP and gets 0x3FC
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b10_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_11_0_0_100;   FS = 5'h15;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
                        state = FETCH;
                     end
            DECODE:  @(negedge sys_clk)
                     begin
                        @(negedge sys_clk)
                        if( IR[31:26] == 6'h0 ) //check for MIPS format
                           begin    //R - type format
                                    //control word assignments: RS <- $rs  RT <- $rt (default)
                            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
                            case ( IR[5:0] )
                              6'h0D :  state = BREAK;
                              6'h20 :  state = ADD;
                              default: state = ILLEGAL_OP;
                            endcase
                           end //end of R - type
                        else
                           begin    //I - type format
                                    //RS <- $rs, RT <- DT
                            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;   FS = 5'h0;
                            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;                              
                            case ( IR[31:26] )
                              6'h0D :  state = ORI;
                              6'h0F :  state = LUI;
                              6'h2B :  state = SW;
                              default: state = ILLEGAL_OP;
                            endcase
                           end //end of I - type
                     end //end of DECODE
            ADD:     @(negedge sys_clk)
                     begin
                        //control word assignments: ALU_Out <- RS($rs) + RT($rt)
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h02;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = WB_alu;
                     end
            ORI:     @(negedge sys_clk)
                     begin
                        //control word assignments: ALU_Out <- RS($rs) | {16'h0, RT[15:0]}
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h17;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = WB_imm;
                     end
            LUI:     @(negedge sys_clk)
                     begin
                        //control word assignments: ALU_Out <- { RT[15:0], 16'h0 }
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h18;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = WB_imm;
                     end
             SW:     @(negedge sys_clk)
                     begin
                        //control word assignments: ALU_Out <- RS($rs) + RT(se_16), RT <- $rt   probably wrong
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = WB_mem;
                     end
            WB_alu:  @(negedge sys_clk)
                     begin
                        //control word assignments: R[rd] <- ALU_Out
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = FETCH;
                     end
            WB_imm:  @(negedge sys_clk)
                     begin
                        //control word assignments: R[rt] <- ALU_Out
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        state = FETCH;
                     end
            WB_mem:  @(negedge sys_clk)
                     begin
                        //control word assignments: M[ ALU_Out($rs + se_16) ] <- RT($rt)
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_0_1;   
                        state = FETCH;
                     end
            BREAK:   @(negedge sys_clk)
                     begin
                        $display("BREAK INSTRUCTION FETCHED %t", $time);
                        //control word assignments for 'deasserting' everything
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        $display(" R E G I S T E R ' S   A F T E R   B R E A K");
                        $display(" ");
                        //Dump_Registers;   //R0 - R15 task to output MIPS RegFile
                        //Dump DMEM         //from memory 3F0 to 3F3
                        $display(" ");
//                        $display("time=%t  M[3F0]=%h", $time, {TopLevel6_tb.dMem.M[12'h3F0],
//                                                               TopLevel6_tb.dMem.M[12'h3F1],
//                                                               TopLevel6_tb.dMem.M[12'h3F2],
//                                                               TopLevel6_tb.dMem.M[12'h3F3]} );
                        $finish;
                     end
            ILLEGAL_OP:
                     @(negedge sys_clk)
                     begin
                        $display("ILLEGAL OPCODE FETCHED %t", $time);
                        // control word assignments for 'deasserting everything'
                        // Dump_Registers;
                        // Dump_PC_and_IR;
                        $finish;
                     end
            INTR_1:  @(negedge sys_clk)
                     begin
                        //PC gets address of interrupt vector; Save PC in $ra
                        //control word assignments: ALU_Out <- 0x3FC, R[$ra] <- PC
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
                        state = INTR_2;
                     end
            INTR_2:  @(negedge sys_clk)
                     begin
                        //Read address of ISR into D_in
                        //control word assignments: D_in <- dM[ALU_Out(0x3FC)]
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_1_0;          int_ack = 0;
                        state = INTR_3;
                     end
            INTR_3:  @(negedge sys_clk)
                     begin
                        //Reload PC with address of ISR; ack the intr; goto FETCH
                        //control word assignments: PC <- D_in( dM[0x3FC] ), int_ack <- 1
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 1; 
                        state = FETCH;
                     end              
         endcase  //end of FSM logic
         
//   //TASKS
//   // Register Dump Task
//   task Reg_Dump;
//      //Output register values
//      for( i = 0; i < 16; i = i + 1 )
//       begin
//         @(negedge clk)
//          begin
//            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
//            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
//            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;   FS = 5'h0;
//            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
//            @(negedge clk)
//               $display( "t=%t, $r%0h = 0x%h",
//                          $time, i, IDP.regfile.regs[i]);
//          end
//       end
//   endtask
         
endmodule
