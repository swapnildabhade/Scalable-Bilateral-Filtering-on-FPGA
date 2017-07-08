library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use STD.textio.all;


entity tb_gpf2 is
end tb_gpf2;

architecture Behavioral of tb_gpf2 is

component gpf_main 
    Port ( Iin : in STD_LOGIC_VECTOR (8 downto 0);
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           Iout : out STD_LOGIC_VECTOR (8 downto 0);
--                Y : out STD_LOGIC_VECTOR (15 downto 0);
--                Y1 : out STD_LOGIC_VECTOR (15 downto 0);
--                Y2 : out STD_LOGIC_VECTOR (15 downto 0);
--                YYY : out STD_LOGIC_VECTOR (40 downto 0);
                st:out STD_LOGIC_VECTOR (2 downto 0);
                 Nout:out integer;
                count_out : out STD_LOGIC_VECTOR (16 downto 0);
           done : out STD_LOGIC);
end component;

signal Iin :  STD_LOGIC_VECTOR (8 downto 0);
signal           clk :  STD_LOGIC;
signal           start :  STD_LOGIC;
signal           Iout :  STD_LOGIC_VECTOR (8 downto 0);
--signal                Y :  STD_LOGIC_VECTOR (15 downto 0);
--signal                Y1 :  STD_LOGIC_VECTOR (15 downto 0);
--signal                Y2 :  STD_LOGIC_VECTOR (15 downto 0);
--signal                YYY :  STD_LOGIC_VECTOR (40 downto 0);
signal                st: STD_LOGIC_VECTOR (2 downto 0);
signal  Nout:integer;
signal                count_out :  STD_LOGIC_VECTOR (16 downto 0);
signal           done :  STD_LOGIC;

signal           en_out,en_in :  STD_LOGIC:='0';


  file file_pointer : text; 
   file file_pointer_o : text;
   file file_pointer_o2 : text;
 
begin

uut: gpf_main port map(Iin,clk,start,Iout,
--        Y,
--        Y1,Y2,
--        YYY,
        st,
        Nout,
        count_out,
            done);

clocking: process
begin
clk<='1';
wait for 5 ns;
clk<='0';
wait for 5 ns;
end process;

process
begin
start<='0';
wait for 50ns;
start<='1';
wait for 15ns;
start<='0';
wait ;


end process;

en_in<='1' when start='1' ;
en_out<= done;

   process(clk)
             
                variable line_content_o : string(1 to 16);
--                variable line_content_o : string(1 to 9);
                variable line_content : string(1 to 8);
                variable bin_value_o : std_logic_vector(15 downto 0);
--                variable bin_value_o : std_logic_vector(8 downto 0);
                variable bin_value : std_logic_vector(7 downto 0);
              variable line_num_o : line;
              variable line_num : line;
                variable i_o,j_o : integer := 0;
                variable i,j : integer := 0;
                variable char_o : character:='0'; 
                variable char : character:='0'; 
                 variable flag : integer:=0;
            
      begin
           --Open the file read.txt from the specified location for reading(READ_MODE).
           if(flag=0) then
                    file_open(file_pointer,"/home/dsplab/Documents/gpf_box_3/img_dummy",READ_MODE);
                    file_open(file_pointer_o,"/home/dsplab/Documents/gpf_box_3/write_old2.txt",WRITE_MODE);
                    flag:= 1;      
                  end if;
     
            if(clk'event and clk='0') then
                if(en_out='1') then
                        bin_value_o:="0000000" & Iout;
--                        bin_value_o:=Y;
                    
                    for j_o in 0 to 15 loop
                       if(bin_value_o(j_o) = '0') then
                           line_content_o(16-j_o) := '0';
                       else
                           line_content_o(16-j_o) := '1';
                       end if; 
                    end loop;
                    write(line_num_o,line_content_o); --write the line.
                    writeline (file_pointer_o,line_num_o); --write the contents into the file.
             end if;
             
             if(en_in='1' and not endfile(file_pointer)) then
                readline (file_pointer,line_num); --reading a line from the file.
                read(line_num,line_content);  --reading the data from the line and putting it in a real type variable.
                for j in 0 to 7 loop
                   if(line_content(8-j) = '0') then
                       bin_value(j) := '0';
                   else
                       bin_value(j) := '1';
                   end if; 
                end loop;
                Iin<='0' & bin_value;
             end if;
          end if;
                 
          -- wait;
       end process;

end Behavioral;
