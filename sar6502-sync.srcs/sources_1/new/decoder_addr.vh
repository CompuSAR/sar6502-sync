
function void handle_addr_imm();
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();

                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction
