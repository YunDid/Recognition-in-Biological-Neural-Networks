clc
clear
close 
import java.awt.Robot;
import iava.awe.event.*;
robot = java.awt.Robot;
locx=[888 918 945 973 1002 1029 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    888 918 945 973 1002 1029];
locy=[418 418 418 418 418 418 ...
    455 455 455 455 455 455 455 455 ...
    474 474 474 474 474 474 474 474 ...
    501 501 501 501 501 501 501 501 ...
    531 531 531 531 531 531 531 ...
    558 558 558 558 558 558 558 558 ...
    585 585 585 585 585 585 585 585 ...
    615 615 615 615 615 615];
pos1=[9 12 16 17 6 3];
pos2=[17 16 3 12 9 6];
pause(5)
%%
%5min-spon
ClickOnce(260,50);%开始记录自发电
pause(300)
ClickOnce(260,50);%结束记录
pause(5)
%%
%test1+5min-spon
ClickOnce(260,50);%开始记录
pause(5)
ClickOnce(828,216);%刺激器1
for j=1:30
    for i=1:6
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
    end
    pause(10)
    for i=1:6
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
    end
    pause(10)
end 
ClickOnce(828,216);%刺激器1
ClickOnce(260,50);%结束记录
pause(5)
ClickOnce(260,50);%记录
pause(300)
ClickOnce(260,50);%记录
pause(5)
%%
%train1+5min-spon
ClickOnce(260,50);%开始记录
pause(5)
ClickOnce(856,216);%刺激器1
for j=1:30
    for i=1:6
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
    end
    pause(10)
end 
ClickOnce(856,216);%刺激器1
ClickOnce(260,50);%结束记录
pause(5)
ClickOnce(260,50);%记录
pause(300)
ClickOnce(260,50);%记录
%%
%test2+5min-spon
ClickOnce(260,50);%开始记录

pause(5)
ClickOnce(828,216);%刺激器1
for j=1:30
    for i=1:6
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
    end
    pause(10)
    for i=1:6
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
    end
    pause(10)
end 
ClickOnce(828,216);%刺激器1
ClickOnce(260,50);%结束记录
pause(5)
ClickOnce(260,50);%记录
pause(300)
ClickOnce(260,50);%记录
pause(5)
%%
%train2+5min-spon
ClickOnce(260,50);%开始记录
pause(5)
ClickOnce(856,216);%刺激器1
for j=1:30

    for i=1:6
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
    end
    pause(10)
end 
ClickOnce(856,216);%刺激器1
ClickOnce(260,50);%结束记录
pause(5)
ClickOnce(260,50);%记录
pause(300)
ClickOnce(260,50);%记录
%%
%test3+5min-spon
ClickOnce(260,50);%开始记录
pause(5)
ClickOnce(828,216);%刺激器1
for j=1:30
    for i=1:6
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos1(i)),locy(pos1(i)))
    end
    pause(10)
    for i=1:6
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
        ClickOnce(430,50);%开始刺激
        pause(0.25)
        ClickOnce(locx(pos2(i)),locy(pos2(i)))
    end
    pause(10)
end 
ClickOnce(828,216);%刺激器1
ClickOnce(260,50);%结束记录
pause(5)
ClickOnce(260,50);%记录
pause(300)
ClickOnce(260,50);%记录
pause(5)
 %%
 function ClickOnce(x,y)
import java.awt.Robot;
import iava.awe.event.*;
robot = java.awt.Robot;
robot.mouseMove(-1,-1);
robot.mouseMove(x/1.25,y/1.25);
robot.mousePress (java.awt.event.InputEvent.BUTTON1_MASK);
robot.mouseRelease (java.awt.event.InputEvent.BUTTON1_MASK);
end