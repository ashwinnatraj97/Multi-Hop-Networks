% Gains in dB and Powers in dBm
Pt = 50;
Gt = 10;
Gr = 10;
Pn = -95;

alpha = 3
W = 20e+6;
M = 10;

f = 5e+9;
wav = 3e+8/f;
d = 3000;

di = 10:10:d-10;
K = (db2pow(Pt)*dbm2pow(Gt)*dbm2pow(Gr))/db2pow(Pn)*(wav/(4*pi))^2;
cap = zeros(size(di));
for i = 1:length(di)
    cap(i) = log2(1+K*di(i)^-alpha)+log2(1+K*(d-di(i))^-alpha);
end

T = M./(W*cap);
plot(di,cap);
plot(di,T);