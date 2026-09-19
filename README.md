# 6502 CPU cycle and bus accurate implementation with a synchronous bus

This project is part of the CompuSar project and the [Some Assembly Required](https://youtube.com/compusar) YouTube channel.

## Cycle and Bus accurate
This implementation carries out the same commands as an authentic 6502, having the same effect. Each command takes exactly the
same number of cycles to execute as an authentic 6502 (cycle accurate), during which it carries out exactly the same bus operations
as an authentic 6502 CPU would (bus accurate).

It's probably an overkill for your project. The "bus accurate" part is probably an overkill even for my project, but what can I say?
I like to be thorough.

### When is a cycle a cycle?
When discussing cycle and bus accuracy, it's important to understand that not all clock cycles count as "cycles". Only clock cycles with
a `bus_req_valid_o` set are counted, and those will arrive between every cycle and every 4 cycles. So unless an external moderator is
applied, actual execution speed will be vary.

Project CompuSar uses a [frequency divider](https://github.com/CompuSAR/compusar/blob/main/CompuSar.srcs/sources_1/new/freq_div_bus.sv)
as moderator to great effect.

See [this video](https://www.youtube.com/watch?v=and5Sfoy9t4) for more information as well as the reasoning for this move.

## Synchronous bus
The original 6502 employed an async bus. This project is deliberately incompatible with that. Instead, it employs a basic synchronous
bus with the following signals:
* `clock_i` - the clock.
* `nmi_i`, `irq_i`, `set_overflow_i` and `reset_i` - same meaning as per the 6502[^1]. Sampled on the rising edge of the clock.
* `bus_req_address_o` - address of bus operation
* `bus_req_write_o` - bus write operation if set[^1].
* `bus_req_valid_o` - valid bus cycle. The bus slave should look at the other fields **only** if both this signal and `bus_req_ack_i` are set.
  If they are not, this is not a valid bus cycle and the fields should be ignored. If `bus_req_valid_o` is clear, the other fields may actually
  contain garbage.
* `bus_req_ack_i` - this signal allows backpressure. If this signal is clear, the CPU will assume that the bus request was not accepted, and will
  continue to issue it in future cycles until it is accepted.
* `bus_rsp_valid_i` - Read requests are not served in the same cycle they are requested. They can be served in the next cycle after that. The CPU
  knows when a reply arrives when this signal is set. The actual read data is then available on the `bus_rsp_data_i` bus.
* `dbg_reg_*` - a reflection of the internal state of the relevant registers. Useful for a hardware debugger.

[^1]: But see the "no active low" note.

### No active low signals
One important different to notice is that, unlike an authentic 6502, non of the signals are active low. If the `reset_i` signal is high, the
CPU will be in reset. The same goes to the `bus_req_write_o` signal. If it's 1, this is a write operation.

## License
All code in the CompuSar project is licensed under the GPL-3 unless explicitly stated otherwise.
