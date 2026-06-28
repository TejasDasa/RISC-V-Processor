// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VALU_TB__SYMS_H_
#define VERILATED_VALU_TB__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Valu_tb.h"

// INCLUDE MODULE CLASSES
#include "Valu_tb___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Valu_tb__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Valu_tb* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Valu_tb___024root              TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_alu_tb;

    // CONSTRUCTORS
    Valu_tb__Syms(VerilatedContext* contextp, const char* namep, Valu_tb* modelp);
    ~Valu_tb__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
