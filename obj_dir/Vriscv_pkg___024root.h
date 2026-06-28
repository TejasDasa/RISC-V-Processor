// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vriscv_pkg.h for the primary calling header

#ifndef VERILATED_VRISCV_PKG___024ROOT_H_
#define VERILATED_VRISCV_PKG___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vriscv_pkg__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vriscv_pkg___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*3:0*/ alu_tb__DOT__alu_op;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ alu_tb__DOT__a;
    IData/*31:0*/ alu_tb__DOT__b;
    IData/*31:0*/ alu_tb__DOT__result;
    IData/*31:0*/ __VactIterCount;
    VlDelayScheduler __VdlySched;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vriscv_pkg__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vriscv_pkg___024root(Vriscv_pkg__Syms* symsp, const char* v__name);
    ~Vriscv_pkg___024root();
    VL_UNCOPYABLE(Vriscv_pkg___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
