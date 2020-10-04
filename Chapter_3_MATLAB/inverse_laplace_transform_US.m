%% Symbolic variables
syms t;
syms w;
syms a;

%% Inverse Laplace Transform
syms s
ilaplace(s/(s^2 + w^2))
ilaplace(3/(2+s)-5/(3+s)^2)

