library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_signed.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity boxf_rec is
    generic(size:integer := 2;
           Isize:integer := 4;
            busw:integer := 16 );
    Port ( Iin : in STD_LOGIC_VECTOR (busw-1 downto 0);
           clk : in STD_LOGIC;
           counter : in STD_LOGIC_vector(16 downto 0);
           start : in STD_LOGIC;
           Iout : out STD_LOGIC_VECTOR (busw-1 downto 0);
           done : out STD_LOGIC);
end boxf_rec;

architecture Behavioral of boxf_rec is

component fifo_generator_fh IS
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END component;
  
  component fifo_generator_bv IS
    PORT (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
    );
  END component;
    
    component fifo_generator_fv IS
      PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(busw+3 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
      );
    END component;

signal ff_rst: std_logic:='0';

signal w_en,r_en_1,full_1,empty_1: std_logic:='0';
signal r_en_3,full_3,empty_3: std_logic:='0';
signal r_en_4,full_4,empty_4: std_logic:='0';

signal Hin,Hz,Ha,Haz: std_logic_vector(busw+3 downto 0):=(others=>'0');
signal Vin,Vz,Va,Vaz: std_logic_vector(busw+3 downto 0):=(others=>'0');
begin


ff_rst<=not(start);
w_en<=start;

process(clk,start)
begin

if start='1' then
    if clk'event and clk='1' then
        Hin<=Iin(busw-1)  & Iin(busw-1)  & Iin(busw-1)  & Iin(busw-1)  & Iin;
    end if;
else
        Hin<=(others=>'0');
end if;
end process;


r_en_1<='1' when conv_integer(counter)>=size-1 else '0';
fifo1: fifo_generator_fh port map(clk,ff_rst,Hin,w_en,r_en_1,Hz,full_1,empty_1);

Ha<= Hin + Haz - Hz when start='1' else (others=>'0');

Haz<=Ha when clk'event and clk='0';

Vin<= conv_std_logic_vector(conv_integer(Ha)/size,busw+4) when clk'event and clk='0';
Va<= Vin + Vaz - Vz when start='1' else (others=>'0');

r_en_3<='1' when conv_integer(counter)>=((size*Isize)-1) else '0';
fifo3: fifo_generator_fv port map(clk,ff_rst,Vin,w_en,r_en_3,Vz,full_3,empty_3);

r_en_4<='1' when conv_integer(counter)>=Isize-1 else '0';
fifo4: fifo_generator_bv port map(clk,ff_rst,Va,w_en,r_en_4,Vaz,full_4,empty_4);

done<='0' when conv_integer(counter)<(Isize*size/2+size/2+1) else
      '0' when conv_integer(counter)>(Isize*Isize+Isize*size/2+size/2+1) else 
      '1';
Iout<=conv_std_logic_vector(conv_integer(Va)/size,busw) when clk'event and clk='1';

end Behavioral;
