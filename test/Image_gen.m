clc,
clear all;
close all;

I=padarray(double(imresize((imread('rice.png')),[256,256])),[0,0]);
sign=20;
I=I(:,:,1);
In=I+sign*randn(size(I));
In(In<0)=0;
In(In>255)=255;

fp=fopen('img_in','w');
%fprintf(fp,'(');
for i=1:size(In,1)
    %fprintf(fp,'(');
    for j=1:size(In,2)
        v=dec2bin(In(i,j),8);
        fprintf(fp,['0', v,'\n']);
    end
    %fseek(fp, -2, 0);
    %fprintf(fp,',\n');
end
%fseek(fp, -2, 0);
    %fprintf(fp,');\n');
fclose(fp);
% 
figure(1),imshow(uint8(I));

figure(2),imshow(uint8(In));

