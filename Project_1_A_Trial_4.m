% Version: Channel equalization using unknown H(k)
% Using IIR Channel instead
clc; clear all; close all
%% Generate bits
N = 128;
b = randsrc(1,2*N,[-1 1]);
%% Add training Bits
b = [1,1,b(1:64),1,1,b(65:128),1,1,b(129:192),1,1,b(193:end)];
%% Bits2Symbols Using QPSK
M = 4; % Number of symbols in QPSK
m = log2(M); % Bits per Symbol
s_QPSK = [(1 + 1i) (1 - 1i) (-1 -1i) (-1 + 1i)]/sqrt(2); % QPSK Symbols
b_buffer = buffer(b, m)'; % Group bits into bits per symbol
s = zeros(N+4,1);
% Look up symbols using the indices
for k=1:N+4 % 4 extra training symbols
    if b_buffer(k,:) == [1 1]
        s(k) = 1 + 1i;
    elseif b_buffer(k,:) == [1 -1]
        s(k) = 1 - 1i;
    elseif b_buffer(k,:) == [-1 -1]
        s(k) = -1 - 1i;
    else
        s(k) = -1 + 1i;
    end
end
%% Generate OFDM Seuqence
zz = ifft(s);
%% Channel Description
h = zeros(N+4,1); % Channel 1
for n=1:N+4
    h(n) = 0.8^(n-1);
end
H = fft(h,N+4); % DTFT
%% Decide and Add Cyclic Prefix
% IIR the beta should be one
beta = 1; % Parameter deciding how long the cyclic prefix
len_cp_c = ceil(length(h)*beta); % Length of cyclic prefix
cyclic_prefix_c = zz(end-len_cp_c+1:end); % Cyclic prefix
zz = [cyclic_prefix_c;zz]; % Add cyclic prefix to the front
y_len = length(zz)+length(h)-1;
%% Generate Noise Sequence
sigma = 0.02; % Noise level
w = 1/sqrt(2)*sigma*(randn(y_len,1) + 1i*randn(y_len,1)); % AWGN Channel1
%% Generate Received Signal
y = conv(h,zz) + w;
y = y(1:length(zz)); % Remove convolution redundancy
y = y(len_cp_c+1:end); % Remove cyclic prefix
%% OFDM Decoding 
r = fft(y);
%% Channel Equalization With unknown H(k)
ss = zeros(N+4,1);
HH = zeros(N+4,1); % Guessed H(k)
trainingSymbol = 1 + 1i;

ss(1) = trainingSymbol;
HH(1)=r(1)/ss(1);
for k=1:32 % For loop used for decision feedback
    HH(k+1)=r(k)/ss(k);
    ss(k+1) = sign(real(r(k+1).*conj(HH(k+1))))+1j*sign(imag(r(k+1).*conj(HH(k+1))));
end

ss(34) = trainingSymbol;
HH(34)=r(34)/ss(34);
for k=34:65 % For loop used for decision feedback
    HH(k+1)=r(k)/ss(k);
    ss(k+1) = sign(real(r(k+1).*conj(HH(k+1))))+1j*sign(imag(r(k+1).*conj(HH(k+1))));
end

ss(67) = trainingSymbol;
HH(67)=r(67)/ss(67);
for k=67:98 % For loop used for decision feedback
    HH(k+1)=r(k)/ss(k);
    ss(k+1) = sign(real(r(k+1).*conj(HH(k+1))))+1j*sign(imag(r(k+1).*conj(HH(k+1))));
end

ss(100) = trainingSymbol;
HH(100)=r(100)/ss(100);
for k=100:131 % For loop used for decision feedback
    HH(k+1)=r(k)/ss(k);
    ss(k+1) = sign(real(r(k+1).*conj(HH(k+1))))+1j*sign(imag(r(k+1).*conj(HH(k+1))));
end
%% Symbols2Bits
bb = zeros(1,2*(N+4)); % Bits received
for k=1:N+4
    bb(2*k-1) = real(ss(k));
    bb(2*k) = imag(ss(k));
end
%% Bits error calculating
diff=b-bb;
error=find(diff~=0);
errorrate=length(error)/(2*N);
%% Some plots
figure;
plot(real(r));hold on;
plot(real(ss));hold on;
plot(real(s));hold on;
xlabel('k');
ylabel('amplitude');
title('Comparison between r(k),real s(k) and estimated s(k)');
legend('r(k)','estimated s(k)','real s(k)');
figure;
plot(real(H));hold on;
plot(real(HH));hold on;
xlabel('k');
ylabel('amplitude');
title('Comparison between real H(k) and estimated H(k)');
legend('real H(k)','estimated H(k)');