%symbolic variables
syms t;
syms f(t);

%% f(t) derivatives
D1f=diff(f,1);
D2f=diff(f,2);

%% First example
equ1=5*D2f+3*D1f+f==2
sol1=dsolve(equ1,f(0)==0,D1f(0)==0)

%plot
figure;
ezplot(sol1,[0,40,0,3])
legend('first example solution')
grid on

%Second example
equ2=5*D2f+1*D1f+f==2
sol2=dsolve(equ2,f(0)==0,D1f(0)==0)

%plot
figure;
ezplot(sol2,[0,70,0,4])
legend('second example solution')

grid on;






