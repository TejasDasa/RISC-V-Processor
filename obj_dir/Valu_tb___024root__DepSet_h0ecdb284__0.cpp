// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Valu_tb.h for the primary calling header

#include "Valu_tb__pch.h"
#include "Valu_tb___024root.h"

VlCoroutine Valu_tb___024root___eval_initial__TOP__Vtiming__0(Valu_tb___024root* vlSelf);

void Valu_tb___024root___eval_initial(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_initial\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Valu_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
}

void Valu_tb___024root___act_sequent__TOP__0(Valu_tb___024root* vlSelf);

void Valu_tb___024root___eval_act(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        Valu_tb___024root___act_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Valu_tb___024root___act_sequent__TOP__0(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___act_sequent__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.alu_tb__DOT__result = ((8U & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                      ? ((4U & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                          ? 0U : ((2U 
                                                   & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                   ? 0U
                                                   : 
                                                  ((1U 
                                                    & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                    ? 
                                                   ((vlSelfRef.alu_tb__DOT__a 
                                                     < vlSelfRef.alu_tb__DOT__b)
                                                     ? 1U
                                                     : 0U)
                                                    : 
                                                   (VL_LTS_III(32, vlSelfRef.alu_tb__DOT__a, vlSelfRef.alu_tb__DOT__b)
                                                     ? 1U
                                                     : 0U))))
                                      : ((4U & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                          ? ((2U & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                              ? ((1U 
                                                  & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                  ? 
                                                 VL_SHIFTRS_III(32,32,5, vlSelfRef.alu_tb__DOT__a, 
                                                                (0x1fU 
                                                                 & vlSelfRef.alu_tb__DOT__b))
                                                  : 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  >> 
                                                  (0x1fU 
                                                   & vlSelfRef.alu_tb__DOT__b)))
                                              : ((1U 
                                                  & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                  ? 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  << 
                                                  (0x1fU 
                                                   & vlSelfRef.alu_tb__DOT__b))
                                                  : 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  ^ vlSelfRef.alu_tb__DOT__b)))
                                          : ((2U & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                              ? ((1U 
                                                  & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                  ? 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  | vlSelfRef.alu_tb__DOT__b)
                                                  : 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  & vlSelfRef.alu_tb__DOT__b))
                                              : ((1U 
                                                  & (IData)(vlSelfRef.alu_tb__DOT__alu_op))
                                                  ? 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  - vlSelfRef.alu_tb__DOT__b)
                                                  : 
                                                 (vlSelfRef.alu_tb__DOT__a 
                                                  + vlSelfRef.alu_tb__DOT__b)))));
}

void Valu_tb___024root___eval_nba(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Valu_tb___024root___act_sequent__TOP__0(vlSelf);
    }
}

void Valu_tb___024root___timing_resume(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___timing_resume\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Valu_tb___024root___eval_triggers__act(Valu_tb___024root* vlSelf);

bool Valu_tb___024root___eval_phase__act(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_phase__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Valu_tb___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Valu_tb___024root___timing_resume(vlSelf);
        Valu_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Valu_tb___024root___eval_phase__nba(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_phase__nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Valu_tb___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Valu_tb___024root___dump_triggers__nba(Valu_tb___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Valu_tb___024root___dump_triggers__act(Valu_tb___024root* vlSelf);
#endif  // VL_DEBUG

void Valu_tb___024root___eval(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Valu_tb___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("tests/unit/alu_tb.sv", 2, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelfRef.__VactIterCount))) {
#ifdef VL_DEBUG
                Valu_tb___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("tests/unit/alu_tb.sv", 2, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Valu_tb___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Valu_tb___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Valu_tb___024root___eval_debug_assertions(Valu_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Valu_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu_tb___024root___eval_debug_assertions\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
