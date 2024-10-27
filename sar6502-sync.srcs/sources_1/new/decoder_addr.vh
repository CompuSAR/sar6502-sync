
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

function void handle_addr_abs_x(input unconditional_extra_cycle);
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();
            end
            C_ADDR2: begin
                addr_out_pc();
                advance_pc();

                // Add X to PCL
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::X_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR3: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;
            end
            C_ADDR4: begin
                adh_src_o = ctl::DL_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;

                // Speculatively add carry to ADH address
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::O_SB;
                alu_op_o = ctl::SUMS;
                control_signals_o[ctl::I_ADDC] = alu_acr_delayed_i;

                if( !alu_acr_delayed_i && !unconditional_extra_cycle ) begin
                    instruction_counter_next = C_ADDR6;
                    addr_load_value = 1'b1;
                end
            end
            C_ADDR5: begin
                sb_src_o = ctl::ADD_SB;
                adh_src_o = ctl::SB_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                addr_load_value = 1'b1;
            end
            C_ADDR6: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

function void handle_addr_abs_y(input unconditional_extra_cycle);
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();
            end
            C_ADDR2: begin
                addr_out_pc();
                advance_pc();

                // Add Y to PCL
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::Y_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR3: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;
            end
            C_ADDR4: begin
                adh_src_o = ctl::DL_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;

                // Speculatively add carry to ADH address
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::O_SB;
                alu_op_o = ctl::SUMS;
                control_signals_o[ctl::I_ADDC] = alu_acr_delayed_i;

                if( !alu_acr_delayed_i && !unconditional_extra_cycle ) begin
                    instruction_counter_next = C_ADDR6;
                    addr_load_value = 1'b1;
                end
            end
            C_ADDR5: begin
                sb_src_o = ctl::ADD_SB;
                adh_src_o = ctl::SB_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                addr_load_value = 1'b1;
            end
            C_ADDR6: begin
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

function void handle_addr_zp_ind_y(input unconditional_extra_cycle);
    if( addr_cycle() ) begin
        case( instruction_counter )
            C_ADDR1: begin
                advance_pc();
            end
            C_ADDR2: begin
                // Load LSB from zp
                adl_src_o = ctl::DL_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                control_signals_o[ctl::O_ADH_0] = 1'b1;
                control_signals_o[ctl::O_ADH_1_7] = 1'b1;
                adh_src_o = ctl::GEN_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;

                // Advance DL to get MSB address
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::O_SB;
                alu_op_o = ctl::SUMS;
                control_signals_o[ctl::I_ADDC] = 1'b1;
            end
            C_ADDR3: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                bus_req_valid_o = 1'b1;
            end
            C_ADDR4: begin
                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::Y_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR5: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;
                adh_src_o = ctl::DL_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;

                if( !alu_acr_i && !unconditional_extra_cycle ) begin
                    addr_load_value = 1'b1;
                    instruction_counter_next = C_ADDR7;
                end else begin
                    db_src_o = ctl::DL_DB;
                    alu_b_src_o = ctl::DB_ADD;
                    sb_src_o = ctl::O_SB;
                    alu_op_o = ctl::SUMS;
                    control_signals_o[ctl::I_ADDC] = alu_acr_i;
                end
            end
            C_ADDR6: begin
                sb_src_o = ctl::ADD_SB;
                adh_src_o = ctl::SB_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                addr_load_value = 1'b1;
            end
            C_ADDR7: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

function void handle_addr_zp_x();
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

                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::X_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR3: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;
                addr_load_value = 1'b1;
            end
            C_ADDR4: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

function void handle_addr_zp_x_ind();
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

                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::X_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR3: begin
                // Read real operand's address LSB
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;

                // Add 1 to previous address so we can read the real operand's
                // address MSB
                sb_src_o = ctl::ADD_SB;
                db_src_o = ctl::O_DB;
                alu_b_src_o = ctl::DB_ADD;
                control_signals_o[ctl::I_ADDC] = 1'b1;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR4: begin
                // Read real operands's address MSB
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;
            end
            C_ADDR5: begin
                // Operand's address LSB is in DL
                adl_src_o = ctl::DL_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;
            end
            C_ADDR6: begin
                // Operand's address MSB is in DL
                adh_src_o = ctl::DL_ADH;
                control_signals_o[ctl::ADH_ABH] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;
                addr_load_value = 1'b1;
            end
            C_ADDR7: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

function void handle_addr_zp_y();
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

                db_src_o = ctl::DL_DB;
                alu_b_src_o = ctl::DB_ADD;
                sb_src_o = ctl::Y_SB;
                alu_op_o = ctl::SUMS;
            end
            C_ADDR3: begin
                adl_src_o = ctl::ADD_ADL;
                control_signals_o[ctl::ADL_ABL] = 1'b1;

                bus_req_valid_o = 1'b1;
                bus_req_write_o = 1'b0;
                addr_load_value = 1'b1;
            end
            C_ADDR4: begin
                instruction_counter_next = C_OP1;
            end
            default: set_invalid_state();
        endcase
    end
endfunction

