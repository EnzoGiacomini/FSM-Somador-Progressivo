Library IEEE;
USE IEEE.std_logic_1164.all;

Entity datapath is
Port(DataIn : in std_logic_vector(7 downto 0);
     C : in std_logic_vector(34 downto 0);
     clk,reset : in std_logic;
     N,Z,cout,ov : out std_logic;
     DataOut,R0,R1,R2,R4 : out std_logic_vector(7 downto 0)
     );
end datapath;

architecture arq of datapath is

component reg8 is
Port(D : in std_logic_vector(7 downto 0);
     clk,reset,carga : in std_logic;
     q : out std_logic_vector(7 downto 0)
     );
end component;

component mux4_1 is
Port(A,B,C,D : in std_logic_vector(7 downto 0);
     sel : in std_logic_vector(1 downto 0);
     y : out std_logic_vector(7 downto 0)
     );
end component;

component soma_sub is
Port(A,B : in std_logic_vector(7 downto 0);
     op : in std_logic;
     N,Z,cout,ov : out std_logic;
     S : out std_logic_vector(7 downto 0)
     );
end component;

component ULA is
Port(A : in std_logic_vector(7 downto 0);
     op : in std_logic;
     S : out std_logic_vector(7 downto 0)
     );
end component;

type bus_d is array (0 to 7) of std_logic_vector(7 downto 0);

signal S_R,S_Q : bus_d;
signal DataUla1,aux : std_logic_vector(7 downto 0);
signal opA1_mux,opB1_mux,opA2_mux,opB2_mux : std_logic_vector(7 downto 0);
signal opC_mux : std_logic_vector(7 downto 0);
signal OutSoma1,OutSoma2,OutShift : std_logic_vector(7 downto 0);

begin

-- Somente os registradores usados pelo algoritmo sao instanciados.
-- R0 guarda 1, R1 guarda o contador, R2 guarda o numero atual e R4 guarda a soma.
S_R(0) <= DataIn when C(0) = '0' else DataUla1;
REG0: reg8 port map(S_R(0),clk,reset,C(8),S_Q(0));

-- R1 recebe a saida dedicada do segundo somador quando C(1) = 1.
S_R(1) <= DataIn when C(1) = '0' else OutSoma2;
REG1: reg8 port map(S_R(1),clk,reset,C(9),S_Q(1));

S_R(2) <= DataIn when C(2) = '0' else DataUla1;
REG2: reg8 port map(S_R(2),clk,reset,C(10),S_Q(2));

S_R(4) <= DataIn when C(4) = '0' else DataUla1;
REG4: reg8 port map(S_R(4),clk,reset,C(12),S_Q(4));

-- Posicoes sem registrador permanecem em zero, preservando os muxes originais.
-- O zero usado pela FSM e tirado daqui, selecionando a posicao de R3.
-- Nao existe um R3 fisico: S_Q(3) esta ligado direto em zero.
S_Q(3) <= (others => '0');
S_Q(5) <= (others => '0');
S_Q(6) <= (others => '0');
S_Q(7) <= (others => '0');

M8A1: with C(18 downto 16) select
    opA1_mux <= S_Q(0) when "000",
                S_Q(1) when "001",
                S_Q(2) when "010",
                S_Q(3) when "011",
                S_Q(4) when "100",
                S_Q(5) when "101",
                S_Q(6) when "110",
                S_Q(7) when others;

M8B1: with C(21 downto 19) select
    opB1_mux <= S_Q(0) when "000",
                S_Q(1) when "001",
                S_Q(2) when "010",
                S_Q(3) when "011",
                S_Q(4) when "100",
                S_Q(5) when "101",
                S_Q(6) when "110",
                S_Q(7) when others;

M8A2: with C(30 downto 28) select
    opA2_mux <= S_Q(0) when "000",
                S_Q(1) when "001",
                S_Q(2) when "010",
                S_Q(3) when "011",
                S_Q(4) when "100",
                S_Q(5) when "101",
                S_Q(6) when "110",
                S_Q(7) when others;

M8B2: with C(33 downto 31) select
    opB2_mux <= S_Q(0) when "000",
                S_Q(1) when "001",
                S_Q(2) when "010",
                S_Q(3) when "011",
                S_Q(4) when "100",
                S_Q(5) when "101",
                S_Q(6) when "110",
                S_Q(7) when others;

M4B: mux4_1 port map(S_Q(4),S_Q(5),S_Q(6),S_Q(7),
                     C(23 downto 22),opC_mux);

-- Primeiro somador: caminho original da DataUla.
-- Ele incrementa R2 e, no outro estado, acumula o valor em R4.
SOMA1: soma_sub port map(opA1_mux,opB1_mux,C(24),
                         open,open,open,open,OutSoma1);

-- Segundo somador: caminho dedicado a R1 e flags do contador.
-- Ele decrementa R1 e gera a flag Z usada para sair do loop.
SOMA2: soma_sub port map(opA2_mux,opB2_mux,C(34),
                         N,Z,cout,ov,OutSoma2);

M3: ULA port map(opC_mux,C(25),OutShift);

aux <= OutSoma1 when C(26) = '0' else OutShift;
DataUla1 <= aux when C(27) = '0' else opA1_mux;

DataOut <= opC_mux;
-- DataOut seleciona R4, que e onde a soma final fica guardada.

R0 <= S_Q(0);
R1 <= S_Q(1);
R2 <= S_Q(2);
R4 <= S_Q(4);

end arq;
