%% Laplace Transform
syms t;
syms w;
syms a;
laplace(sin(w*t))
laplace(cos(w*t))
laplace(exp(-a*t)*cos(w*t))
laplace(exp(-a*t)*sin(w*t))
