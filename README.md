# Implementação física - Altera DE2

## Arquivos principais

- `top_level.vhd`: conecta o projeto à placa.
- `Divfreq_1Hz.vhd`: divide o clock de 27 MHz para 1 Hz.
- `conversor_display.vhd`: mostra valores hexadecimais nos displays.
- `Somador-Progressivo.qsf`: define o FPGA e os pinos.
- `Somador-Progressivo.sdc`: define o clock de entrada de 27 MHz.

## Ligações

| Recurso | Uso |
|---|---|
| `SW7..SW0` | Número de entrada `n` |
| `KEY0` | Reset e início |
| `LEDR7..LEDR0` | Resultado em binário |
| `LEDG0` | Flag `Z` (acende quando o resultado testado é zero) |
| `HEX3:HEX2` | Entrada em hexadecimal |
| `HEX1:HEX0` | Resultado em hexadecimal |

## Como executar

1. Defina `n` nas chaves `SW7..SW0`.
2. Pressione `KEY0`.
3. Solte `KEY0` para iniciar.
4. Aguarde aproximadamente 25 segundos.
5. Leia o resultado em `HEX1:HEX0` ou nos LEDs vermelhos.

O circuito divide o `CLOCK_27` da placa para 1 Hz, permitindo visualizar a
execução da FSM.

## Exemplos

| `n` | Entrada exibida | Resultado decimal | Resultado exibido |
|---:|---:|---:|---:|
| 3 | `03` | 88 | `58` |
| 10 | `0A` | 165 | `A5` |
| 18 | `12` | 253 | `FD` |

Os registradores possuem 8 bits. Para evitar overflow, utilize entradas de
`0` até `18`.

## Compilar e gravar

1. Abra `Somador-Progressivo.qpf` no Quartus.
2. Confira o dispositivo `EP2C35F672C6`.
3. Execute **Processing > Start Compilation**.
4. Conecte e ligue a DE2 pelo USB-Blaster.
5. Abra **Tools > Programmer**.
6. Selecione **USB-Blaster** em **Hardware Setup**.
7. Adicione o arquivo `.sof` gerado em `output_files`.
8. Marque **Program/Configure** e pressione **Start**.

É necessário que o Quartus instalado tenha suporte à família Cyclone II.
