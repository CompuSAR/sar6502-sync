
function void handle_op_brk();
    $display("handle_op_brk cycle %s", instruction_counter.name());
    case( instruction_counter )
        C_ADDR1: begin
            adl_src_o = ctl::GEN_ADL;
            control_signals_o[ctl::O_ADL_0] = 1'b1;
            control_signals_o[ctl::O_ADL_1] = 1'b1;
            control_signals_o[ctl::O_ADL_2] = 1'b0;

            adh_src_o = ctl::GEN_ADH;
            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b0;

            bus_req_valid_o = 1'b1;
            control_signals_o[ctl::ADH_ABH] = 1'b1;
            control_signals_o[ctl::ADL_ABL] = 1'b1;
        end
        C_ADDR2: begin end
        C_ADDR3: begin
            adl_src_o = ctl::DL_ADL;
            control_signals_o[ctl::ADL_PCL] = 1'b1;
        end
        C_ADDR4: begin
            adl_src_o = ctl::GEN_ADL;
            control_signals_o[ctl::O_ADL_0] = 1'b0;
            control_signals_o[ctl::O_ADL_1] = 1'b1;
            control_signals_o[ctl::O_ADL_2] = 1'b0;

            adh_src_o = ctl::GEN_ADH;
            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b0;

            bus_req_valid_o = 1'b1;
            control_signals_o[ctl::ADH_ABH] = 1'b1;
            control_signals_o[ctl::ADL_ABL] = 1'b1;
        end
        C_ADDR5: begin end
        C_ADDR6: begin
            new_instruction();

            adh_src_o = ctl::DL_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_ldx();
    if( !addr_cycle() ) begin
        case( instruction_counter )
            C_OP1: begin
                sb_src_o = ctl::DL_SB;
                control_signals_o[ctl::SB_X] = 1'b1;

                new_instruction();
            end
            default: set_invalid_state();
        endcase
    end
endfunction
