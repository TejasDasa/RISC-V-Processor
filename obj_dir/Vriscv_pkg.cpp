// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vriscv_pkg__pch.h"

//============================================================
// Constructors

Vriscv_pkg::Vriscv_pkg(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vriscv_pkg__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vriscv_pkg::Vriscv_pkg(const char* _vcname__)
    : Vriscv_pkg(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vriscv_pkg::~Vriscv_pkg() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vriscv_pkg___024root___eval_debug_assertions(Vriscv_pkg___024root* vlSelf);
#endif  // VL_DEBUG
void Vriscv_pkg___024root___eval_static(Vriscv_pkg___024root* vlSelf);
void Vriscv_pkg___024root___eval_initial(Vriscv_pkg___024root* vlSelf);
void Vriscv_pkg___024root___eval_settle(Vriscv_pkg___024root* vlSelf);
void Vriscv_pkg___024root___eval(Vriscv_pkg___024root* vlSelf);

void Vriscv_pkg::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vriscv_pkg::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vriscv_pkg___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vriscv_pkg___024root___eval_static(&(vlSymsp->TOP));
        Vriscv_pkg___024root___eval_initial(&(vlSymsp->TOP));
        Vriscv_pkg___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vriscv_pkg___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vriscv_pkg::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vriscv_pkg::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vriscv_pkg::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vriscv_pkg___024root___eval_final(Vriscv_pkg___024root* vlSelf);

VL_ATTR_COLD void Vriscv_pkg::final() {
    Vriscv_pkg___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vriscv_pkg::hierName() const { return vlSymsp->name(); }
const char* Vriscv_pkg::modelName() const { return "Vriscv_pkg"; }
unsigned Vriscv_pkg::threads() const { return 1; }
void Vriscv_pkg::prepareClone() const { contextp()->prepareClone(); }
void Vriscv_pkg::atClone() const {
    contextp()->threadPoolpOnClone();
}
