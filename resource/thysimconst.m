% this version has timedelays
% Thyroid hormone equations implementation based on 
% May 10, 2012 equations.
% Some equations are set to constants
% $ octave
% octave:1> thyroidglobal2
clc; clear all;

global p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19;
global p20 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 p31 p32 p33 p34 p35 p36;
global p37 p38 p39 p40 p41 p42 p43 p44 p45 p46 p47 p48 kdelay u1 u4;

u1 = 0;        %194.439722;
u4 = 0;
kdelay = 5/8;               %(n-1)/k = t; n comps, t = 8hr

p1 = 0.00168;               %S4
p2 = 8;                     %tau
p3 = 0.868;                 %k12
p4 = 0.108;                 %k13
p5 = 584;                   %k31free
p6 = 1503;                  %k21free
p7 = 0.000289;              %A
p8 = 0.000214;              %B
p9 = 0.000128;              %C
p10 = -8.83*10^-6;          %D
p11 = 0.881;                %k4absorb
p12 = 0.0189;               %k02
p13 = 3.85*10^-4;           %VmaxD1fast
p14 = 2.85;                 %KmD1fast
p15 = 6.63*10^-4;           %VmaxD1slow
p16 = 95;                   %KmD1slow
p17 = 0.00109;              %VmaxD2slow
p18 = 0.075;                %KmD2slow
p19 = 3.71*10^-4;           %S3
p20 = 5.37;                 %k45
p21 = 0.0689;               %k46
p22 = 127;                  %k64free
p23 = 2043;                 %k54free
p24 = 0.00395;              %a
p25 = 0.00185;              %b
p26 = 0.00061;              %c
p27 = 0.000505;             %d
p28 = 0.882;                %k3absorb
p29 = 0.207;                %k05
p30 = 1166;                 %Bzero
p31 = 581;                  %Azero
p32 = 2.37;                 %Amax
%p33 = -3.71;                %phi
p33 = -4.4668;                %phi
p34 = 0.53;                 %kdegTSH-HYPO
p35 = 0.037;                %VmaxTSH
p36 = 23;                   %K50TSH
p37 = 0.118;                %k3
p38 = 0.29;                 %T4P-EU
p39 = 0.006;                %T3P-EU
p40 = 0.037;                %KdegT3B
p41 = 0.0034;               %KLAG-HYPO
p42 = 5;                    %KLAG
p43 = 1.3;                  %k4dissolve
p44 = 0.119;                %k4excrete
p45 = 1.78;                 %k3dissolve
p46 = 0.118;                %k3excrete
p47 = 3;                    %Vp
p48 = 3.5;                  %VTSH

% Equations are in a separate function
function [dqdt] = ODEss(t,q)
global p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19;
global p20 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 p31 p32 p33 p34 p35 p36;
global p37 p38 p39 p40 p41 p42 p43 p44 p45 p46 p47 p48 kdelay u1 u4;

%_____________________________________________________________________
% Auxillaries
%q10init= T4Dose;                                               %T4Dose
%q11init= T3Dose;                                               %T3Dose
q4F= (p24 +p25*q(1) +p26*q(1)^2 +p27*q(1)^3) *q(4);             %FT3p
q1F= (p7 +p8*q(1) +p9*q(1)^2 +p10*q(1)^3) *q(1);                %FT4p
SR3= p19*q(19);%%%%%%%%%%% p2 is tau
SR4= p1*q(19);%%%%%%%%%%%%%
%fCIRC= 1+(p32/(p31*exp(-q(9)))-1)*(1/(1+exp(10*q(9)-55)));
fCIRC= 1;
%SRTSH= (p30 +p31*fCIRC*sin(pi/12*t-p33)) *exp(-q(9));
SRTSH= (p30 +p31*fCIRC*sin(pi/12*t-p33)) *exp(-0.118*q(8));
%SRTSH= 0;
%fdegTSH= p34 +p35/(p36+q(7));
fdegTSH= 0.756;
fLAG= p41 +2*q(8)^11/(p42^11 +q(8)^11);
%f4= p37 +5*p37/(1+exp(2*q(8)-7));
f4= 1;

%p17 = 4*p15;                                                    %80:20 conversion ratio

%_____________________________________________________________________
% ODEs
q1dot= SR4 +p3*q(2) +p4*q(3) -(p5+p6)*q1F +p11*q(11) +u1;       %T4dot
q2dot= p6*q1F -(p3+p12+ p13/(p14+q(2)))*q(2);                   %T4fast
q3dot= p5*q1F -(p4+ p15/(p16+q(3)) +p17/(p18+q(3)))*q(3);       %T4slow
q4dot= SR3 +p20*q(5) +p21*q(6) -(p22+p23)*q4F +p28*q(13) +u4;   %T3pdot
q5dot= p23*q4F +p13*q(2)/(p14+q(2)) -(p20+p29)*q(5);            %T3fast
q6dot= p22*q4F +p15*q(3)/(p16+q(3)) +p17*q(3)/(p18+q(3))-p21*q(6);%T3slow
q7dot= SRTSH -fdegTSH*q(7);                                     %TSHp
%q8dot= f4/p38*q(1) +p37/p39*q(4) -p40*q(8);                     %T3B
q8dot= q(1)/p38 +q(4)/p39 -p40*q(8);                     %T3B
q9dot= fLAG*(q(8)-q(9));                                        %T3B LAG
q10dot= -p43*q(10);                                             %T4PILLdot
q11dot= p43*q(10) - (p44+p11)*q(11);                            %T4GUTdot
q12dot= -p45*q(12);                                             %T3PILLdot
q13dot= p45*q(12) -(p46+p28)*q(13);                             %T3GUTdot

%_____________________________________________________________________
% Delay ODEs
q14dot= -kdelay*q(14) +q(7);                                    %delay1
q15dot= kdelay*(q(14) -q(15));                                  %delay2
q16dot= kdelay*(q(15) -q(16));                                  %delay3
q17dot= kdelay*(q(16) -q(17));                                  %delay4
q18dot= kdelay*(q(17) -q(18));                                  %delay5
q19dot= kdelay*(q(18) -q(19));                                  %delay6

%_____________________________________________________________________
%Outputs
y1= 777*q(1)/(10*p47);
y4= 651*q(4)/p47;
y7= 5.6*q(7)/p48;
y(1) = y1;
y(2) = y4;
y(3) = y7;
y = y';

%%%%%%%%%%%%%%%%%%%%%%%%%_______________________________________
%ODE vector
dqdt(1)=q1dot;
dqdt(2)=q2dot;
dqdt(3)=q3dot;
dqdt(4)=q4dot;
dqdt(5)=q5dot;
dqdt(6)=q6dot;
dqdt(7)=q7dot;
dqdt(8)=q8dot;
dqdt(9)=q9dot;
dqdt(10)=q10dot;
dqdt(11)=q11dot;
dqdt(12)=q12dot;
dqdt(13)=q13dot;
dqdt(14)=q14dot;
dqdt(15)=q15dot;
dqdt(16)=q16dot;
dqdt(17)=q17dot;
dqdt(18)=q18dot;
dqdt(19)=q19dot;
dqdt=dqdt';

endfunction

T4conv  = 777/30;
T3conv  = 651/p47;
TSHconv = 5.6/p48;

%solve
% all ICs 0
%q0 = [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];  % ICs (Note: s0 = e0)
% Sara's ICs. From thyroid_sim.py
%q0 = [0.29084565; 0.17812003; 0.56569934; 0.0071879; 0.01203157; 0.08047781; 2.42113484; 6.24768772; 6.5; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];  % ICs (Note: s0 = e0)
%Marisa's ICs. Transmitted orally from Johnny
%q0 = [0.298; 0.181; 0.581; 0.00584; 0.00994; 0.0491; 1.74; 1.805; 1.805; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];  % ICs (Note: s0 = e0)
% Also Marisa's IC. The ~55 is calculated from 2/0.0386
%q0 = [0.298; 0.181; 0.581; 0.00584; 0.00994; 0.0491; 1.74; 54.805; 1.805; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];  % ICs (Note: s0 = e0)
% Using the SS above to 24 hours and added 400 mcg T4
q0 = [0.30753; 0.18899; 0.57109; 0.0065053; 0.010895; 0.055676; 2.1205; 51.875; 51.769; .515; 0; 0; 0; 4.3401; 5.3306; 6.1941; 6.8059; 7.1011; 7.0728];  % ICs (Note: s0 = e0)
% IC after running to SS using ICs from above.
%q0 = [0.33500; 0.21219; 0.66716; 0.0062479; 0.010644; 0.067288; 1.9199; 6.9864; 6.9861; 0; 0; 0; 0; 3.5876; 3.9612; 4.1594; 4.1804; 4.0486; 3.8069];  % ICs (Note: s0 = e0)
tspan = [0 480];

% default RelTol and AbsTol are 0.000001.
% Increasing all these numbers decreased the solve time. MaxStep seems
% particularly important
%vopt = odeset ('RelTol',1e-4,'AbsTol',1e-4,'InitialStep',1e-1,'MaxStep',1e-2);
vopt = odeset ('NormControl','on','InitialStep',1e-1,'MaxStep',1e-1);
%vopt = odeset ('NormControl','on');
[t,x]=ode23(@ODEss, tspan, q0, vopt);
y(:,1) = x(:,1)*T4conv;
y(:,2) = x(:,4)*T3conv;
y(:,3) = x(:,7)*TSHconv;
subplot(3,1,1);
%plot(t,x(:,1));
plot(t,y(:,1));
axis([0, 480, 0, 13]);
subplot(3,1,2);
%plot(t,x(:,4));
plot(t,y(:,2));
axis([0, 480, 0, 3]);
subplot(3,1,3);
%plot(t,x(:,7));
plot(t,y(:,3));
axis([0, 480, 0, 12]);
% last t appears to be 0.83444

% Printing the output for the interface
%[n m] = size(x);
%printf("START_T4_START\n");
%for i = 1:n
%  printf("%0.4f\n",x(i,1));
%end
%printf("END_T4_END\n");
%
%printf("START_T3_START\n");
%for i = 1:n
%  printf("%0.4f\n",x(i,4));
%end
%printf("END_T3_END\n");
%
%printf("START_TSH_START\n");
%for i = 1:n
%  printf("%0.4f\n",x(i,7));
%end
%printf("END_TSH_END\n");
%
%printf("START_t_START\n");
%for i = 1:n
%  printf("%0.4f\n",t(i));
%end
%printf("END_t_END\n");
