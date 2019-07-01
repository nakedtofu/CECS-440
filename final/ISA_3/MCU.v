`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MCU.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.4
 * Rev. Date:  11/20/2018
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
 * Revision Notes:
 *             1.2: Added Instructions: BEQ, BNE, ADDI, SRL, JMP, SRA, SLL, 
 *                                      SLT, SLTI, JAL, MULT, MFLO, MFHI, 
 *                                      XOR, SLTU, DIV, XORI, SUB, ANDI, 
 *                                      SLTIU, BLEZ, BGTZ
 *                  Added present and next state registers for the Interrupt 
 *                  and ALU status flags
 *             1.3: Added Instructions: SETIE, INPUT, OUTPUT
 *             1.4: Added Enhanced Instructions: ROTLEFT, ROTRIGHT
 *                   
 ****************************************************************************/
module MCU  (sys_clk, reset, intr,                 //system inputs
             c, n, z, v,                           //ALU status inputs
             IR,                                   //Instruction Register input
             int_ack,                              //Output to I/O subsystem
             FS,                                   //Function Select
             pc_sel, pc_ld, pc_inc, ir_ld,         //PC and IR control words
             im_cs, im_rd, im_wr,                  //Inst. Memory control words
             D_En, DA_sel, T_sel, HILO_ld, Y_sel,  //Datapath Control Words
             dm_cs, dm_rd, dm_wr,                  //Data memory control words
             io_cs, io_rd, io_wr, M_sel,           //IO module control words
             stat_sel,                             //Select for CPU output
             S_sel,                                //RS read select
             D_in                                  //D_in reg (return flags)
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
              
   //Added for Rev 1.3
   output reg io_cs, io_rd, io_wr, M_sel;
   
   //Added for Rev 1.4
   output reg [1:0] stat_sel;
   output reg       S_sel;
   input [31:0]     D_in;
   
   //****************************
   // Internal Data Structures
   //****************************

   //state assignments
   parameter
      RESET      = 00,  FETCH  = 01,  DECODE = 02,
      ADD        = 10,  ADDU   = 11,  AND    = 12, OR    = 13, NOR = 14,
      ORI        = 20,  LUI    = 21,  LW     = 22, LW2   = 23, SW  = 24,
      WB_alu     = 30,  WB_imm = 31,  WB_Din = 32,
      WB_hi      = 33,  WB_lo  = 34,  WB_mem = 35,
		JR1        = 40,  JR2    = 41,
      //      INTR_1     = 501, INTR_2 = 502, INTR_3 = 503,
      BREAK      = 510, 
      ILLEGAL_OP = 511,
      //added 
      BEQ        = 50,  BEQ2   = 51,               //Test 1
      BNE        = 60,  BNE2   = 61,               
      ADDI       = 70,  SRL    = 71,  JMP    = 72, //Test 2
      SRA        = 80,                             //Test 3
      SLL        = 90,  SLT    = 91,               //Test 4
      SLTI       = 92,                             //Test 5
      JAL        = 100, JAL2   = 101,              //Test 7
      MULT       = 110, MFLO   = 111, MFHI   = 112,//Test 8
      XOR        = 120, SLTU   = 121,              //Test 9 
      DIV        = 130,                            //Test 10
      XORI       = 140, SUB    = 141, ANDI   = 142,//Test 11
      SLTIU      = 143,
      BLEZ       = 150, BLEZ2  = 151,              //Test 12
      BGTZ       = 152, BGTZ2  = 153,
      SETIE      = 160,                            //Test 13
      INPUT      = 161, INPUT2 = 162,
      OUTPUT     = 163, OUTPUT2= 164,
      INTR_1     = 201, INTR_2 = 202, INTR_3 = 203,//Test 14
      INTR_4     = 204, INTR_5 = 205, INTR_6 = 206,
      INTR_7     = 207, INTR_8 = 208,
      RETI1      = 171, RETI2  = 172, RETI3  = 173,
      RETI4      = 174, RETI5  = 175, RETI6  = 176,
      //Enhanced Instructions
      ROTLEFT    = 180, ROTRIGHT = 181;
   
   //Registers 
   reg [8:0] state;              //State Register (up to 512 states)
   reg psi, psc, psv, psn, psz,  //Present state Status Flags
       nsi, nsc, nsv, nsn, nsz;  //Next state Status Flags
   
   always @(posedge sys_clk, posedge reset)
      if(reset)
         {psi, psc, psv, psn, psz} = 5'b0;
      else
         {psi, psc, psv, psn, psz} = {nsi, nsc, nsv, nsn, nsz};
     
   //***********************************************
   // 440 MIPS Control Unit (Finite State Machine)
   //***********************************************
   
   //Next State Logic
   always @(posedge sys_clk, posedge reset)
      if(reset)
         begin
            // PC <- 32'b0, R31($ra) <- 32'b0
            // NS <- RESET
            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b10_1_0_0;
            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_10_0_0_100;   FS = 5'h15;
            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;          int_ack = 0;
            {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
            {stat_sel, S_sel}                      = 3'b00_0;
            state = RESET;
         end
      else
         case(state)
            FETCH:   @(negedge sys_clk)   begin
                     if(int_ack == 0 & intr == 1)  begin
                        // control word assignments for 'deasserting' everything
                        // NS <- INTR_1
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        FS = 5'h00;        int_ack = 0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_1;
                      end
                     else
                      begin
                        if(int_ack == 1 & intr == 0) int_ack = 0;
                        // IR <- iM[PC], PC <- PC + 4
                        // NS <- DECODE
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_1_1;
                        {im_cs, im_rd, im_wr}                  = 3'b1_1_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = DECODE;
                      end
                     end //fetch
            RESET:   @(negedge sys_clk)
                      begin
                        // R29($sp) <- ALU_Out(32'h3FC)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_11_0_0_000;  
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;      
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //reset
            DECODE:  @(negedge sys_clk)
                      begin
                        if( IR[31:26] == 6'h0 ) //check for MIPS format
                           begin    //R-type format
                                    // RS <- $rs  RT <- $rt (default)
                            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                            {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                            {stat_sel, S_sel}                      = 3'b00_0;
                            FS = 5'h00;        int_ack = 0;
                            #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                            
                            //Decides which state to go to according to IR[5:0]
                            case ( IR[5:0] )
                              6'h0D :  state = BREAK;
                              6'h20 :  state = ADD;
										6'h08 :  state = JR1;
                              6'h02 :  state = SRL;      //iMem 2 test
                              6'h03 :  state = SRA;      //iMem 3 test
                              6'h00 :  state = SLL;      //iMem 4 test
                              6'h2A :  state = SLT;      
                              6'h18 :  state = MULT;     //iMem 8 test
                              6'h10 :  state = MFHI;     
                              6'h12 :  state = MFLO;
                              6'h26 :  state = XOR;      //iMem 9 test
                              6'h24 :  state = AND;
                              6'h25 :  state = OR;
                              6'h27 :  state = NOR;
                              6'h2B :  state = SLTU;
                              6'h1A :  state = DIV;      //iMem 10 test
                              6'h22 :  state = SUB;      //iMem 11 test
                              6'h1F :  state = SETIE;    //iMem 13 test
                              6'h2C :  state = ROTLEFT;  //Enhanced Instructions
                              6'h2D :  state = ROTRIGHT;
                              default: state = ILLEGAL_OP;
                            endcase
                           end //end of R - type
                        else
                           begin    //I-type or J-type format
                                    // RS <- $rs, RT <- DT
                            {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                            {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                            {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                            {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;  
                            {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                            {stat_sel, S_sel}                      = 3'b00_0;
                            FS = 5'h00;        int_ack = 0;
                            #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};

                            //Decides which state to go to according to IR[31:26]
                            case ( IR[31:26] )
                              6'h0D :  state = ORI;
                              6'h0F :  state = LUI;
                              6'h2B :  state = SW;
                              6'h04 :  {T_sel, state} = {1'b0, BEQ}; //iMem 1 test
                              6'h05 :  {T_sel, state} = {1'b0, BNE}; //iMem 1 test
                              6'h08 :  state = ADDI;                 //iMem 2 test
                              6'h02 :  state = JMP;                  //iMem 2 test  
                              6'h0A :  state = SLTI;                 //iMem 5 test
                              6'h23 :  state = LW;                   //iMem 6 test
                              6'h03 :  state = JAL;                  //iMem 7 test
                              6'h0E :  state = XORI;                 //iMem 11 test
                              6'h0C :  state = ANDI;
                              6'h0B :  state = SLTIU;
                              6'h06 :  state = BLEZ;                 //iMem 12 test
                              6'h07 :  state = BGTZ;
                              6'h1C :  state = INPUT;                //iMem 13 test
                              6'h1D :  state = OUTPUT;
                              6'h1E :  state = RETI1;                //iMem 14 test
                              default: state = ILLEGAL_OP;
                            endcase
                           end //end of I - type
                      end //end of DECODE
            ADD:     @(negedge sys_clk)   //Add (R-type)
                      begin
                        // ALU_Out <- RS($rs) + RT($rt)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;  
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //ADD
            ORI:     @(negedge sys_clk)   //Or Immediate (I-type)
                      begin
                        // ALU_Out <- RS($rs) or {16'h0, RT[15:0]}
                        // NS <- WB_imm
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h17;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //ORI
            LUI:     @(negedge sys_clk)   //Load Upper Immediate (I-type)
                      begin
                        // ALU_Out <- { RT[15:0], 16'h0 }
                        // NS <- WB_imm
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h18;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //LUI
             SW:     @(negedge sys_clk)   //Store Word (I-type)
                      begin
                        // ALU_Out <- RS($rs) + RT(se_16), RT <- $rt
                        // NS <- WB_mem
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_mem;
                      end //SW
            WB_alu:  @(negedge sys_clk)   //Write Back to D_Addr
                      begin
                        // R[rd] <- ALU_Out
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //WB_alu
            WB_imm:  @(negedge sys_clk)   //Write Back to T_Addr
                      begin
                        // R[rt] <- ALU_Out
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_01_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;   
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //WB_imm
            WB_mem:  @(negedge sys_clk)   //Write Back to Memory
                      begin
                        // M[ ALU_Out($rs + se_16) ] <- RT($rt)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_0_1; 
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;     
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //WB_mem
            BREAK:   @(negedge sys_clk)
                      begin
                        $display("BREAK INSTRUCTION FETCHED %t", $time);
                        //control word assignments for 'deasserting' everything
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;  
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        FS = 5'h00;        int_ack = 0;
                        $display(" R E G I S T E R ' S   A F T E R   B R E A K");
                        $display(" ");
                        Reg_Dump();       //Dumps Register Values
                        //Dump_DMEM();
                        Dump_DMEM_INTR(); //Dumps Values in Memory (0x3F0 - 0x404)
                        Dump_IO();        //Dumps Values in IO Memory 
                        Dump_PCIR();
                        $display(" ");
                        $finish;          //ends simulation
                      end //BREAK
            ILLEGAL_OP:
                     @(negedge sys_clk)
                      begin //ILLEGAL_OP
                        $display("ILLEGAL OPCODE FETCHED %t", $time);
                        // control word assignments for 'deasserting everything'
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        FS = 5'h00;        int_ack = 0;                        
                        Reg_Dump();
                        Dump_PCIR();        //Dumps Value of PC and IR
                        $finish;          //ends simulation
                      end //ILLEGAL_OP
            INTR_1:  @(negedge sys_clk)
                      begin
                        //PC gets address of interrupt vector, Save PC in stack
                        // RS <- 0x3FC, ALU_Out <- 0x3FC
                        // NS <- INTR_2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h15;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_2;
                      end //INTR_1
            INTR_2:  @(negedge sys_clk)
                      begin
                        // ALU_Out <- RS(0x3FC) + 4, RS <- RS(0x3FC) + 4
                        // NS <- INTR_3
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h11;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_3;
                      end //INTR_2  
            INTR_3:  @(negedge sys_clk)
                      begin
                        // M[ ALU_Out(0x400) ] <- PC,  RS <- ALU_Out(0x400)
                        // NS <- INTR_4
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_0_1;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b01_1;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_4;
                      end //INTR_3
            INTR_4:  @(negedge sys_clk)
                      begin
                        // ALU_Out <- RS(0x400) + 4
                        // NS <- INTR_5
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h11;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_5;
                      end //INTR_4
            INTR_5:  @(negedge sys_clk)
                      begin
                        // M[ ALU_Out(0x404) ] <- status flags(psi, c, v, n, z)
                        // $sp <- ALU_Out(0x404)
                        // NS <- INTR_6
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_11_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_0_1;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b10_0;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_6;                       
                      end //INTR_5
            INTR_6:  @(negedge sys_clk)
                      begin
                        // ALU_Out <- 0x3FC, RS <- 0x3FC
                        // NS <- INTR_7
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h15;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_7;
                      end //INTR_6
            INTR_7:  @(negedge sys_clk)
                      begin
                        //Read address of ISR into D_in
                        // D_in <- dM[ALU_Out(0x3FC)]
                        // NS <- INTR_8
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_1_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INTR_8;
                      end //INTR_7
            INTR_8:  @(negedge sys_clk)
                      begin
                        //Reload PC with address of ISR; ack the intr; goto FETCH
                        // PC <- D_in( dM[0x3FC] ), int_ack <- 1
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b10_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_011;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;          int_ack = 1;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end  //INTR_8
				   JR1:	@(negedge sys_clk)   //Jump Register (R-type)
					       begin
                        // ALU_Out <- RS($rs)
                        // NS <- JR2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = JR2;
                      end //JR1
					JR2:	@(negedge sys_clk)
					       begin
                        // PC <- ALU_Out($rs)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b10_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //JR2
                      
            //Added States for iMem 1-12
             //test 1
               BEQ:  @(negedge sys_clk)   //Branch on Equal (I-type)
					       begin
                        // ALU_Out <- RS($rs) - RT($rt)
                        // NS <- BEQ2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h03;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = BEQ2;
                      end //BEQ
					BEQ2:	@(negedge sys_clk)
					       begin
                        // if(z==1)    PC <- ALU_Out(se_16), NS <- FETCH
                        // else        NS <- FETCH
                        if(z == 1)  begin    //BEQ pass
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_1_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h01;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                        else  begin          //BEQ fail
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h00;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                      end //BEQ2                     
               BNE:  @(negedge sys_clk)   //Branch Not Equal (I-type)
					       begin
                        // ALU_Out <- RS($rs) - RT($rt)
                        // NS <- BRANCH(pass) OR NS <- FETCH(fail)
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h03;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = BNE2;
                      end //BNE
					BNE2:	@(negedge sys_clk)
					       begin
                        // if(z==1)    PC <- PC + ALU_Out(se_16), NS <- FETCH
                        // else        NS <- FETCH
                        if(z != 1)  begin    //BEQ pass
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_1_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h01;        int_ack = 0;
                          #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                        else  begin          //BEQ fail
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h00;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                      end //BNE2
            //test 2       
               ADDI: @(negedge sys_clk)   //Add Immediate (I-type)
					       begin
                        // ALU_Out <- RS($rs) + RT(se_16), RT <- RT($rt)
                        // NS <- WB_imm
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //ADDI
               SRL:  @(negedge sys_clk)   //Shift Right Logical (R-type)
					       begin
                        // ALU_Out <- RT($rt) >> IR[10:6]
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h0D;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //SRL
               JMP:  @(negedge sys_clk)   //Jump (J-type)
					       begin
                        // PC <- {PC[31:28], IR[25:0], 2'b00}
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b01_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //JMP
            //test 3
               SRA:  @(negedge sys_clk)   //Shift Right Arithmetic (R-type)
					       begin
                        // ALU_Out <- {$rt[31], %rt[31:1]}
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h0E;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //SRA
            //test 4
               SLL:  @(negedge sys_clk)   //Shift Left Logical (I-type)
					       begin
                        // ALU_Out <- RT($rt) << IR[10:6]
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h0C;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //SLL
               SLT:  @(negedge sys_clk)   //Set Less Than (R-type)
					       begin
                        // if( RS($rs) < RT($rt) )    ALU_Out <- 1
                        // else                       ALU_Out <- 0
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h06;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //SLT
            //test 5
               SLTI: @(negedge sys_clk)   //Set Less Than Immediate (I-type)
					       begin
                        // if( RS($rs) < RT(se_16) )  ALU_Out <- 1
                        // else                       ALU_Out <- 0
                        // NS <- WB_imm
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h06;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //SLTI
            //test 6
                 LW: @(negedge sys_clk)   //Load Word (I-type)
					       begin
                        // ALU_Out <- RS($rs) + RT(se_16)
                        // NS <- LW2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = LW2;
                      end //LW
                LW2: @(negedge sys_clk)
					       begin
                        // D_in <- M[rs + se_16]
                        // NS <- WB_Din
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_1_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_Din;
                      end //LW2
             WB_Din: @(negedge sys_clk)   //Write Back to Address of D_in
					       begin
                        // R[rt] <- D_in( M[rs + se_16] )
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_01_1_0_011;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;  
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //WB_Din
            //test 7
               JAL:  @(negedge sys_clk)   //Jump and Link (J-type)
					       begin
                        // R31 <- PC
                        // NS <- JAL2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_10_0_0_100;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = JAL2;
                      end //JAL
               JAL2: @(negedge sys_clk)
					       begin
                        // PC <- {PC[31:28], IR[25:0], 2'b00}
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b01_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //JAL2
            //test 8
               MULT: @(negedge sys_clk)   //Multiply (R-type)
					       begin
                        // {HI, LO} <- RS($rs) * RT($rt)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_1_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h1E;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //MULT
               MFLO: @(negedge sys_clk)   //Move from LO (R-type)
					       begin
                        // R[rd] <- LO
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_00_0_0_010;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //MFLO
               MFHI: @(negedge sys_clk)   //Move from HI (R-type)
					       begin
                        // R[rd] <- HI
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_00_0_0_001;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //MFHI
            //test 9
               XOR:  @(negedge sys_clk)   //Exclusive OR (R-type)
					       begin
                        // ALU_Out <- RS($rs) ^ RT($rt)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h0A;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //XOR
               AND:  @(negedge sys_clk)   //AND (R-type)
					       begin
                        // ALU_Out <- RS($rs) & RT($rt)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h08;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //AND
                OR:  @(negedge sys_clk)   //OR (R-type)
					       begin
                        // ALU_Out <- RS($rs) | RT($rt)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h09;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //OR
               NOR:  @(negedge sys_clk)   //Not OR (R-type)
					       begin
                        // ALU_Out <- ~( RS($rs) | RT($rt) )
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h0B;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //NOR
               SLTU: @(negedge sys_clk)   //Set Less Than Unsigned (R-type)
					       begin
                        // if( RS($rs) < RT(%rt) )    ALU_Out <- 1
                        // else                       ALU_Out <- 0
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h07;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //XOR
            //test 10
                DIV: @(negedge sys_clk)   //Divide (R-type)
					       begin
                        // {HI, LO} <- RS($rs) / RT($rt)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_1_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h1F;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //DIV
            //test 11
               XORI: @(negedge sys_clk)   //Exclusive OR Immediate (I-type)
					       begin
                        // ALU_Out <- RS($rs) ^ RT(se_16)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h19;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //XORI
                SUB: @(negedge sys_clk)   //Subtract (R-type)
					       begin
                        // ALU_Out <- RS($rs) - RT($rt)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h03;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end //SUB
               ANDI: @(negedge sys_clk)   //AND Immediate (I-type)
					       begin
                        // ALU_Out <- RS($rs) & RT(se_16)
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h16;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //ANDI
              SLTIU: @(negedge sys_clk)   //Set Less Than Immediate Unsigned (I-type)
					       begin
                        // if( RS($rs) < RT(%se_16) )    ALU_Out <- 1
                        // else                          ALU_Out <- 0
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h07;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_imm;
                      end //SLTIU
            //test 12  BLEZ, BGTZ
               BLEZ: @(negedge sys_clk)   //Branch on Less than or Equal to Zero (I-type)
					       begin
                        // ALU_Out <- RS($rs) - RT($rt), RT <- DT(se_16)
                        // NS <- BLEZ2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h03;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = BLEZ2;
                      end //BLEZ
				  BLEZ2: @(negedge sys_clk)
					       begin
                        // if(z==1) or (n==1) PC <- ALU_Out(se_16), NS <- FETCH
                        // else               NS <- FETCH
                        if( (z == 1) | (n == 1) )  begin    //BLEZ pass
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_1_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h01;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                        else  begin                         //BLEZ fail
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h00;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                      end //BLEZ2    
               BGTZ: @(negedge sys_clk)   //Branch on Greater Than Zero (I-type)
					       begin
                        // ALU_Out <- RS($rs) - RT($rt), RT <- DT(se_16)
                        // NS <- BGTZ2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h03;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = BGTZ2;
                      end //BGTZ
				  BGTZ2: @(negedge sys_clk)
					       begin
                        // if(z==1)    PC <- ALU_Out(se_16), NS <- FETCH
                        // else        NS <- FETCH
                        if( (z == 1) | (n == 1) ) begin  //BGTZ fail
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h00;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                        else  begin                      //BGTZ pass
                           {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_1_0_0;
                           {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                           {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                           {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                           {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                           {stat_sel, S_sel}                      = 3'b00_0;
                           FS = 5'h00;        int_ack = 0;
                           #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                           state = FETCH;
                         end
                      end //BGTZ2
            //test 13
              SETIE: @(negedge sys_clk)   //Set Interrupt Enable
					       begin
                        // NSI <- 1'b1
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {1'b1, c, v, n, z};
                        state = FETCH;
                      end //SETIE
              INPUT: @(negedge sys_clk)   //INPUT (similar to LW)
					       begin
                        // ALU_Out <- RS($rs) + RT(se_16)
                        // NS <- INPUT2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = INPUT2;
                      end //INPUT
             INPUT2: @(negedge sys_clk)   //      (similar to LW2)
					       begin
                        // D_in <- I_O[rs + se_16]
                        // NS <- WB_Din
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b1_1_0_1;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_Din;
                      end //INPUT2
             OUTPUT: @(negedge sys_clk)   //OUTPUT (similar to SW)
                      begin
                        // ALU_Out <- RS($rs) + RT(se_16), RT <- $rt
                        // NS <- OUTPUT2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_1_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h02;        int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = OUTPUT2;
                      end //OUTPUT
            OUTPUT2: @(negedge sys_clk)   //       (similar to WB_mem)
                      begin
                        // I_O[ ALU_Out($rs + se_16) ] <- RT($rt)
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0; 
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b1_0_1_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h00;        int_ack = 0;     
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end //OUTPUT2
         //test 14
         	 RETI1: @(negedge sys_clk)   //Return Interrupt
					       begin
                        // ALU_Out <- RS(0x404)
                        // NS <- RETI2
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = RETI2;
                      end //RETI1
              RETI2: @(negedge sys_clk)
                      begin
                        // D_in <- dM[ALU_Out(0x404)],
                        // NS <- RETI3
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_1_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = RETI3;
                      end  //RETI2
              RETI3: @(negedge sys_clk)
                      begin
                        // I, C, V, N, Z <- D_in(28'b0, intr, C, V, N, Z),
                        // ALU_Out <- RS(0x404) - 4, RS <- 0x404 - 4
                        // NS <- RETI4
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h12;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = D_in[4:0];
                        state = RETI4;
                      end //RETI3
              RETI4: @(negedge sys_clk)
                      begin
                        // D_in <- dM[ALU_Out(0x400)], 
                        // ALU_Out <- RS(0x400) - 4, RS <- 0x400 - 4
                        // NS <- RETI5
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b1_1_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h12;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = RETI5;
                      end //RETI4
              RETI5: @(negedge sys_clk)
                      begin
                        // PC <- D_in( dM[0x400] ),
                        // NS <- RETI6
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b10_1_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_011;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h00;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = RETI6;
                      end //RETI5
              RETI6: @(negedge sys_clk)
                      begin
                        // $sp <- ALU_Out(0x3FC), int_ack = 1,
                        // NS <- FETCH
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b1_11_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_1;
                        FS = 5'h00;          int_ack = 1;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = FETCH;
                      end  //RETI6
            //Enhanced Instructions
            ROTLEFT: @(negedge sys_clk)   //Rotate Left (R-type)
                      begin
                        // ALU_Out <- RT($rt) (rotate left) IR[10:6]
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h1C;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end  //ROTLEFT
           ROTRIGHT: @(negedge sys_clk)   //Rotate Right (R-type)
                      begin
                        // ALU_Out <- RT($rt) (rotate right) IR[10:6]
                        // NS <- WB_alu
                        {pc_sel, pc_ld, pc_inc, ir_ld}         = 5'b00_0_0_0;
                        {im_cs, im_rd, im_wr}                  = 3'b0_0_0; 
                        {D_En, DA_sel, T_sel, HILO_ld, Y_sel}  = 8'b0_00_0_0_000;
                        {dm_cs, dm_rd, dm_wr}                  = 3'b0_0_0;
                        {io_cs, io_rd, io_wr, M_sel}           = 4'b0_0_0_0;
                        {stat_sel, S_sel}                      = 3'b00_0;
                        FS = 5'h1D;          int_ack = 0;
                        #1 {nsi, nsc, nsv, nsn, nsz}           = {psi, c, v, n, z};
                        state = WB_alu;
                      end  //ROTRIGHT
                      
         endcase  //end of FSM logic
   
   // Simulation Tasks
   integer i;
         
   //Task to dump values of RegFile
   task Reg_Dump;
      //Output register values
      for( i = 0; i < 16; i = i + 1 )
         @(negedge sys_clk)
          begin
            $display( "t=%t, $r%0d = 0x%h  ||   $r%0d = 0x%h",
                       $time, i,    CPU_test3.cpu.IDP.regfile.regs[i],
                              i+16, CPU_test3.cpu.IDP.regfile.regs[i+16]);
          end
   endtask
   
   //Task to dump values of Memory Locations 0xC0 to 0xFF
   task Dump_DMEM;   begin
      $display(" "); $display("Memory Locations 0xC0 to 0xFF");
      for(i = 12'h0C0; i < 12'h100; i = i + 4)
         @(negedge sys_clk)
            $display( "t=%t, M[%h] = 0x%h%h%h%h",
                    $time, i, CPU_test3.data_mem.M[i],
                              CPU_test3.data_mem.M[i+1],
                              CPU_test3.data_mem.M[i+2],
                              CPU_test3.data_mem.M[i+3]);
      end
   endtask
   
   //Task to dump value of PC and IR
   task Dump_PCIR;
      @(negedge sys_clk)
         $display( "t=%t, PC = 0x%h,   IR = 0x%h", 
                    $time, CPU_test3.cpu.IU.PC, CPU_test3.cpu.IU.IR);
   endtask
   
   //Task to dump values from IO Location 0xC0 to 0xFF
   task Dump_IO;  begin
      $display(" "); $display("IO Memory Locations 0xC0 to 0xFF");
      for(i = 12'h0C0; i < 12'h100; i = i + 4)
         @(negedge sys_clk)
            $display( "t=%t, IO[%h] = 0x%h%h%h%h",
                       $time, i, CPU_test3.in_out.IO[i],
                                 CPU_test3.in_out.IO[i+1],
                                 CPU_test3.in_out.IO[i+2],
                                 CPU_test3.in_out.IO[i+3]);
      end
   endtask
   
   //Task to dump value from Memory Location 0x3F0
   task Dump_DMEM_3F0; begin
      $display(" "); $display("Memory Location 0x3F0");
      i = 12'h3F0;
      @(negedge sys_clk)     
            $display( "t=%t, M[%h] = 0x%h%h%h%h",
                       $time, i, CPU_test3.data_mem.M[i],
                                 CPU_test3.data_mem.M[i+1],
                                 CPU_test3.data_mem.M[i+2],
                                 CPU_test3.data_mem.M[i+3]);
      end
   endtask
   
   //Task to dump values from Memory Locations 0x3F0 to 0x404
   task Dump_DMEM_INTR; begin
      $display(" "); $display("Memory Location 0x3F0 to 0x404");
      for(i = 12'h3F0; i < 12'h408; i = i + 4)
         @(negedge sys_clk)     
            $display( "t=%t, M[%h] = 0x%h%h%h%h",
                       $time, i, CPU_test3.data_mem.M[i],
                                 CPU_test3.data_mem.M[i+1],
                                 CPU_test3.data_mem.M[i+2],
                                 CPU_test3.data_mem.M[i+3]);
      end
   endtask
   
endmodule
