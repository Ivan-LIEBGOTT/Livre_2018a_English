%definition af x as a symbolic variable
syms x
%% expandind function
expr1=(x-8)*(x+2)^2
expand(expr1)

%% factoring function
expr2=x^3 - 4*x^2 - 28*x - 32
factor(expr2,x)
