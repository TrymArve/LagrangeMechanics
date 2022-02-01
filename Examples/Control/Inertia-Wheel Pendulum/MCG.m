function [M,C,G] = MCG(in1,in2,in3,in4)
%MCG
%    [M,C,G] = MCG(IN1,IN2,IN3,IN4)

%    This function was generated by the Symbolic Math Toolbox version 9.0.
%    01-Feb-2022 14:58:08

Ip = in3(4,:);
Iw = in3(2,:);
L = in4(3,:);
L_cm = in4(2,:);
g = in4(1,:);
mp = in3(3,:);
mw = in3(1,:);
q1 = in1(1,:);
t2 = L.*mw;
t3 = L_cm.*mp;
M = reshape([Ip+L.*t2+L_cm.*t3,0.0,0.0,Iw],[2,2]);
if nargout > 1
    C = reshape([0.0,0.0,0.0,0.0],[2,2]);
end
if nargout > 2
    G = [-g.*sin(q1).*(t2+t3);0.0];
end
