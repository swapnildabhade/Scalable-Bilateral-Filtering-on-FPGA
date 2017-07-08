library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_signed.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity gpf_main is
    Port ( Iin : in STD_LOGIC_VECTOR (8 downto 0);
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           Iout : out STD_LOGIC_VECTOR (8 downto 0);
--                Y : out STD_LOGIC_VECTOR (15 downto 0);
--                Y1 : out STD_LOGIC_VECTOR (15 downto 0);
--                Y2 : out STD_LOGIC_VECTOR (15 downto 0);
--                YYY : out STD_LOGIC_VECTOR (40 downto 0);
                st:out STD_LOGIC_VECTOR (2 downto 0);
                --temp_gon:out STD_LOGIC;
                Nout:out integer;
                count_out : out STD_LOGIC_VECTOR (16 downto 0);
           done : out STD_LOGIC);
end gpf_main;

architecture Behavioral of gpf_main is

component fifo_generator_0 
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END component;

component boxf_rec     
        generic(size:integer := 4;
           Isize:integer := 256;
            busw:integer := 16 );

    Port ( Iin : in STD_LOGIC_VECTOR (15 downto 0);
           clk : in STD_LOGIC;
           counter : in STD_LOGIC_vector(16 downto 0);
           start : in STD_LOGIC;
           Iout : out STD_LOGIC_VECTOR (15 downto 0);
           done : out STD_LOGIC);
end component;


    component fifo_generator_delay IS
      PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
      );
    END component;

component gaussina_fn
    Port ( A : in STD_LOGIC_VECTOR (15 downto 0);
             en : in STD_LOGIC;
           Y : out STD_LOGIC_VECTOR (15 downto 0));
end component;

constant img_s:integer:=4;
constant win_s:integer:=2;
constant sigr:integer:=70;
constant tc:integer:=127;
constant Nmax:integer:=9;

type arr is array(20 downto 1) of std_logic_vector(8 downto 0); --Q1.8 
constant Sqroot:arr:=("000011101","000011101","000011110","000011111","000100000","000100001","000100010","000100100","000100101","000100111","000101000","000101011","000101101","000110000","000110100","000111001","001000000","001001010","001011011","010000000");
constant Ninv:arr:=("000000110","000000111","000000111","000001000","000001000","000001001","000001001","000001010","000001011","000001100","000001101","000001110","000010000","000010010","000010101","000011010","000100000","000101011","001000000","010000000");


signal Nsig,Nsig2:integer:=1;

signal counter:std_logic_vector(16 downto 0):=(others=>'0');

signal  fiforst:std_logic:='0';
signal  count_rst,count_max:std_logic:='0';
signal  g_on,g_st:std_logic:='0';
signal  init_gpa:std_logic:='0';
signal  start_en,out_en:std_logic:='0';
signal  div_en:std_logic:='0';
signal  gd_full,gd_empty:std_logic:='0';
signal  hd_full,hd_empty:std_logic:='0';
signal  Hwr,Fwr,Gwr,Pwr,Qwr:std_logic:='0';


signal  Hcon:std_logic_vector(3 downto 0):="0000";     --control signal (full,empty,read,write)
signal  Fcon:std_logic_vector(3 downto 0):="0000";
signal  Gcon:std_logic_vector(3 downto 0):="0000";
signal  Pcon:std_logic_vector(3 downto 0):="0000";
signal  Qcon:std_logic_vector(3 downto 0):="0000";

signal Hin,Hout:std_logic_vector(15 downto 0):=(others=>'0');   --Q8.8
signal Fin,Fout,HFsig2:std_logic_vector(15 downto 0):=(others=>'0');
signal Gin,Gout:std_logic_vector(15 downto 0):=(others=>'0');
signal Pin,Pout,Pout2:std_logic_vector(15 downto 0):=(others=>'0');
signal Qin,Qout,Qout2:std_logic_vector(15 downto 0):=(others=>'0');


signal  Hsig,Hsig2:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8
signal  Fsig,Fsig2:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8
signal  Gdel:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8
signal  Hdel:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8
signal  Fbar,Fbar2,Fbar3:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8

signal  Filtin,Filtout,Filtout2:std_logic_vector(15 downto 0):=(others=>'0'); --Q8.8

signal  HFsig:std_logic_vector(31 downto 0):=(others=>'0'); --Q16.16
signal  HGsig:std_logic_vector(40 downto 0):=(others=>'0'); --Q18.23
signal  HFbarsig:std_logic_vector(40 downto 0):=(others=>'0'); --Q18.23
signal  FGsig:std_logic_vector(31 downto 0):=(others=>'0'); --Q16.16
signal  FbarGdelsig:std_logic_vector(31 downto 0):=(others=>'0'); --Q16.16
signal  FbarHdelsig:std_logic_vector(31 downto 0):=(others=>'0'); --Q16.16

--Defines the type for states in the state machine
type state_type is (wait_start,init,init_wait,filtN_wait,filtN,incN,last,last_wait,output,stop); 
--Declare the signal with the corresponding state type.
signal Current_State, Next_State : state_type:=wait_start; 

begin

start_en<=start when clk'event and clk='1';
done<=out_en;
fsm: process(clk,Current_State,count_max,start,g_on)
begin
    case Current_State is 
        when wait_start =>
            count_rst<='1';
            fiforst<='1';
            g_st<='0';
            init_gpa<='0';
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="00";
            Qcon(1 downto 0)<="00";
               st<="000";
            if start_en='0' then
                Next_State<=wait_start;
            else
                Next_State<=init;
            end if;
        when init => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='1';
--            out_en<=g_on;
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="01";
            Fcon(1 downto 0)<="01";
            Gcon(1 downto 0)<="01";
            Pcon(1 downto 0)<='0' & g_on;
            Qcon(1 downto 0)<='0' & g_on;
                st<="001";
            if count_max='1' then
                 Next_State<=init_wait;
            else
                Next_State<=init;
            end if;
        when init_wait => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='1';
            Nsig<=1;
            Nsig2<=1;
--            out_en<=g_on;
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="01" ;
            Qcon(1 downto 0)<="01";
                st<="001";
            if g_on='0' then
                g_st<='0';
                count_rst<='1';
                if Nsig<Nmax then
                    Next_State<=filtN;
                else
                    Next_State<=last;
                end if;
            else
                Next_State<=init_wait;
            end if;
        when filtN => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='0';
--            out_en<=g_on;
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="11";
            Fcon(1 downto 0)<="11";
            Gcon(1 downto 0)<="11";
            Pcon(1 downto 0)<=g_on & g_on ;
            Qcon(1 downto 0)<=g_on & g_on ;
               st<="010";
            if count_max='1' then
                Next_State<=filtN_wait;
            else
                Next_State<=filtN;
            end if;
        when filtN_wait => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='0';
            Nsig2<=Nsig+1;
--          out_en<=g_on;
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="11" ;
            Qcon(1 downto 0)<="11";
                st<="010";
            if g_on='0' then
                g_st<='0';
                count_rst<='1';
                Next_State<=incN;
            else
                Next_State<=filtN_wait;
            end if;
        when incN =>
            count_rst<='1';
            fiforst<='0';
            g_st<='0';
            init_gpa<='0';
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="00" ;
            Qcon(1 downto 0)<="00";
                st<="011";
            Nsig<=Nsig2;
            if Nsig<Nmax then 
                Next_State<=filtN;
            else
                Next_State<=last;
            end if;
        when last => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='0';
--            out_en<=g_on;
          out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="10";
            Fcon(1 downto 0)<="10";
            Gcon(1 downto 0)<="10";
            Pcon(1 downto 0)<=g_on & g_on ;
            Qcon(1 downto 0)<="00";
--            Qcon(1 downto 0)<=g_on & '0';
                st<="100";
            if count_max='1' then
                Next_State<=last_wait;
            else
                Next_State<=last;
            end if;
        when last_wait => 
            count_rst<='0';
            fiforst<='0';
            g_st<='1';
            init_gpa<='0';
--            out_en<=g_on;
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="11" ;
            Qcon(1 downto 0)<="00";
--            Qcon(1 downto 0)<=g_on & '0';
st<="100";
            if g_on='0' then
                g_st<='0';
                count_rst<='1';
                Next_State<=output;
            else
                Next_State<=last_wait;
            end if;
        when output => 
            count_rst<='0';
            fiforst<='0';
            g_st<='0';
            init_gpa<='0';
            out_en<='1';
            div_en<='1';
            Hcon(1 downto 0)<="10";
            Fcon(1 downto 0)<="10";
            Gcon(1 downto 0)<="10";
            Pcon(1 downto 0)<="10" ;
            Qcon(1 downto 0)<="10";
                st<="101";
            if count_max='1' then
                count_rst<='1';
                Next_State<=stop;
            else
                Next_State<=output;
            end if;        
       when stop => 
            count_rst<='1';
            fiforst<='0';
            g_st<='0';
            init_gpa<='0';
            out_en<='0';
            div_en<='0';
            Hcon(1 downto 0)<="00";
            Fcon(1 downto 0)<="00";
            Gcon(1 downto 0)<="00";
            Pcon(1 downto 0)<="00";
            Qcon(1 downto 0)<="00";
                st<="110";
            if count_max='1' then
                Next_State<=stop;
            else
                Next_State<=wait_start;
            end if;        
        when others => 
            st<="111";
            Next_State <= wait_start;
        end case;
end process;
Current_State<=Next_State when clk'event and clk='1';

process(clk,count_rst)
begin
if clk'event and clk='1' then
    if count_rst='1' then
        counter<=(others=>'0');
    else
        counter<=counter+1;
    end if;    
end if;
end process;
count_max<='1' when conv_integer(counter)>=img_s*img_s-1 else '0';

Hsig<=conv_std_logic_vector((conv_integer(Iin)-tc)*2**8/sigr,16) when init_gpa='1';
gauss_gen:gaussina_fn port map(Hsig,init_gpa,Fsig);

Hsig2<=Hsig when clk'event and clk='1';
Hwr<=Hcon(0) when clk'event and clk='1';
Hin<=Hsig2 when init_gpa='1' else Hout;
Himg:fifo_generator_0 port map(clk,fiforst,Hin,Hwr,Hcon(1),Hout,Hcon(3),Hcon(2));

Fsig2<=Fsig when clk'event and clk='1';
HFsig<=Hsig2*Fsig2;
Fwr<=Fcon(0) when clk'event and clk='1';
Fin<=HFsig(23 downto 8) when init_gpa='1' else Fout;
Fimg:fifo_generator_0 port map(clk,fiforst,Fin,Fwr,Fcon(1),Fout,Fcon(3),Fcon(2));
--Fout2<=Fout when clk'event and clk='1';

--HGsig<=Hout*Gout*Sqroot(Nsig) when clk'event and clk='1';--this will add extra delay but it will reduce ctirtical section;
HGsig<=Hout*Gout*Sqroot(Nsig);
Gin<="0000000100000000" when init_gpa='1' else HGsig(30 downto 15);
Gwr<=Gcon(0) when clk'event and clk='1';
Gimg:fifo_generator_0 port map(clk,fiforst,Gin,Gwr,Gcon(1),Gout,Gcon(3),Gcon(2));

FGsig<=Fout*Gout;
Filtin<=Fsig when init_gpa='1' else FGsig(23 downto 8);
spatial_filt:boxf_rec generic map(win_s,img_s,16) port map(Filtin, clk,counter, g_st, Filtout,g_on );

Gdelay:fifo_generator_delay port map(clk,not(g_st),Gout,g_st,g_on,Gdel,gd_full,gd_empty);
Filtout2<=Filtout when clk'event and clk='1';
--FbarGdelsig<=Filtout*Gdel when clk'event and clk='1';--this will add extra delay but it will reduce ctirtical section;
FbarGdelsig<=Filtout*Gdel ;
Fbar<=Filtout2 when init_gpa='1' else FbarGdelsig(23 downto 8);


Hdelay:fifo_generator_delay port map(clk,not(g_st),Hout,g_st,g_on,Hdel,hd_full,hd_empty);

--HFbarsig<=Hdel*Fbar*Ninv(Nsig) when clk'event and clk='1';--this will add extra delay but it will reduce ctirtical section
HFbarsig<=Hdel*Fbar*Ninv(Nsig);

Fbar2<=Fbar when clk'event and clk='1';
Fbar3<=Fbar2 when clk'event and clk='1';

Qin<=Fbar when init_gpa='1' else HFbarsig(30 downto 15);
--Qout2<=Qout when clk'event and clk='1';
Qwr<=Qcon(0) when clk'event and clk='1';
Qimg:fifo_generator_0 port map(clk,fiforst,Qin+Qout,Qwr,Qcon(1),Qout,Qcon(3),Qcon(2));

Pin<=Fbar when init_gpa='0' else (others=>'0');
--Pout2<=Pout when clk'event and clk='1';
Pwr<=Pcon(0) when clk'event and clk='1';
Pimg:fifo_generator_0 port map(clk,fiforst,Pin+Pout,Pwr,Pcon(1),Pout,Pcon(3),Pcon(2));
--Iout<="000000" & init_gpa & g_st & g_on;
--Iout<= Sqroot(Nsig);
Iout<=(others=>'0') when output/=Current_State else
    (others=>'0') when conv_integer(Qout)=0 else 
    conv_std_logic_vector((conv_integer(Pout)*sigr/conv_integer(Qout)+127),9);
--Y<=(others=>'0') when conv_integer(Qout)=0 else conv_std_logic_vector((conv_integer(Pout)*sigr/conv_integer(Qout)+127),16);
--Y<=Qout;
--Y1<=Qin;
--Y2<=Fbar;
--YYY<=HFbarsig;
Nout<=Nsig2;
count_out<=counter;
--temp_gon <= g_on;
end Behavioral;
 