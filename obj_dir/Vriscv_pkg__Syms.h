// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VRISCV_PKG__SYMS_H_
#define VERILATED_VRISCV_PKG__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vriscv_pkg.h"

// INCLUDE MODULE CLASSES
#include "Vriscv_pkg___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vriscv_pkg__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vriscv_pkg* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vriscv_pkg___024root           TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_alu_tb;

    // CONSTRUCTORS
    Vriscv_pkg__Syms(VerilatedContext* contextp, const char* namep, Vriscv_pkg* modelp);
    ~Vriscv_pkg__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
