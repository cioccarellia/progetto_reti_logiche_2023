----------------------------------------------------------------------------------
-- Students: Alberto Cantele (10766393), Andrea Cioccarelli (10713858)
-- Create Date: 02/20/2023 11:36:44 AM
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------
--|
--|  project_reti_logiche
--|
----------------------------------------------------------------------------------


library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
    port(
        i_clk:          in  std_logic;
        i_rst:          in  std_logic;
        i_start:        in  std_logic;
        i_w:            in  std_logic;
        
        o_z0:           out std_logic_vector(7  downto 0);
        o_z1:           out std_logic_vector(7  downto 0);
        o_z2:           out std_logic_vector(7  downto 0);
        o_z3:           out std_logic_vector(7  downto 0);
        o_done:         out std_logic;
        
        o_mem_addr:     out std_logic_vector(15 downto 0);
        i_mem_data:     in  std_logic_vector(7  downto 0);
        o_mem_we:       out std_logic;
        o_mem_en:       out std_logic
    );
end project_reti_logiche;



architecture proj_impl of project_reti_logiche is

    --| segnali di controllo (da demux a registri)
    signal control_demux_to_reg_z0: std_logic_vector(7 downto 0);
    signal control_demux_to_reg_z1: std_logic_vector(7 downto 0);
    signal control_demux_to_reg_z2: std_logic_vector(7 downto 0);
    signal control_demux_to_reg_z3: std_logic_vector(7 downto 0);
    
    --| segnali di controllo (da registri a porte and e uscite)
    signal control_reg_to_out_z0: std_logic_vector(7 downto 0);
    signal control_reg_to_out_z1: std_logic_vector(7 downto 0);
    signal control_reg_to_out_z2: std_logic_vector(7 downto 0);
    signal control_reg_to_out_z3: std_logic_vector(7 downto 0);



    --| Stato della FSM che modella l'esecuzione del processo.
    --| Ci sono 4 stati possibili: 
    --| - WAIT_START: Stato di idle
    --| - READ_ADDR: Si legge bit per bit l'ingresso w e si salva il valore
    --| - ASK_MEM: Si inviano i segnali alla RAM e si aspetta perche processi la richiesta, 1cc
    --| - OUTPUT: Fase di output, 1cc
    type FSM_S is (WAIT_START, READ_ADDR, ASK_MEM, OUTPUT);
    signal current_state: FSM_S;



    --| Stato della FSM che modella la lettura del segnale di controllo output e dell'indirizzo di memoria.
    --| - S0: Lettura del primo bit di controllo uscita
    --| - S1: Lettura del secondo bit di controllo uscita
    --| - S_READ: Lettura dei singoli bit dell'indirizzo
    type FSM_S_READ is (S0, S1, S_READ);
    signal current_state_reader: FSM_S_READ;



    --| Segnali di supporto alla lettura dell indirizzo di ingresso
    signal control_output:          std_logic_vector(1  downto 0);
    signal control_address:         std_logic_vector(15 downto 0);
    signal control_done_enable:     std_logic;
    



    --| Componente di registro a 8 bit
    component REG_OUT_8_BIT is
        port(
            clk:            in  std_logic;
            rst:            in  std_logic;
            data_in:        in  std_logic_vector(7 downto 0);
            data_out:       out std_logic_vector(7 downto 0)
        );
    end component;
begin

    ---- istanza del componente di registro a 8 bit
    R0: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, data_in => control_demux_to_reg_z0, data_out => control_reg_to_out_z0);
    R1: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, data_in => control_demux_to_reg_z1, data_out => control_reg_to_out_z1);
    R2: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, data_in => control_demux_to_reg_z2, data_out => control_reg_to_out_z2);
    R3: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, data_in => control_demux_to_reg_z3, data_out => control_reg_to_out_z3);
    


    --| FSM per gestire lo stato del programma al variare dei segnali di clock (i_clk) e reset (i_rst)
    --| Si occupa di ricevere il segnale di reset (i_rst) ed impostare i valori allo stato iniziale
    --| Inoltre, fa commutare gli stati
    fsm: process(i_clk, i_rst)
    begin 
        if (i_rst='1') then
            --------| reset di tutti i segnali al loro vaalore iniziale
            --| impostiamo i segnali e gli stati
            current_state <= WAIT_START;                -- stato iniziale di wait for start

            control_output <= "00";                     -- 2  bits of zeros
            control_address <= (others => '0');         -- 16 bits of zeros

            --! i registri sono collegati a i_rst quindi si resettano autonomamente.
            control_demux_to_reg_z0 <= "00000000";
            control_demux_to_reg_z1 <= "00000000";
            control_demux_to_reg_z2 <= "00000000";
            control_demux_to_reg_z3 <= "00000000";




            --------| impostiamo le uscite al loro valore di default
            o_mem_addr <= (others => '0');              -- 16 bits of zeros
            o_mem_en <= '0';
            o_mem_we <= '0';

            o_done <= '0';
            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";


        elsif (rising_edge(i_clk)) then   
            case current_state is
                when WAIT_START =>
                    if i_start='1' then
                        current_state <= READ_ADDR;
                    end if;

                when READ_ADDR =>
                    if i_start='0' then
                        current_state <= ASK_MEM;
                    end if;

                when ASK_MEM =>
                    -- la RAM ci mette 1cc per recuperare il valore, e poi assumo di avere il dato su i_mem_data
                    current_state <= OUTPUT;

                when OUTPUT =>
                    --!!FIXME!! probabilmente è meglio impostare questo direttamente in fsm_output, e non qui, perchè non ci metto solo 1cc
                    current_state <= WAIT_START;
            end case;
        end if;
    end process;





    fsm0: process(current_state, i_clk)
    begin
        --------| Inizialmente imposto i valori di uscita a default
        --o_mem_addr <= (others => '0');              
        o_mem_en <= '0';
        o_mem_we <= '0';

        o_done <= '0';
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";

        case current_state is
            when WAIT_START =>
            when READ_ADDR =>
            when ASK_MEM =>
                o_mem_en <= '1';
            when OUTPUT =>

        end case;
    end process;






    ---- FSM per gestire i valori di uscita
    ---- dipende solo dallo stato corrente (current_state) e si occupa di 
    fsm_output: process(current_state)
    begin
        case current_state is
            when WAIT_START | READ_ADDR | ASK_MEM =>
                o_done <= '0';
                control_done_enable <= '0';

                o_z0 <= "00000000";
                o_z1 <= "00000000";
                o_z2 <= "00000000";
                o_z3 <= "00000000";

            when OUTPUT =>
               --| si puo usare un bel:   case (control_output) is
                if control_output = "00" then
                    control_demux_to_reg_z0 <= i_mem_data;
                    control_demux_to_reg_z1 <= "UUUUUUUU";
                    control_demux_to_reg_z2 <= "UUUUUUUU";
                    control_demux_to_reg_z3 <= "UUUUUUUU";
                elsif control_output = "01" then
                    control_demux_to_reg_z0 <= "UUUUUUUU";
                    control_demux_to_reg_z1 <= i_mem_data;
                    control_demux_to_reg_z2 <= "UUUUUUUU";
                    control_demux_to_reg_z3 <= "UUUUUUUU";
                elsif control_output = "10" then
                    control_demux_to_reg_z0 <= "UUUUUUUU";
                    control_demux_to_reg_z1 <= "UUUUUUUU"; 
                    control_demux_to_reg_z2 <= i_mem_data;
                    control_demux_to_reg_z3 <= "UUUUUUUU";
                elsif control_output = "11" then
                    control_demux_to_reg_z0 <= "UUUUUUUU";
                    control_demux_to_reg_z1 <= "UUUUUUUU"; 
                    control_demux_to_reg_z2 <= "UUUUUUUU";
                    control_demux_to_reg_z3 <= i_mem_data;
                end if;
                
              
                   
                --| control_demux_to_reg_z0 <=  i_mem_data when control_output = "00" else
                --|                             "UUUUUUUU"; --| by default 
                --| control_demux_to_reg_z1 <=  i_mem_data when control_output = "01" else
                --|                             "UUUUUUUU"; --| by default 
                --| control_demux_to_reg_z2 <=  i_mem_data when control_output = "10" else
                --|                             "UUUUUUUU"; --| by default 
                --| control_demux_to_reg_z3 <=  i_mem_data when control_output = "11" else
                --|                             "UUUUUUUU"; --| by default 
                 
                

                -- output
                o_done <= '1';
                control_done_enable <= '1';
                

                if (control_done_enable = '1') then
                    o_z0 <= control_reg_to_out_z0 and "11111111";
                    o_z1 <= control_reg_to_out_z1 and "11111111";
                    o_z2 <= control_reg_to_out_z2 and "11111111";
                    o_z3 <= control_reg_to_out_z3 and "11111111";
                elsif control_done_enable = '0' then
                    o_z0 <= control_reg_to_out_z0 and "00000000";
                    o_z1 <= control_reg_to_out_z1 and "00000000";
                    o_z2 <= control_reg_to_out_z2 and "00000000";
                    o_z3 <= control_reg_to_out_z3 and "00000000";
                end if;
                
                
                
           end case;
    end process;


    ---- FSM per scansione dell'input e letura in memoria
    fsm_scan_read: process(current_state, current_state_reader)
    begin
        case current_state is
            when WAIT_START =>
                control_address <= (others => '0');

            when READ_ADDR =>
                -- implementazione multiplexer scelta del canale di uscita 
                case current_state_reader is
                    when S0 =>
                        if rising_edge(i_clk) then
                            control_output(1) <= i_w;
                        end if;
                        current_state_reader<=S1;

                    when S1 =>    
                        if rising_edge(i_clk) then
                            control_output(0) <= i_w;
                        end if;
                        current_state_reader <= S_READ;

                    when S_read =>
                        -- Estensione del vettore a 16 bit: shifto a sx 15 bit in and con i_w
                        if rising_edge(i_clk) then
                            control_address <= control_address(14 downto 0) & i_w; -- & concatena, and è logica
                            control_address(0) <= i_w;
                        end if;
                        current_state_reader <= S_READ;
                    
                end case;
            when ASK_MEM =>
                -- abilitazione lettura in memoria
                o_mem_addr <= control_address;
                
            --lettura in memoria e acquisizione dato
            when OUTPUT =>
        end case;
    end process;   
end proj_impl;






----------------------------------------------------------------------------------
--|
--|  Registro di supporto a 8 bit
--|
----------------------------------------------------------------------------------


library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

--| register entity
entity REGISTER_Z8 is
    port(
        clk:            in  std_logic;
        rst:            in  std_logic;
        data_in:        in  std_logic_vector(7 downto 0);
        data_out:       out std_logic_vector(7 downto 0)
    );
end REGISTER_Z8;


--| register implementation
architecture REG_impl of REGISTER_Z8 is

    constant inactive_in_signal : std_logic_vector := "UUUUUUUU";
    constant inactive_output : std_logic_vector := "00000000";
    
    
    begin
        reg: process(clk,rst)
        begin
            if rst='1' then
                --| reset dello stato del registro quando si riceve segnale di rst, uscite a zero
                data_out <= (others => '0');

            elsif rising_edge(clk) then
                --| controllo di inattivita registro: se ho un ingresso completamente indefinito
                --| allora mando in uscita un valore prefefinito (inactive_output, tutto nullo)
                if (data_in /= inactive_in_signal) then
                    data_out <= data_in;
                elsif (data_in = inactive_in_signal) then
                    data_out <= inactive_output;
                end if;
                
            end if;
        end process;
end REG_impl;
