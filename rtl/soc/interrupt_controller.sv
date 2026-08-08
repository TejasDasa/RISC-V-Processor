module interrupt_controller (
    input logic timer_irq,
    output logic cpu_irq
);

assign cpu_irq = timer_irq;

endmodule
