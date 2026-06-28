// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vriscv_pkg.h for the primary calling header

#include "Vriscv_pkg__pch.h"
#include "Vriscv_pkg__Syms.h"
#include "Vriscv_pkg___024root.h"

void Vriscv_pkg___024root___ctor_var_reset(Vriscv_pkg___024root* vlSelf);

Vriscv_pkg___024root::Vriscv_pkg___024root(Vriscv_pkg__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vriscv_pkg___024root___ctor_var_reset(this);
}

void Vriscv_pkg___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vriscv_pkg___024root::~Vriscv_pkg___024root() {
}
