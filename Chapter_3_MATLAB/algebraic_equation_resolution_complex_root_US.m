%definition of x as a symbolic variable
syms x
%% %resolution of an algebraic equation (complex roots)

%equation to solve
equation= x^2+2*x+5==0;
%Resolution
solution=solve(equation,x);

disp('The first root is:'),disp (solution(1))
disp('The second root is:'),disp (solution(2))


