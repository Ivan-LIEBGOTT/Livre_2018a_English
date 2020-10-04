
%--------------------------------------------------------------  
    clc %efface la fenêtre de commande

%-------------------------------------------------------------- 


load ('Reponse_indicielle.txt') % On charge le fichier texte

t = Step_response(:,1); % t vector
x = Step_response(:,3); % x vector
v= Step_response(:,9); % v vector
u= Step_response(:,7); % u vector



%display data

figure;
subplot(2,1,2);
plot(t,u,'LineWidth',2);
xlabel('time (s)')
grid on;
title('input signal: motor supply voltage')


subplot(2,1,1);
plot(t,v,'r','LineWidth',2);
xlabel('time (s)')
grid on;
title('output signal: linear velocity of the axis (mm/s)')

%% iddata element
mydata=iddata(v,u,0.01);

% Identification second order transfetrt function
sys = tfest(mydata,2,0)




