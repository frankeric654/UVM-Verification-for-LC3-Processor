//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
// This file contains defines and typedefs to be compiled for use in
// the simulation running on the emulator when using Veloce.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
                                                                               

typedef enum bit [3:0] { IMEM_BR = 4'h0, IMEM_ADD = 4'h1, IMEM_LD = 4'h2, IMEM_ST = 4'h3, IMEM_JSR = 4'h4, IMEM_AND = 4'h5, IMEM_LDR = 4'h6, IMEM_STR = 4'h7, IMEM_RTI = 4'h8, IMEM_NOT = 4'h9, IMEM_LDI = 4'hA, IMEM_STI = 4'hB, IMEM_JMP = 4'hC, IMEM_RESERVED = 4'hD, IMEM_LEA = 4'hE, IMEM_TRAP = 4'hF } imem_opcode_e;

// pragma uvmf custom additional begin
// pragma uvmf custom additional end

