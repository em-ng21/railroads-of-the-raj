function [r_new, pi] = eq_cond2(r_guess,theta,kRAIN,ePortFE,mu,T,L)


S = size(T);
D = S(1);
P = size(ePortFE,1);
K = S(3);

% create the A matrix (DxK) which is the true exogenous productivity term
% (determined by kappa*RAIN for non-port districts and by the estimated
% exporter FE, adjusted by the land rental rate, for any port city
% location)

A = zeros(D,K);
for d = 1:(D-P)
    A(d,:) = kRAIN(d,:);
end
for d = D-P+1:D
    for k=1:K
        A(d,k) = ePortFE(d-D+P,k)*(r_guess(d))^(theta(k));
    end
end

%creating the rT matrix
%multiply each T_odk with r_o, eg. all T_1dk*r1, T_2dk*r_2 etc
%-> Each column of T elementwise with r
rT = bsxfun(@times,T(:,:,:),r_guess);

%Take each ro*T_odk to the power of -theta(k), eg. all (T_od1*ro)^(-theta(1)), 
rTtheta = bsxfun(@power,rT(:,:,:),reshape(-theta,[1 1 K]));

%multiply each (T_odk*ro)^(-theta(k)) by A_ok, 
%eg. all (T_1d1*r1)^(-theta(1))*A_11
%-> A is reshaped to the dimension (Dx1xK), i.e. o=2, k=4 would be A(2,1,4)
%-> each column of the matrix in dimension k is multiplied elementwise with
% the one column of A in dimension k
ArTtheta = bsxfun(@times,rTtheta(:,:,:),reshape(A,[D 1 K]));

%Function computing p from equation (4) in matrix form...
ptheta = secant_price2(ArTtheta);

%Function computing pi from equation (5) in matrix form...
%ArTtheta  is a DxDxK matrix. multiply each ArTtheta_odk with ptheta_dk, eg. all 
%ArTtheta_o11*ptheta_11, ArTtheta_o12*ptheta_12 etc.
%-> reshape ptheta to 1xDxK (one row per dimension k) and multiply each row o
%per dimension k in ArTtheta element wise with the row of ptheta

pi = bsxfun(@times,ArTtheta,reshape(ptheta,[1 D K]));

%Function solving for r(o) in equation (6) in matrix form...

%multiply each k-dimension of pi with mu(k) elementwise
su = bsxfun(@times,pi,reshape(mu,[1 1 K]));

%mulitply each row of su with the transposed r-column elementwise
su = bsxfun(@times,su,r_guess.');

%multiply each row of su with the transposed L-column elementwise
su = bsxfun(@times,su,L.');

%sum over the k and d dimensions when su was a (DxDxK) matrix
%(row-index o, column-index d and matrix-index k)
su = sum(sum(su(:,:,:),3),2);

%divide the Dx1 vector su elementwise by L
r_new = su./L;
