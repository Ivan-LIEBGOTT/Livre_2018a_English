% vector definition
X=[0 10 20 30 40];
Y=[2 5 12 25 46];
% find the coefficients for a polynomial p(x) 
% of degree 2 that is a best fit 
A=polyfit(X,Y,2);
% defintion of t vector wich contain 100 elements between 
% the first and the last component of X
t=linspace(X(1),X(end),100);
% definition of U vector wich contain the elements of the 
% interpolation polynomial wich correpond to the 100 elements of t
U=polyval(A,t);
%plot
plot(t,U,'g','Linewidth',3);
hold on;
% marker specification
plot(X,Y,'r.','MarkerSize',25);
grid on;

