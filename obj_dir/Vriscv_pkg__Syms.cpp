// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vriscv_pkg__pch.h"
#include "Vriscv_pkg.h"
#include "Vriscv_pkg___024root.h"

// FUNCTIONS
Vriscv_pkg__Syms::~Vriscv_pkg__Syms()
{
}

Vriscv_pkg__Syms::Vriscv_pkg__Syms(VerilatedContext* contextp, const char* namep, Vriscv_pkg* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(18);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_alu_tb.configure(this, name(), "alu_tb", "alu_tb", "<null>", -12, VerilatedScope::SCOPE_OTHER);
}
