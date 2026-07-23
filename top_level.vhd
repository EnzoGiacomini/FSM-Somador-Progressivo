Library IEEE;
USE IEEE.std_logic_1164.all;

Entity top_level is
Port(CLOCK_27 : in std_logic;
     KEY0 : in std_logic;
     SW : in std_logic_vector(7 downto 0);
     LEDR : out std_logic_vector(7 downto 0);
     LEDG0 : out std_logic;
     HEX0,HEX1,HEX2,HEX3 : out std_logic_vector(6 downto 0)
     );
end top_level;

architecture arq of top_level is

component Divfreq_1Hz is
Port(clock,reset : in std_logic;
     q : out std_logic
     );
end component;

component FSM is
Port(DataIn : in std_logic_vector(7 downto 0);
     clk,reset : in std_logic;
     N,Z,cout,ov : out std_logic;
     DataOut,R0,R1,R2,R4 : out std_logic_vector(7 downto 0)
     );
end component;

component conversor_display is
Port(valor : in std_logic_vector(3 downto 0);
     display : out std_logic_vector(6 downto 0)
     );
end component;

signal reset,clk,Z_saida : std_logic;
signal fase : std_logic_vector(1 downto 0);
signal entrada,resultado : std_logic_vector(7 downto 0);

begin

-- KEY0 e ativo em zero.
reset <= not KEY0;

DIV_CLOCK: Divfreq_1Hz port map(CLOCK_27,reset,clk);

-- Seleciona 1, 10 e n nos tres ciclos de carga da FSM.
P_FASE: process(clk,reset)
begin
    if reset = '1' then
        fase <= "00";
    elsif clk'event and clk = '1' then
        case fase is
            when "00" => fase <= "01";
            when "01" => fase <= "10";
            when "10" => fase <= "11";
            when others => fase <= "11";
        end case;
    end if;
end process;

with fase select
    entrada <= x"01" when "01",
               x"0A" when "10",
               SW when others;

CONTROLE: FSM
port map(
    DataIn  => entrada,
    clk     => clk,
    reset   => reset,
    N       => open,
    Z       => Z_saida,
    cout    => open,
    ov      => open,
    DataOut => resultado,
    R0      => open,
    R1      => open,
    R2      => open,
    R4      => open
);

-- Resultado em binario.
LEDR <= resultado;

-- Acende o LED verde quando a flag de zero estiver ativa.
LEDG0 <= Z_saida;

-- Entrada nos displays da esquerda e resultado nos da direita.
DISPLAY0: conversor_display port map(resultado(3 downto 0),HEX0);
DISPLAY1: conversor_display port map(resultado(7 downto 4),HEX1);
DISPLAY2: conversor_display port map(SW(3 downto 0),HEX2);
DISPLAY3: conversor_display port map(SW(7 downto 4),HEX3);

end arq;
