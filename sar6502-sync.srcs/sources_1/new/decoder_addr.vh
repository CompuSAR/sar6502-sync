
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

function void handle_addr_abs();
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();
            end
            C_ADDR2: begin
                addr_out_pc();
            end
            C_ADDR3: begin
                adl_src_o = ctl::DL_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;
                advance_pc();
            end
            C_ADDR4: begin
                adh_src_o = ctl::DL_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                addr_load_value = 1'b1;
            end
            C_ADDR5: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

function void handle_addr_zp();
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();
            end
            C_ADDR2: begin
                adl_src_o = ctl::DL_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                control_signals_o[ctl::O_ADH_0] = 1'b1;
                control_signals_o[ctl::O_ADH_1_7] = 1'b1;
                adh_src_o = ctl::GEN_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;

                addr_load_value = 1'b1;
            end
            C_ADDR3: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

