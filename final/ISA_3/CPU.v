`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU.v
 * Project:    CECS 440 Senior Project - Enhanced MIPS Processor
 * Designer:   Benjamin Santos and Naoaki Takatsu
 * Email:      benjaminsantos@gmx.com
 *             naoaki.takatsu@student.csulb.edu
 * Rev. No.:   Version 1.2
 * Rev. Date:  11/8/2018
 *
 * Purpose:    The Central Processing Unit(CPU) module has the Control 
 *             Unit, Instruction Unit and the Datpath modules. 
 *
 * Notes:      The CPU can be connected to the DataMemory module and the
 *             InputOutput module that can be written to and read from
 *             according to the Instruction from the Instruction Memory
 *             The Instruction Memory is instantiated using $readmemh on the 
 *             testbench module (CPU_test1.v)
 *
 * Revision Notes:
 *             1.2:  Added IO flag outputs (io_cs, io_rd, io_wr)
 *                   Added wires M_sel  - Determines data going into Datapath
 *                               DY     - Input for DY reg of the Datapath
 *             1.3:  Added wires D_val  - Value from D_OUT of Datapath
 *                               stat_sel
 *                                      - Determines the Data type being
 *                                        output by the CPU
 *                               S_sel  - Determines where register RS in the
 *                                        Datapath is getting Data from
 *                               D_in   - Register D_in from the Datapath now
 *                                        connects to the Control Unit to
 *                                        acquire the status flags from the
 *                                        stack
 *                                        
 ****************************************************************************/
module CPU(clk, reset,            //Clock and Reset
           intr,  int_ack,        //Interrupt Flags
           D_MemToInt, D_IOToInt, //Data Into IDP
           Addr,  D_OUT,          //Data going to Memory
           dm_cs, dm_rd, dm_wr,   //Data Memory Flags
           io_cs, io_rd, io_wr    //IO Module Flags
           );
   input         clk, reset, intr;
   input  [31:0] D_MemToInt, D_IOToInt;
   output        int_ack;
   output [31:0] Addr, D_OUT;
   output        dm_cs, dm_rd, dm_wr;
   output        io_cs, io_rd, io_wr;
   
   //Wires
	wire        N, Z, C, V;
   wire [31:0] IR_out;
   wire [31:0] PC_IUtoID, SE_16;
   wire [31:0] DY;               //Added for Rev 1.2
   
   //MCU control words(control words of state machine)
   wire [4:0] FS;                //5-bit control word
   wire [2:0] Y_Sel;             //3-bit control word
   wire [1:0] pc_sel, DA_sel;    //2-bit control words
   wire pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr, 
        D_En, T_sel, HILO_LD;
        
   //Added for Rev 1.2
   wire M_sel;
   
   //Added for Rev 1.3
   wire [31:0] D_val;      //D_OUT of Datapath
   wire  [1:0] stat_sel;   //0 - D_val from IDP, 1 - PC, 2 - Status Flags
   wire        S_sel;      //0 - S from RegFile, 1 - Y_lo from ALU
   wire [31:0] D_in;       //D_in register from IDP to the CU
   
	/****************************************************************
    *  Instantiate Control Unit, Instruction Unit and Datapath
    ***************************************************************/
    
   //Control Unit
   MCU      mips_ctrl(
                      .sys_clk(clk), .reset(reset),//Clock and Reset
                      .intr(intr),                 //Interrupt Request
                      .c(C), .n(N), .z(Z), .v(V),  //ALU status Flags
                      .IR(IR_out),                 //Instruction Register input
                      .int_ack(int_ack),           //output to I/O subsystem
                      .FS(FS),                     //Function Select
                      .ir_ld(ir_ld),               //IR Laod Enable
                      .pc_sel(pc_sel),             //  \
                      .pc_ld(pc_ld),               // --> PC Flags
                      .pc_inc(pc_inc),             //  /
                      .im_cs(im_cs),               //  \
                      .im_rd(im_rd),               // --> Instruction Memory Flags
                      .im_wr(im_wr),               //  /
                      .D_En(D_En),                 //  \
                      .DA_sel(DA_sel),             //   \
                      .T_sel(T_Sel),               // ---> Datapath Flags
                      .HILO_ld(HILO_LD),           //   /
                      .Y_sel(Y_Sel),               //  /
                      .dm_cs(dm_cs),               //  \
                      .dm_rd(dm_rd),               // --> Data Memory Flags
                      .dm_wr(dm_wr),               //  /
                      .io_cs(io_cs),               //  \
                      .io_rd(io_rd),               // --> I/O Module Flags
                      .io_wr(io_wr),               //  /
                      .M_sel(M_sel),               //DM or IO Select
                      .stat_sel(stat_sel),         //Select for CPU Output type
                      .S_sel(S_sel),               //Select for register RS
                      .D_in(D_in)                  //Register D_in from IDP
                     );

   //Instruction Unit
   Instruction_Unit IU(
                      .clk(clk),  .reset(reset),   //Clock and Reset
                      .PC_in(Addr),                //Value to change PC
                      .ir_ld(ir_ld),               //IR Load Enable
                      .pc_sel(pc_sel),             //  \
                      .pc_ld(pc_ld),               // --> PC Flags
                      .pc_inc(pc_inc),             //  /
                      .im_cs(im_cs),               //  \
                      .im_rd(im_rd),               // --> Instruction Memory Flags
                      .im_wr(),                    //  /
                      .PC_out(PC_IUtoID),          //Current PC sending to Datapath
                      .IR_out(IR_out),             //Current IR sending to Datapath
                      .SE_16(SE_16)                //Sign-Extended IR[15:0]
                     );
   
   //Datapath
   Integer_Datapath
                 IDP (
                      .clk(clk),    .reset(reset), //Clock and Reset
                      .D_En(D_En),                 //Write Enable
                      .D_Addr(IR_out[15:11]),      //D - Address
                      .S_Addr(IR_out[25:21]),      //S - Address
                      .T_Addr(IR_out[20:16]),      //T - Address
                      .DT(SE_16),                  //Sign Extended IR[15:0]
                      .DA_sel(DA_sel),             //Register File Write Selector
                      .T_Sel(T_Sel),               //RT value Selector
                      .FS(FS),                     //Function Select
                      .N(N), .Z(Z), .C(C), .V(V),  //ALU Status Flags
                      .HILO_LD(HILO_LD),           //Enable for HI and LO
                      .DY(DY),                     //Value of Memory to D_in register
                      .PC_in(PC_IUtoID),           //PC value into the Datapath
                      .Y_Sel(Y_Sel),               //ALU_Out Selector
                      .ALU_OUT(Addr),              //Data Address output of CPU
                      .D_OUT(D_val),               //Data Value output of Datapath
                      .shift_val(IR_out[10:6]),    //Shift value for Barrel Shift
                      .S_sel(S_sel),               //Select for register RS
                      .D_in(D_in)                  //Register D_in to CU
                     );
                     
	// Select between Data Memory and IO Module
   // (0 - Data Memory, 1 - I/O)
   assign DY    = (M_sel == 0) ? D_MemToInt : D_IOToInt;   

   // Type of Data to send to memory
   assign D_OUT = (stat_sel == 2'b00) ? D_val      :                 //RT
                  (stat_sel == 2'b01) ? PC_IUtoID  :                 //PC
                  (stat_sel == 2'b10) ? {28'b0, intr, C, V, N, Z} :  //Status Flags
                   D_OUT;

endmodule
