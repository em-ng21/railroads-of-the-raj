%Price Equation (4), solved numerically in matrix form using the guessed
%rent vector r_guess
function ptheta = secant_price2(ArTtheta)

S = size(ArTtheta);
D = S(1);
K = S(3);


%sum over all o and make the matrix 2-dimensional (DxK) with a reshape
test = sum(ArTtheta(:,:,:),1);



test(1,D-5:D,1);
test(1,D-5:D,4);


p = reshape(sum(ArTtheta(:,:,:),1),[D K]);

%NB: k is now the column-index, not the matrix index

ptheta = bsxfun(@power,p(:,:),-1);

%Note, multiplying by lambda is not necessary as it falls out when
%substiuting into equation (5)

