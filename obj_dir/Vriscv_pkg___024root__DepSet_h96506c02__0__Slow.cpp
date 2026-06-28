// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vriscv_pkg.h for the primary calling header

#include "Vriscv_pkg__pch.h"
#include "Vriscv_pkg___024root.h"

VL_ATTR_COLD void Vriscv_pkg___024root___eval_static(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_static\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vriscv_pkg___024root___eval_final(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_final\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vriscv_pkg___024root___dump_triggers__stl(Vriscv_pkg___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vriscv_pkg___024root___eval_phase__stl(Vriscv_pkg___024root* vlSelf);

VL_ATTR_COLD void Vriscv_pkg___024root___eval_settle(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_settle\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vriscv_pkg___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("tests/unit/alu_tb.sv", 2, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vriscv_pkg___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vriscv_pkg___024root___dump_triggers__stl(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___dump_triggers__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

void Vriscv_pkg___024root___act_sequent__TOP__0(Vriscv_pkg___024root* vlSelf);

VL_ATTR_COLD void Vriscv_pkg___024root___eval_stl(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vriscv_pkg___024root___act_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vriscv_pkg___024root___eval_triggers__stl(Vriscv_pkg___024root* vlSelf);

VL_ATTR_COLD bool Vriscv_pkg___024root___eval_phase__stl(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___eval_phase__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vriscv_pkg___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vriscv_pkg___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vriscv_pkg___024root___dump_triggers__act(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___dump_triggers__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vriscv_pkg___024root___dump_triggers__nba(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___dump_triggers__nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vriscv_pkg___024root___ctor_var_reset(Vriscv_pkg___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vriscv_pkg__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vriscv_pkg___024root___ctor_var_reset\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->alu_tb__DOT__a = VL_RAND_RESET_I(32);
    vlSelf->alu_tb__DOT__b = VL_RAND_RESET_I(32);
    vlSelf->alu_tb__DOT__alu_op = VL_RAND_RESET_I(4);
    vlSelf->alu_tb__DOT__result = VL_RAND_RESET_I(32);
    }
