function Cpep_mm_mle_A_072814

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Input

tgc = [0	86.68	500.00
2	233.40	501.36
3	238.30	690.53
4	239.19	997.88
5	224.39	911.94
6	222.14	852.81
8	214.41	829.90
10	205.73	816.38
12	200.58	814.95
14	193.50	818.91
16	187.71	791.98
19	179.99	771.72
22	173.55	754.15
25	165.19	788.90
30	156.18	831.65
40	137.84	809.77
50	120.95	834.86
60	104.54	800.89
70	100.68	766.91
80	93.92	704.76
90	85.71	647.97
100	83.78	601.94
110	80.89	551.84
120	80.41	529.95
140	78.96	504.95
160	79.92	483.99
180	81.37	452.30
210	83.30	428.20
240	83.78	437.67]

tspan = tgc(:,1);
%Fixed Cpep_Mini_Model initial conditions & model parameters
h = 93;
k01 = 0.05;
k21 = 0.201;
k12 = 0.052
gamma2 = 0.0142;
CP0 = 1550;
x0(1) = 500;
x0(2) = 0;
Gb = tgc(1,2);

p = [gamma2, h, k01, k21, k12, CP0]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' Enter to continue with MLE'); disp(' ')
pause
if 1
p_init = [gamma2, h, k01, k21, k12, CP0];
%3 known parameters:
p_fix = [x0(1) x0(2)];
end


lb = 0*ones(size(p_init));%[0 0 0 0];
ub = [];%ones(size(p_init));%[];
options = optimset('Display','iter','TolFun', 1e-4,...%'iter' default:1e-4
'TolX',1e-5,... %default: 1e-4
'MaxFunEvals' , [],... %800 default:
'LargeScale','on'); %default: on

plt = 0;

[p_est,resnorm,RESIDUAL,exitflag,OUTPUT,LAMBDA,Jacobian]= lsqnonlin(@err_fn,p_init,lb,ub,options,p_fix,tspan,tgc); 
disp(' ')
%end
%Accuracy:
%lsqnonlin returns the jacobian as a sparse matrix
varp = resnorm*inv(Jacobian'*Jacobian)/length(tspan);
stdp = sqrt(diag(varp)); %The standard deviation is the square root of the variance

% p_est = [gamma1, h, k01, k21, k12, CP0]
p = [p_est(1), p_est(2), p_est(3), p_est(4), p_est(5), p_est(6)];
%x0 = [x0]
x0 = [p_est(6), p_fix(2)];

plt =1;
cpep = cpep_sim(tspan,x0,tgc, p,plt);
figure(1); subplot(121)
h1 = plot(tspan,tgc(:,3),'or', 'Linewidth',2);

disp(' Parameters:')
disp([' gamma2 = ', num2str(p_est(1)), ' +/- ', num2str(stdp(1))])
disp([' h = ', num2str(p_est(2)), ' +/- ', num2str(stdp(2))])
disp([' k01 = ', num2str(p_est(3)), ' +/- ', num2str(stdp(3))])
disp([' k21 = ', num2str(p_est(4)), ' +/- ', num2str(stdp(4))])
disp([' k12 = ', num2str(p_est(5)), ' +/- ', num2str(stdp(5))])
disp([' CP0 = ', num2str(p_est(6)), ' +/- ', num2str(stdp(6))])

disp(' Initial conditions:')
disp([' x0(1) = ', num2str(p_fix(1))])
disp([' x0(2) = ', num2str(p_fix(2))])
disp(' ')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function e = err_fn(p_var, p_fix,tspan,tgc)
p = [p_var(1), p_var(2), p_var(3),p_var(4), p_var(5),p_var(6)];

x0 = [p_var(6), p_fix(2)];
cpep = cpep_sim(tspan,x0,tgc, p,0);
%LSQNONLIN: objective function should return the model error
e = cpep-tgc(:,3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cpep = cpep_sim(tspan,x0,tgc, p,plt)

ode_options = [];
[t,x] = ode45(@ode_fn,tspan,x0,ode_options,tgc,p);

cpep = x(:,1);

if plt==1
cpep_plt(tspan,x,tgc,p)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dx = ode_fn(t,x,tgc,p)
%CPEP_ODE ODE's of C-peptide minimal model

% p_est = [gamma2, h, k01, k21, k12, CP0]
gamma2 = p(1);
h = p(2);
k01 = p(3);
k21 = p(4);
k12 = p(5);
CP0 = p(6);

g = interp1(tgc(:,1),tgc(:,2),t);    % using experimental glucose value over testing time

if g > h
    dCP1 = not(t)*CP0 + gamma2 * (g - h)* t -(k01 + k21)* x(1) + k12*x(2)
    dCP2 = k21 * x(1) - k12 * x(2);
else
    dCP1 = not(t)*CP0 -(k01 + k21)* x(1) + k12*x(2)
    dCP2 = k21 * x(1) - k12 * x(2);
end

dx = [dCP1;dCP2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cpep_plt(tspan,x,tgi,p)
Gb = tgi(1,2);
CPb = tgi(1,3);

figure
subplot(121); h = plot(tspan,x(:,1), '-','Linewidth',2); hold on
plot( [tspan(1) tspan(end)], [CPb CPb], '--k','Linewidth',1.5)
%baseline level
ylabel('Cpep level [uU/mL]')
legend(h, 'model simulation')

g = interp1(tgi(:,1),tgi(:,2), tspan); %reconstruct used input signal
subplot(122); plot(tspan,g, '--or','Linewidth',2); hold on
plot( [tspan(1) tspan(end)], [Gb Gb], '--k','Linewidth',1.5)
%baseline level
ylabel('glucose level [mg/dL]'); xlabel('time [min]')
legend('interpolated measured test data')
        







