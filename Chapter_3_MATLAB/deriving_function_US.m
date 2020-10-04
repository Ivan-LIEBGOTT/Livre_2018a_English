%% deriving a function 
%definition of t as a symbolic varaible
syms t
%function to derive
f=sin(t)+3*t^3;

%first derivative calculation
df=diff(f,t)

%fifth derivative calculation
d5f=diff(f,t,5)


