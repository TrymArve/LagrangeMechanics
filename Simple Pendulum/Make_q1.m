function q1_expr = Make_q1(q2,ddq2,in3,in4)
%MAKE_Q1
%    Q1_EXPR = MAKE_Q1(Q2,DDQ2,IN3,IN4)

%    This function was generated by the Symbolic Math Toolbox version 8.7.
%    19-May-2021 09:54:25

I2 = in3(3,:);
Lc2 = in4(:,2);
g = in4(:,1);
k = in4(:,3);
m2 = in3(1,:);
q1_expr = (k.*q2+ddq2.*(I2+Lc2.^2.*m2)+Lc2.*g.*m2.*cos(q2))./k;