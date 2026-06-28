// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vriscv_pkg.h for the primary calling header

#include "Vriscv_pkg__pch.h"
#include "Vriscv_pkg__Syms.h"
#include "Vriscv_pkg___024root.h"

VL_INLINE_OPT VlCoroutine Vriscv_pkg___024root___eval_initial__TOP__Vtiming__0(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_initial__TOP__Vtiming__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.alu_tb__DOT__a = 5U;
    vlSelfRef.alu_tb__DOT__b = 7U;
    vlSelfRef.alu_tb__DOT__alu_op = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "tests/unit/alu_tb.sv", 
                                         22);
    if (VL_UNLIKELY((0xcU != vlSelfRef.alu_tb__DOT__result))) {
        VL_WRITEF_NX("[%0t] %%Error: alu_tb.sv:25: Assertion failed in %Nalu_tb: ADD failed: expected 12, got %0#\n",0,
                     64,VL_TIME_UNITED_Q(1),-12,vlSymsp->name(),
                     32,vlSelfRef.alu_tb__DOT__result);
        VL_STOP_MT("tests/unit/alu_tb.sv", 25, "");
    }
    vlSelfRef.alu_tb__DOT__a = 7U;
    vlSelfRef.alu_tb__DOT__b = 5U;
    vlSelfRef.alu_tb__DOT__alu_op = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "tests/unit/alu_tb.sv", 
                                         31);
    if (VL_UNLIKELY((2U != vlSelfRef.alu_tb__DOT__result))) {
        VL_WRITEF_NX("[%0t] %%Error: alu_tb.sv:34: Assertion failed in %Nalu_tb: SUB failed: expected 2, got %0#\n",0,
                     64,VL_TIME_UNITED_Q(1),-12,vlSymsp->name(),
                     32,vlSelfRef.alu_tb__DOT__result);
        VL_STOP_MT("tests/unit/alu_tb.sv", 34, "");
    }
    VL_WRITEF_NX("ALU basic tests finished\n",0);
    VL_FINISH_MT("tests/unit/alu_tb.sv", 38, "");
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vriscv_pkg___024root___dump_triggers__act(Vriscv_pkg___024root* vlSelf);
#endif  // VL_DEBUG

void Vriscv_pkg___024root___eval_triggers__act(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_triggers__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.set(0U, vlSelfRef.__VdlySched.awaitingCurrentTime());
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vriscv_pkg___024root___dump_triggers__act(vlSelf);
    }
#endif
}
