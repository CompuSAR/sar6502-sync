function void handle_op_branch();
    case( instruction_counter )
        C_ADDR1: begin
            control_signals_o[ctl::I_PC] = 1'b1;

            if( condtion_flag != instruction_register[5] )
                new_instruction();
        end
        C_ADDR2: begin
            sb_src_o = ctl::DL_SB;
            alu_b_src_o = ctl::ADL_ADD;
            adl_src_o = ctl::PCL_ADL;

            alu_op_o = ctl::SUMS;

            addr_out_pc();
        end
        C_ADDR3: begin
            adl_src_o = ctl::ADD_ADL;
            control_signals_o[ctl::ADL_PCL] = 1'b1;
            control_signals_o[ctl::DL_DL] = 1'b1;

            if( !dl7_i && !alu_acr || dl7_i && alu_acr )
                new_instruction();

            adh_src_o = ctl::PCH_ADH;
        end
        C_ADDR4: begin
            addr_out_pc();

            sb_src_o = ctl::ADH_SB;
            db_src_o = ctl::O_DB;

            if( dl7_i ) begin
                // Negative offset
                control_signals_o[ctl::I_ADDC] = 1'b0;
                alu_b_src_o = ctl::DBB_ADD;
            end else begin
                // Positive offset
                control_signals_o[ctl::I_ADDC] = 1'b1;
                alu_b_src_o = ctl::DB_ADD;
            end

            alu_op_o = ctl::SUMS;
        end
        C_ADDR5: begin
            sb_src_o = ctl::ADD_SB;
            adh_src_o = ctl::SB_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_brk();
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

function void handle_op_jmp();
    if( addr_cycle() ) begin
        control_signals_o[ctl::ADL_PCL] = control_signals_o[ctl::ADL_ABL];
        control_signals_o[ctl::ADH_PCH] = control_signals_o[ctl::ADH_ABH];
        if( control_signals_o[ctl::ADL_PCL] )
            control_signals_o[ctl::I_PC] = 1'b0;

        if( addr_load_value )
            bus_req_valid_o = 1'b0;
    end else begin
        new_instruction();
    end
endfunction

function void handle_op_jsr();
    case( instruction_counter )
        C_ADDR1: begin
            advance_pc(); 

            addr_out_stack( 1'b0 );
        end
        C_ADDR2: begin
            decrease_sp();

            control_signals_o[ctl::DL_DL] = 1'b1;       // Don't store the value
        end
        C_ADDR3: begin
            addr_out_stack( 1'b1 );

            db_src_o = ctl::PCH_DB;

            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR4: begin
            addr_out_stack( 1'b1 );

            db_src_o = ctl::PCL_DB;
        end
        C_ADDR5: begin
            decrease_sp();

            addr_out_pc();
        end
        C_ADDR6: begin
            control_signals_o[ctl::ADL_PCL] = 1'b1;
            adl_src_o = ctl::DL_ADL;

            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR7: begin
            adh_src_o = ctl::DL_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_lda();
    if( !addr_cycle() ) begin
        case( instruction_counter )
            C_OP1: begin
                sb_src_o = ctl::DL_SB;
                control_signals_o[ctl::SB_AC] = 1'b1;

                new_instruction();
            end
            default: set_invalid_state();
        endcase
    end
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

function void handle_op_nop();
    case( instruction_counter )
        C_ADDR1: begin
            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_pha();
    case( instruction_counter )
        C_ADDR1: begin
            sb_src_o = ctl::AC_SB;
            db_src_o = ctl::SB_DB;
            bus_req_write_o = 1'b1;

            adl_src_o = ctl::S_ADL;
            control_signals_o[ctl::ADL_ABL] = 1'b1;

            adh_src_o = ctl::GEN_ADH;
            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b1;
            control_signals_o[ctl::ADH_ABH] = 1'b1;

            bus_req_valid_o = 1'b1;
        end
        C_ADDR2: begin
            db_src_o = ctl::O_DB;
            alu_b_src_o = ctl::DBB_ADD;
            sb_src_o = ctl::S_SB;

            alu_op_o = ctl::SUMS;
            control_signals_o[ctl::DAA] = 1'b0;
            control_signals_o[ctl::I_ADDC] = 1'b0;
        end
        C_ADDR3: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_php();
    case( instruction_counter )
        C_ADDR1: begin
            addr_out_stack( 1'b1 );

            db_src_o = ctl::P_DB;
        end
        C_ADDR2: begin
            decrease_sp();
        end
        C_ADDR3: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_plp();
    case( instruction_counter )
        C_ADDR1: begin
            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR2: begin
            addr_out_stack( 1'b0 );
            adl_src_o = ctl::ADD_ADL;
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR3: begin
        end
        C_ADDR4: begin
            db_src_o = ctl::DL_DB;

            control_signals_o[ctl::DB0_C] = 1'b1;
            control_signals_o[ctl::DB1_Z] = 1'b1;
            control_signals_o[ctl::DB2_I] = 1'b1;
            control_signals_o[ctl::DB3_D] = 1'b1;
            control_signals_o[ctl::DB6_V] = 1'b1;
            control_signals_o[ctl::DB7_N] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_rti();
    case( instruction_counter )
        C_ADDR1: begin
            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR2: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR3: begin
            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR4: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR5: begin
            db_src_o = ctl::DL_DB;
            control_signals_o[ctl::DB0_C] = 1'b1;
            control_signals_o[ctl::DB1_Z] = 1'b1;
            control_signals_o[ctl::DB2_I] = 1'b1;
            control_signals_o[ctl::DB3_D] = 1'b1;
            control_signals_o[ctl::DB6_V] = 1'b1;
            control_signals_o[ctl::DB7_N] = 1'b1;

            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR6: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR7: begin
            adl_src_o = ctl::DL_ADL;
            control_signals_o[ctl::ADL_PCL] = 1'b1;
        end
        C_ADDR8: begin
            addr_out_stack( 1'b0 );
        end
        C_ADDR9: begin
        end
        C_ADDR10: begin
            adh_src_o = ctl::DL_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_rts();
    case( instruction_counter )
        C_ADDR1: begin
            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR2: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR3: begin
            addr_out_stack( 1'b0 );
            increase_sp();
        end
        C_ADDR4: begin
            sb_src_o = ctl::ADD_SB;
            control_signals_o[ctl::SB_S] = 1'b1;
        end
        C_ADDR5: begin
            adl_src_o = ctl::DL_ADL;
            control_signals_o[ctl::ADL_PCL] = 1'b1;
        end
        C_ADDR6: begin
            addr_out_stack( 1'b0 );
        end
        C_ADDR7: begin
        end
        C_ADDR8: begin
            adh_src_o = ctl::DL_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;
        end
        C_ADDR9: begin
            addr_out_pc();
            advance_pc();

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_txs();
    case( instruction_counter )
        C_ADDR1: begin
            sb_src_o = ctl::X_SB;
            control_signals_o[ctl::SB_S] = 1'b1;

            new_instruction();
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_op_set_flag();
    case( instruction_register[7:6] )
        2'b00: control_signals_o[ctl::IR5_C] = 1'b1;
        2'b01: control_signals_o[ctl::IR5_I] = 1'b1;
        2'b11: control_signals_o[ctl::IR5_D] = 1'b1;
    endcase

    new_instruction();
endfunction

function void handle_op_clv();
    sb_src_o = ctl::O_SB;
    db_src_o = ctl::SB_DB;
    control_signals_o[ctl::DB6_V] = 1'b1;

    new_instruction();
endfunction
