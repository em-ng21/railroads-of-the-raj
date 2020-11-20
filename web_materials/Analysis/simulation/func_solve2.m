function [r, pi] = func_solve2(theta,kRAIN,ePortFE,mu,T,L)

S = size(T);
D = S(1);
K = S(3);

crit = 1;
r_guess = unifrnd(0.01,2000,D,1);

iter = 1;
display('solving...')
while crit>10e-10 && iter < 1000
    [r_new, pi] = eq_cond2([r_guess],theta,kRAIN,ePortFE,mu,T,L);
    
    r_new = r_new./r_new(1); 
    crit = norm(r_new-r_guess);
    r_guess = 0.9*r_guess + 0.1*r_new;
    iter = iter+1;
end
if(iter == 1000 && crit > crit>10e-10)
display('Solution not found in <1000 iterations')
else  
[r, pi] = eq_cond2(r_new,theta,kRAIN,ePortFE,mu,T,L); 
display('Solution found')
end;



