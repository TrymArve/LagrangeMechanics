clc;clear;close all;

GenCoords = {'q1','q2'};
S = MakeSymbolicGenCoords(GenCoords);

syms g Lcm L
S.par = [Lcm,L];

pos_pend = Lcm*arm(q1);
pos_pend_1 = pos_pend + arm(q1);
pos_pend_2 = pos_pend - arm(q1);
pos_wheel = L*arm(q1);
pos_wheel_1 = pos_wheel + arm(q2+q1);
pos_wheel_2 = pos_wheel - arm(q2+q1);
S.pos = {pos_pend,pos_pend_1,pos_pend_2,pos_wheel,pos_wheel_1,pos_wheel_2};

% Define your own mass-names(not necessary, if "MakeLagrange" doesn't fins an "S.mass", it will simply make it own masses)
syms mp mp1 mp2 mw mw1 mw2
S.mass = {mp, mp1, mp2, mw, mw1, mw2};

S = MakeLagrange(S);
EL = S.EL;
disp('EL(inertia not fixed):')
disp(EL)

syms Iw Ip
S.mass = {mw,Iw,mp,Ip}; % Define new masses/inertias after "RepairInertia"
EL = RepairInertia(EL,{'mw','mw1','mw2'},{'mw','Iw'});
EL = RepairInertia(EL,{'mp','mp1','mp2'},{'mp','Ip'});
disp('EL(fixed inertia):')
disp(EL)
%% Extract MCG-form

% define variable vectors
q = [S.q{:}].';
dq = [S.dq{:}].';
mass = [S.mass{:}].';

[EL,M,C,G] = ExtractMCG(EL,GenCoords); 
matlabFunction(M,C,G,'file','MCG','vars',{q,dq,S.par,mass});

%% Simulate
clc;close all;

% define reference handle:
global REF dREF ddREF
omega = 2;
A = pi/5;
REF   = @(t) A*sin(omega*t) - pi/2;
dREF  = @(t) omega*A*cos(omega*t);
ddREF = @(t) -omega^2*A*sin(omega*t);

% configurate:
tf = 30;
init_state = [REF(0) 0, dREF(0) 0];

% define parameters:
g = 9.81;
Lcm = 1;
L1 = 3;
par = [g Lcm L1];

% define masse:
mw = 10;
Iw = 10;
mp = 2;
Ip = 2;
mass = [mw;Iw;mp;Ip];



% set controller parameters:
% PD controller
ctrl.PD.Kp = 100;
ctrl.PD.Kd = -1;
% Feedback Linearization controller
ctrl.FL.Kp = 1;
ctrl.FL.Kd = 100; 
% Any other controllers here:


% SIMULATE:
% set controller:
ctrl.type = 'off';
[tsim,xsim] = ode45(@(t,x) IWPDynamics(t,x,mass,par,ctrl),[0 tf],init_state);

%for plotting several plots:
spn = 1;
spm = 1;
spc = 0;

%get reference
R = REF(tsim);

%PLOT:

spc = spc + 1;
subplot(spn,spm,spc)
addleg_plot(tsim.',xsim.','b-',';',{'q1','q2';2,2});
addleg_plot(tsim.',R','i-',';','R')
title(ctrl.type);


%% Animate
close all;
% Define object to animate:

%pole
obj.pole.type = 'line';
obj.pole.a = @(q) [0;0];
obj.pole.b = @(q) L1*arm(q(1));
obj.pole.color = 'b';

%wheel
obj.wheel.type = {'line','ball'};
obj.wheel.c = @(q) L1*arm(q(1));
radius_w = 0.5;
obj.wheel.r = radius_w;
obj.wheel.a = obj.wheel.c;
obj.wheel.b = @(q) L1*arm(q(1)) + radius_w*arm(q(1)+q(2));

%reference
obj.ref.type = 'line';
obj.ref.a = @(q) [0;0];
obj.ref.b = @(q) L1*arm(q(3));
obj.ref.color = 'r';

% Configure animation settings:
config.simspeed = 2;
config.axis = [-4.6 4.6 -4 4];
config.tf = 15;
Animate(tsim,[xsim(:,[1 2]) R(:)],obj,config)

%%
function[dstate] = IWPDynamics(t, state, mass, par, ctrl)
%Extract info: (unnecessary, but makes it readable)
q1 = state(1);
q2 = state(2);
dq1 = state(3);
dq2 = state(4);

mw = mass(1); % mass of wheel
Iw = mass(2); % inertia of wheel
mp = mass(3); % mass of pole
Ip = mass(4); % inertia of pole

g = par(1);  % gravity field strength
Lcm = par(2);% length from center to center of mass of pole
L1 = par(3); % length of pole (distance to center of wheel)

%define references
global REF dREF ddREF
q1_ref   = REF(t);
dq1_ref  = dREF(t);
ddq1_ref = ddREF(t);

% Controller:
Ctype = string(ctrl.type);
[M,C,G] = MCG([q1;q2],[dq1,dq2],par,mass); %get current dynamics
switch Ctype
    case "off"
        u = 0;
        
    case "PD"
        u = (q1-q1_ref)*ctrl.PD.Kp + (dq1 - dq1_ref)*ctrl.PD.Kd;
        
    case "FL"
        
        v = ddq1_ref + (q1-q1_ref)*ctrl.FL.Kp + (dq1 - dq1_ref)*ctrl.FL.Kd;
        Q = M*[0;v] + C*[dq1;dq2] + G;
        u = Q(2);
    case "any other controller of you liking"
        u = 'some other controller';
        
    otherwise
        u = 0;
end
U = [0;u]; %apply control law as a force on the system


% Dynamics:
ddq = M\(U - C*[dq1;dq2] - G);

dstate = [dq1;dq2;ddq(1);ddq(2)];
end