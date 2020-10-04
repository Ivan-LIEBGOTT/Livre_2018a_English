%definition of x a a symbolic variable
syms x
%% %algebraic equation resolution

%equation to solve
equation= x^2+2*x-3==0;
%solution of the equation
solution=solve(equation,x);

disp('The first root is:'),disp (solution(1))
disp('The second root is'),disp (solution(2))