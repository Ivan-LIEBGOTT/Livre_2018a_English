%symbolic variables
syms K;
syms T;
syms t;
syms f(t);
%% f(t) derivatives
D1f=diff(f,1);
D2f=diff(f,2);

%% differential equation definition
equ1=T*D1f+f(t)==K;

%% Resolution
%without initial conditions
dsolve(equ1)

%with initial conditions
dsolve(equ1,f(0)==0)








