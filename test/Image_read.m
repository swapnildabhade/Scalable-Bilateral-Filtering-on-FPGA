clc;
clear all;
close all;

fid = fopen('img_out','r');
tem='000000000';
while ~feof(fid)
    tline = fgets(fid);
    tem=[tem; tline(1:end-1)];
end

fclose(fid);

for i=1:size(tem,1)
   tem1=tem(i,:);
   val(i)=0;
   for j=1:9
       if tem1(j)=='1'
           val(i)=val(i)+2^(9-j);
       end
   end
   if tem1(1)=='1'
       val(i)=val(i)-2^9;
   end 
end
bias=1;
siz=256;
clk_div=1;
val2=[val val(end)*ones([1 bias])];
imad=val2(bias:clk_div:clk_div*siz^2+bias-1);
img=reshape(imad,[siz siz]);
img=img';
 img(img<=0)=0;
 img(img>255)=255;
figure(6),imshow((uint8((img))));
