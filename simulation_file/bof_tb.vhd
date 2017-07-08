library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.textio.all;

entity bof_tb is
end bof_tb;

architecture Behavioral of bof_tb is


component boxf_rec
    Port ( Iin : in STD_LOGIC_VECTOR (7 downto 0);
           clk : in STD_LOGIC;
           start : in STD_LOGIC_vector(0 downto 0);
           Iout : out STD_LOGIC_VECTOR (7 downto 0);
           --Hino: out STD_LOGIC_VECTOR (11 downto 0);
           --Hzo: out STD_LOGIC_VECTOR (11 downto 0);
           --Hao: out STD_LOGIC_VECTOR (11 downto 0);
           --Hazo: out STD_LOGIC_VECTOR (11 downto 0);
           done : out STD_LOGIC_vector(0 downto 0));
end component;

 signal Iin :  STD_LOGIC_VECTOR (7 downto 0):=(others=>'0');
 signal clk :  STD_LOGIC:='0';
 signal start :  STD_LOGIC_vector(0 downto 0):="0";
 signal Iout :  STD_LOGIC_VECTOR (7 downto 0):=(others=>'0');
 signal Hino:  STD_LOGIC_VECTOR (11 downto 0):=(others=>'0');
 signal Hzo:  STD_LOGIC_VECTOR (11 downto 0):=(others=>'0');
 signal Hao:  STD_LOGIC_VECTOR (11 downto 0):=(others=>'0');
 signal Hazo:  STD_LOGIC_VECTOR (11 downto 0):=(others=>'0');
        
 signal done :  STD_LOGIC_vector(0 downto 0):="0";

signal  bin_value : std_logic_vector(7 downto 0):=(others=>'0');
   --signal count: std_logic_vector(15 downto 0);
signal data : std_logic_vector(7 downto 0);
   --signal en_in,en_out: std_logic;
file file_pointer : text; 
file file_pointer_o : text;
      
       constant clk100_period : time := 10 ns; 
       
begin

uut: boxf_rec port map( Iin=>Iin,clk=>clk,start=>start,Iout=>Iout,done=>done);
--uut: boxf_rec port map( Iin=>Iin,clk=>clk,start=>start,Iout=>Iout,Hino=>Hino,Hzo=>Hzo,Hao=>Hao,Hazo=>Hazo,done=>done);

clkprocess: process
   begin
		clk <= '0';
		wait for clk100_period/2;
		clk <= '1';
		wait for clk100_period/2;
   end process;
process
begin
   start(0)<='0';
   wait for 50ns;
   start(0)<='1' ;
   wait for 750us;
   start(0)<='0' ;
   
   wait;
   end process;
   
   process(clk)
             
                variable line_content_o : string(1 to 8);
                variable line_content : string(1 to 8);
                variable bin_value_o : std_logic_vector(7 downto 0);
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
                    file_open(file_pointer,"/home/dsplab/Dropbox/gpf_box_2/img",READ_MODE);
                    file_open(file_pointer_o,"/home/dsplab/Dropbox/gpf_box_2/write.txt",WRITE_MODE);
                    flag:= 1;      
                  end if;
     
            if(clk'event and clk='0') then
                if(done(0)='1') then
                    bin_value_o:=Iout;
                    for j_o in 0 to 7 loop
                       if(bin_value_o(j_o) = '0') then
                           line_content_o(8-j_o) := '0';
                       else
                           line_content_o(8-j_o) := '1';
                       end if; 
                    end loop;
                    write(line_num_o,line_content_o); --write the line.
                    writeline (file_pointer_o,line_num_o); --write the contents into the file.
             end if;
             
             if(start(0)='1') then
                 if  not endfile(file_pointer) then
                 
                    readline (file_pointer,line_num); --reading a line from the file.
                    read(line_num,line_content);  --reading the data from the line and putting it in a real type variable.
                    for j in 0 to 7 loop
                       if(line_content(8-j) = '0') then
                           bin_value(j) := '0';
                       else
                           bin_value(j) := '1';
                       end if; 
                    end loop;
                    Iin<=bin_value;
                 --else
                    --start(0)<='0';
                end if;
             end if;
          end if;
                 
          -- wait;
       end process;
       
end Behavioral;
