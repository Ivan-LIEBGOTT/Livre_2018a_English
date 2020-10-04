hold all;
grid on;
% Kp is varrying from 1 to 10
% launch the simulation of the "oven_data_export_US" model
for Kp=1:10
    sim('oven_data_export_US');
    plot(t,Tf,'LineWidth',2);
end
