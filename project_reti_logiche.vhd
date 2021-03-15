----------------------------------------------------------------------------------
-- Company: PoliMI
-- Engineer: Matteo Nunziante
-- 
-- Create Date: 12.02.2021 10:03:09
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: progetto reti logiche
-- Target Devices: 
-- Tool Versions: 
-- Description: Equalizzatore dell'istogramma di una immagine
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR(7 downto 0);--segnale che arriva dalla mem in seguito ad una lettura
           o_address : out STD_LOGIC_VECTOR(15 downto 0);--per mandare l'indirizzo alla mem
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;--per poter comunicare con la mem
           o_we : out STD_LOGIC;--1 per scrivere , 0 per leggere dalla mem
           o_data : out STD_LOGIC_VECTOR(7 downto 0)--segnale in uscita verso mem        
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is (IDLE , RESET , START_Indirizzo , START_Wait , START_Read , START_Fine , CALCOLA_MaxMin , CALCOLA_Indirizzo , CALCOLA_Wait , CALCOLA_Fine , CALCOLA_Shift , LEGGI_Indirizzo , LEGGI_Wait , LEGGI_Read , SCRIVI_Indirizzo , SCRIVI_Wait , DONE);
    signal CURRENT_STATE , NEXT_STATE : state_type := IDLE;

    signal resetAttivato : std_logic := '0';--viene posto uno quando viene attivato il reset

    begin
        --Processo gestione stato successivo
        stato:process(i_clk)
        begin
            if(rising_edge(i_clk)) then
                if(resetAttivato = '1')then
                    CURRENT_STATE <= RESET;
                else    
                    CURRENT_STATE <= NEXT_STATE;
                end if;
            end if;
        end process;   
        
        
        --Processo gestione macchina a stati 
        combin:process(i_clk , i_rst)--CURRENT_STATE , i_data , i_start)  
         
        --Dichiarazione variabili e loro inizializzazione     
        variable n_colonne , n_righe                                : integer := 0;
        variable num_pixel                                          : integer := 0;
        variable max_pixel_value                                    : integer := 0;
        variable min_pixel_value                                    : integer := 255;
        variable delta_value                                        : integer := 0;
        variable shift_level                                        : integer := 0;
        variable temp_pixel                                         : integer := 0;
        variable N                                                  : integer := 0;--pos pixel corrente
        variable temp_pixel_value                                   : unsigned(15 downto 0) := (others => '0');
        
        begin  
             if(i_rst = '1') and  (resetAttivato = '0')then
                resetAttivato <= '1';
                
            elsif(falling_edge(i_clk))then  
            
                if(i_rst = '0') and (CURRENT_STATE = RESET)then --se ho già fatto il reset dello stato
                    resetAttivato <= '0';
                end if;
                       
                case CURRENT_STATE is
                
                    when IDLE =>
                        --inizializzo i segnali                  
                        o_en <= '0';
                        o_we <= '0';
                        o_done <= '0';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        NEXT_STATE <= IDLE;
                        --inizializzo le variabili
                        n_colonne := 0;
                        n_righe := 0;
                        num_pixel := 0;
                        max_pixel_value := 0;
                        min_pixel_value := 255;
                        delta_value := 0;
                        shift_level := 0;
                        temp_pixel := 0;
                        N := 0;--pos pixel corrente
                        temp_pixel_value := (others => '0');
                        
                    when RESET => 
                        o_done <= '0';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        --o_en <= '0';-------------------------
                        --o_we <= '0';-------------------------
                        
                        N := 0;
                        n_colonne := 0;
                        n_righe := 0;
                        num_pixel := 0;
                        max_pixel_value := 0;
                        min_pixel_value := 255;
                        delta_value := 0;
                        shift_level := 0;
                        temp_pixel := 0;
                        temp_pixel_value := (others => '0');
    
                        if(i_start = '1') then 
                            NEXT_STATE <= START_Indirizzo;
                            o_en <= '1';
                            o_we <= '0';
                        else
                            NEXT_STATE <= RESET;
                            o_en <= '0';
                            o_we <= '0';
                        end if;
                        
                    when START_Indirizzo => 
                        o_done <= '0';
                        o_data <= (others => '0');  
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));               
                        if(N >= 2) then 
                            o_en <= '0';
                            o_we <= '0';                        
                            NEXT_STATE <= START_Fine;
                        else
                            o_en <= '1';
                            o_we <= '0';
                            NEXT_STATE <= START_Wait;
                        end if;
                        
                    when START_Wait => --serve solo per aspettare un ciclo di clock
                        o_done <= '0';
                        o_en <= '1';
                        o_we <= '0';
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));
                        o_data <= (others => '0');
                        NEXT_STATE <= START_Read;
                    
                    when START_Read =>
                        o_done <= '0';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        --Leggo le dimensioni dell'immagine da convertire
                        if(N = 0) then
                            n_colonne := conv_integer(i_data);
                        else
                            n_righe := conv_integer(i_data);
                        end if;
                        o_en <= '0';
                        o_we <= '0'; 
                        N := N + 1;
                        NEXT_STATE <= START_Indirizzo; 
                        
                     when START_Fine =>
                        o_en <= '0';
                        o_we <= '0';
                        o_done <= '0';
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));
                        o_data <= (others => '0');
                        N := 2;
                        num_pixel := n_colonne * n_righe;--num totale di pixel
                        NEXT_STATE <= CALCOLA_Indirizzo;                 
                                    
                    when CALCOLA_Indirizzo =>
                        o_done <= '0';
                        o_data <= (others => '0');
                        num_pixel := n_colonne * n_righe;
                        if(N < (num_pixel + 2))then
                            o_en <= '1';
                            o_we <= '0';
                            o_address <= std_logic_vector(to_unsigned(N , o_address'length));--in un ciclo dico l'indirizzo,nel successivo leggo il valore
                            NEXT_STATE <= CALCOLA_Wait;--per aspettare un ciclo di clock necessario alla ram
                        else
                            o_address <= (others => '0');
                            o_en <= '0';
                            o_we <= '0';
                            NEXT_STATE <= CALCOLA_Fine;
                        end if;
                        
                    when CALCOLA_Wait => 
                        o_done <= '0';
                        o_en <= '1';
                        o_we <= '0';
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));
                        o_data <= (others => '0');
                        num_pixel := n_colonne * n_righe;
                        NEXT_STATE <= CALCOLA_MaxMin;
                        
                    when CALCOLA_MaxMin =>
                        o_done <= '0';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        --scorro tutti i pixel e trovo max e min                                        
                        temp_pixel := conv_integer(i_data);                  
                        if(temp_pixel > max_pixel_value) then 
                            max_pixel_value := temp_pixel;
                        end if;
                        if(temp_pixel < min_pixel_value) then
                            min_pixel_value := temp_pixel;
                        end if;
                        
                        o_en <= '0';
                        o_we <= '0';                    
                        N := N + 1;
                        num_pixel := n_colonne * n_righe;
                        NEXT_STATE <= CALCOLA_Indirizzo;
                        
                     when CALCOLA_Fine =>
                        o_en <= '0';
                        o_we <= '0';
                        o_done <= '0';
                        o_data <= (others => '0');
                        o_address <= (others => '0');
                        N := 0;
                        num_pixel := n_colonne * n_righe;
                        NEXT_STATE <= CALCOLA_Shift;
                        
                    
                    when CALCOLA_Shift =>  
                        o_done <= '0';
                        o_en <= '0';
                        o_we <= '0';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        
                        delta_value := max_pixel_value - min_pixel_value;
                        num_pixel := n_colonne * n_righe;
                        
                        if(delta_value >= 255) then 
                            shift_level := 0;
                        elsif(delta_value >= 127) then 
                            shift_level := 1;
                        elsif(delta_value >= 63) then
                            shift_level := 2;
                        elsif(delta_value >= 31) then
                            shift_level := 3;
                        elsif(delta_value >= 15) then
                            shift_level := 4;
                        elsif(delta_value >= 7) then
                            shift_level := 5;
                        elsif(delta_value >= 3) then
                            shift_level := 6;
                        elsif(delta_value >= 1) then 
                            shift_level := 7;
                        else 
                            shift_level := 8; 
                        end if;
                        
                        N := 2;
                        NEXT_STATE <= LEGGi_Indirizzo;
                    
                    
                    when LEGGI_Indirizzo =>
                        o_data <= (others => '0');
                        num_pixel := n_colonne * n_righe;
                        if(N < num_pixel + 2) then   
                            o_we <= '0';--per leggere
                            o_en <= '1';     
                            o_done <= '0';                               
                            o_address <= std_logic_vector(to_unsigned(N, o_address'length));--indirizzo pixel N
                            NEXT_STATE <= LEGGI_Wait;
                        else
                            o_en <= '0';
                            o_we <= '0';
                            o_done <= '1';
                            o_address <= (others => '0');
                            NEXT_STATE <= DONE;
                        end if;
                        
                    when LEGGI_Wait =>
                        o_done <= '0';
                        o_en <= '1';
                        o_we <= '0';
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));
                        o_data <= (others => '0');
                        num_pixel := n_colonne * n_righe;
                        NEXT_STATE <= LEGGI_Read;
                        
                    when LEGGI_Read =>
                        o_done <= '0';
                        o_en <= '0';
                        o_we <= '0';
                        o_address <= std_logic_vector(to_unsigned(N , o_address'length));
                        o_data <= (others => '0');
                        num_pixel := n_colonne * n_righe;
                        temp_pixel := conv_integer(i_data);--valore pixel corrente letto
                        temp_pixel := temp_pixel - min_pixel_value;
                        temp_pixel_value := to_unsigned(temp_pixel , temp_pixel_value'length);--metto l'intero in un unsigned
                        temp_pixel_value := temp_pixel_value sll shift_level;--faccio lo shift
    
                        if(temp_pixel_value > to_unsigned(255 , temp_pixel_value'length))then
                            temp_pixel_value := to_unsigned(255 , temp_pixel_value'length);
                        end if;
                        NEXT_STATE <= SCRIVI_indirizzo;
                     
                     when SCRIVI_Indirizzo => 
                        o_done <= '0';
                        o_en <= '1';
                        o_we <= '1';--abilito la scrittura
                        o_address <= std_logic_vector(to_unsigned((N + num_pixel), o_address'length));--indirizzo di scrittura pixel N   
                        o_data <= std_logic_vector(temp_pixel_value(7 downto 0));
                        num_pixel := n_colonne * n_righe;
                        NEXT_STATE <= SCRIVI_Wait;
                        
                      when SCRIVI_Wait =>
                        o_done <= '0';
                        o_en <= '1';
                        o_we <= '1';
                        o_address <= std_logic_vector(to_unsigned(N + num_pixel , o_address'length));
                        o_data <= std_logic_vector(temp_pixel_value(7 downto 0));
                        temp_pixel_value := (others => '0');--riinizzializzo
                        N := N + 1;
                        NEXT_STATE <= LEGGI_Indirizzo;   
                        
                        
                    when DONE =>
                        o_en <= '0';--disattivo la comuncazione
                        o_we <= '0';
                        o_done <= '1';
                        o_address <= (others => '0');
                        o_data <= (others => '0');
                        N := 0;
                        if(i_start = '0') then
                            NEXT_STATE <= RESET;
                        else
                            NEXT_STATE <= CURRENT_STATE;--non dovrebbe servire
                        end if;
                     
                end case; 
            end if;
        end process;

end Behavioral;