%%%%%% Script to generate model-predicted self-trade values (for use in
%%%%%% Step 4 analysis, i.e. regression in Table 5)

clear all;

addpath '../../Data/maps/';


% input parameter estimates (mu, kappa, theta) from previous steps:
kappa = double(csvread('kappa.csv',1,0));
theta = double(csvread('thetas.csv',1,0, [1 0 17 0]));
mu = double(csvread('exp_shares.csv',1,0));
delta = 0.1689108;
K = size(mu,1);
P=4;  % number of port city locations

% set negative thetas to the minimum of the positive thetas:
neg = theta<0;
pos = theta>0;
theta_m = min(theta(pos));
theta(neg) = theta_m;


% input agricultural land areas for each district:
Lfile = double(csvread('land_area.csv',1,0));

L = Lfile(:,2);
NP = size(L,1);
L(NP+1:NP+P)=prctile(Lfile(:,2),5);
    
D = size(L,1);

DistID = Lfile(:,1);
for d = 1:P
    DistID(NP+d)=1000000+d;
end
  


% Compute own-distance from area using Mayer-Zignago (2011) formula, and road distance
% conversion from km to LCRED.
area = L*0.004047; %convert area in acres to km2
OwnDist = 2.375*(0.67/sqrt(pi))*sqrt(area);




%% SOLVE EQUILIBRIUM IN EACH YEAR:

%Create temp file for output:
    filename = 'SelfTrade.csv';
    fid = fopen(filename, 'w');

%create Header
    Header = 'distid,year,commodity,theta,mu,SelfTrade \n';
    fprintf(fid, Header);
    fclose(fid);

for yr = 1870:1:1930
    tic
    yr        
    
    RAINfname = ['inputs/RAIN_' num2str(yr) '.csv'];
    RAIN = double(csvread(RAINfname,1,0));
    kRAIN = exp(kappa*RAIN);

    Tfname = ['inputs/LCRED_D2D_alphahat_' num2str(yr) '.csv'];
    LCRED = double(csvread(Tfname,1,0));
    
    
    % district pairs whose LCRED was set in stata to -77777 are self-trade
    % pairs to be given the self-trade distance:
    for o = 1:D
        for d = 1:D
            if LCRED(o,d)==-77777
                LCRED(o,d)=OwnDist(o);
            end
        end
    end
    
    
    T = zeros(D,D,K);
    for k = 1:K
        T(:,:,k) = LCRED.^(delta);
    end
    
        
    FEfname = ['inputs/portFE_' num2str(yr) '.csv'];
    PortFE = double(csvread(FEfname,1,0));
    ePortFE = exp(PortFE);
    zeroFE = PortFE==-99999;
    ePortFE(zeroFE) = 0;
    
    [r, pi] = func_solve2(theta,kRAIN,ePortFE,mu,T,L);
        % Trade flow matrix pi is 3-D (DxDxK) matrix, with elements pi_odk.
    
    Output = zeros([D, 4]);
    for d = 1:D               
        for k = 1:K
            Output(k+(d-1)*K,1) = DistID(d); %district id
            Output(k+(d-1)*K,2) = yr; %year
            Output(k+(d-1)*K,3) = k; %commodity number
            Output(k+(d-1)*K,4) = theta(k); %theta
            Output(k+(d-1)*K,5) = mu(k); %mu
            Output(k+(d-1)*K,6) = pi(d,d,k); %self-trade
        end
    end    
    dlmwrite (filename, Output, '-append', 'precision',12);
    
    if sum(isnan(r),1)>0
        break
    end    
    
    toc
end    
    
    
    
    
    
    
    
    
