// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Valu_tb__pch.h"

//============================================================
// Constructors

Valu_tb::Valu_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Valu_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Valu_tb::Valu_tb(const char* _vcname__)
    : Valu_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Valu_tb::~Valu_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Valu_tb___024root___eval_debug_assertions(Valu_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Valu_tb___024root___eval_static(Valu_tb___024root* vlSelf);
void Valu_tb___024root___eval_initial(Valu_tb___024root* vlSelf);
void Valu_tb___024root___eval_settle(Valu_tb___024root* vlSelf);
void Valu_tb___024root___eval(Valu_tb___024root* vlSelf);

void Valu_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Valu_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Valu_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Valu_tb___024root___eval_static(&(vlSymsp->TOP));
        Valu_tb___024root___eval_initial(&(vlSymsp->TOP));
        Valu_tb___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Valu_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Valu_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Valu_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Valu_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Valu_tb___024root___eval_final(Valu_tb___024root* vlSelf);

VL_ATTR_COLD void Valu_tb::final() {
    Valu_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Valu_tb::hierName() const { return vlSymsp->name(); }
const char* Valu_tb::modelName() const { return "Valu_tb"; }
unsigned Valu_tb::threads() const { return 1; }
void Valu_tb::prepareClone() const { contextp()->prepareClone(); }
void Valu_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
