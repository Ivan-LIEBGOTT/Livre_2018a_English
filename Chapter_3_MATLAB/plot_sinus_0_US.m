% definition of vector t
t=[0:0.01:2*pi];
% hold all command is the same as hold on but 
% each curve is plot with a different color
hold all;
for a=[1:4]
    plot(t,sin(a*t),'Linewidth',2);
end
grid on
title('Sinus function')

%You can use Tex command in your equations
xlabel('angle \theta in radians');
ylabel('f(\theta)=sin(a.\theta)')
axis([-1 7 -1.5 1.5])





