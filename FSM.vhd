Library IEEE;
USE IEEE.std_logic_1164.all;

Entity FSM is
Port(DataIn : in std_logic_vector(7 downto 0);
     clk,reset : in std_logic;
     N,Z,cout,ov : out std_logic;
     DataOut,R0,R1,R2,R4 : out std_logic_vector(7 downto 0)
     );
end FSM;

architecture arq of FSM is

component datapath is
Port(DataIn : in std_logic_vector(7 downto 0);
     C : in std_logic_vector(34 downto 0);
     clk,reset : in std_logic;
     N,Z,cout,ov : out std_logic;
     DataOut,R0,R1,R2,R4 : out std_logic_vector(7 downto 0)
     );
end component;

-- DataIn recebe, em ciclos consecutivos: 1, 10 e n.
-- R0 = constante 1
-- R1 = contador
-- R2 = numero atual
-- R4 = acumulador e DataOut
-- Tem que guardar a soma no R4 porque ele e o registrador que vai para DataOut.

--ESTADOS:
type t_state is (
    Sreset, --Reseta
    S_carrega_um, --DataIn Constante 1
    S_carrega_dez, --DataIn Constante 10 (controle de soma)
    S_carrega_n, --DataIn o numero que inicia as somas sucessivas
    S_copia_n, --R4 recebe o valor inicial de R2
    --Inicio LOOP:
    S_atualiza, --Incrementa R2 e decrementa o controlador no mesmo ciclo
    S_acumula, --Acumula na soma e testa o fim do loop
    --FIM LOOP
    S_fim --DataOut
);

signal estado_atual, prox_estado : t_state;
signal C : std_logic_vector(34 downto 0);
signal N_dp, Z_dp, cout_dp, ov_dp : std_logic; --Pegar as flags do datapath

-- SOBRE A PALAVRA CONTROLE:
-- 0 a 7 = DataIn (0) ou Data_U (1)
-- 8 a 15 = Load (1) ou Nao Load (0)
-- 18 a 16 = Seleciona Registrador para opA1 (3 bits)
-- 21 a 19 = Seleciona Registrador para opB1 (3 bits)
-- 23 a 22 = Seleciona Registrador para DataOut ou Shifter (2 bits)
-- 24 = SOMA ou SUB do primeiro somador
-- 25 = ShiftL ou ShiftR
-- 26 = Resultado SOMA/SUB ou SHIFTL/SHIFTR
-- 27 = opA1 ou Resultado do SOMA/SUB/SHIFTL/SHIFTR
-- 30 a 28 = Seleciona Registrador para opA2 (3 bits)
-- 33 a 31 = Seleciona Registrador para opB2 (3 bits)
-- 34 = SOMA ou SUB do segundo somador

begin

P1: process(clk,reset)
begin
    if reset = '1' then
        estado_atual <= Sreset;
    elsif clk'event and clk = '1' then
        estado_atual <= prox_estado;
    end if;
end process;

P2: process(estado_atual,reset,Z_dp)
begin

    --Comeca o algoritmo com tudo zerado, logo inicialmente ja ta tudo setado para DataIn
    C <= (others => '0');
    prox_estado <= estado_atual;

    case estado_atual is
        when Sreset =>
            if reset = '0' then
                prox_estado <= S_carrega_um;
            end if;

        when S_carrega_um =>
            -- R0 <- DataIn (1)
            -- O 1 fica guardado para incrementar R2 e decrementar R1.
            C(15 downto 8) <= "00000001"; --Load R0
            prox_estado <= S_carrega_dez;

        when S_carrega_dez =>
            -- R1 <- DataIn (10)
            -- R1 controla quantas vezes o loop vai repetir.
            C(15 downto 8) <= "00000010"; --Load R1
            prox_estado <= S_carrega_n;

        when S_carrega_n =>
            -- R2 <- DataIn (n)
            -- R2 guarda o numero que vai sendo incrementado.
            C(15 downto 8) <= "00000100"; --Load R2
            prox_estado <= S_copia_n;

        when S_copia_n =>
            -- R4 <- R2, sem operacao aritmetica.
            -- R4 comeca com n porque o numero lido tambem entra na soma.
            -- Tem que guardar no R4 porque ele e quem vai para DataOut.
            C(7 downto 0)   <= "00010000"; --Data_U
            C(15 downto 8)  <= "00010000"; --Load R4
            C(18 downto 16) <= "010"; --opA1 = R2
            C(27) <= '1';              --DataUla1 = opA1
            prox_estado <= S_atualiza;

        when S_atualiza =>
            -- Duas operacoes no mesmo ciclo:
            -- Somador 1: R2 <- R2 + R0
            -- Somador 2: R1 <- R1 - R0
            -- Os dois somadores fazem essas contas ao mesmo tempo.
            C(7 downto 0)   <= "00000110"; --Data_U para R1 e R2
            C(15 downto 8)  <= "00000110"; --Load R1 e R2

            C(18 downto 16) <= "010"; --opA1 = R2
            C(21 downto 19) <= "000"; --opB1 = R0
            C(24) <= '0';              --soma 1
            C(26) <= '0';              --resultado somador 1
            C(27) <= '0';              --DataUla1

            C(30 downto 28) <= "001"; --opA2 = R1
            C(33 downto 31) <= "000"; --opB2 = R0
            C(34) <= '1';              --subtracao 2

            prox_estado <= S_acumula;

        when S_acumula =>
            -- Somador 1: R4 <- R4 + R2
            -- Somador 2: testa R1 - R3, sendo R3 = 0
            -- O zero e tirado do datapath pela posicao de R3.
            -- R3 nao e um registrador fisico: essa posicao foi ligada em zero.
            C(7 downto 0)   <= "00010000"; --Data_U
            C(15 downto 8)  <= "00010000"; --Load R4
            C(18 downto 16) <= "100"; --opA1 = R4
            C(21 downto 19) <= "010"; --opB1 = R2
            C(24) <= '0';
            C(26) <= '0';
            C(27) <= '0';

            C(30 downto 28) <= "001"; --opA2 = R1
            C(33 downto 31) <= "011"; --opB2 = R3 = 0
            C(34) <= '1';              --subtracao 2

            -- A soma atual acontece antes da saida do loop.
            if Z_dp = '1' then
                prox_estado <= S_fim;
            else
                prox_estado <= S_atualiza;
            end if;

        when S_fim =>
            -- DataOut <- R4. Mantem o resultado ate reset.
            -- O resultado fica parado na saida ate receber outro reset.
            C(23 downto 22) <= "00";
            prox_estado <= S_fim;
    end case;
end process;

N    <= N_dp;
Z    <= Z_dp;
cout <= cout_dp;
ov   <= ov_dp;

DP: datapath
port map(
    DataIn  => DataIn,
    C       => C,
    clk     => clk,
    reset   => reset,
    N       => N_dp,
    Z       => Z_dp,
    cout    => cout_dp,
    ov      => ov_dp,
    DataOut => DataOut,
    R0      => R0,
    R1      => R1,
    R2      => R2,
    R4      => R4
);

end arq;
