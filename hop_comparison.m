close all;
clear;
clc;
% Simulation Parameters
N = 1:6;                                                % Number of Hops
alpha = 2:4;                                            % Environmental Factor
f = 5e+9;                                               % Carrier Frequency
d = 20000;                                              % Distance between the transmitter and receiver
M = 1;                                                  % Number of Antennas (M x M) UPA
code_rate = 1/3;                                        % LTE Turbo Code Rate
number_of_code_blocks = 50;                             % Number of Code Blocks for Probablity of Error Calculation
signal_bandwidth = 1e+6;                                % 1 MHz Bandwidth Signal
info_bit_length = 2^9 ;                                 % Information Block Size (The Block Length Becomes 6144)
decode_delay = 5/signal_bandwidth;                      % Decoding Delay at Relay/Rx

% Powers in dB
TX_power = -40:1:15;
RX_SNR = zeros(length(alpha), length(N), length(TX_power));
noise_floor = -204 + 10*log10(signal_bandwidth)+2;      % Noise Floor 174 dBm/Hz = -204 dB/Hz

% Calculate End-to-end Capacity
per_hop_capacity = zeros(length(alpha),length(N),length(TX_power));
transmission_rate = zeros(length(alpha),length(N),length(TX_power));
% Probablity of Error for each Transmit Power/Hop/Alpha
error_rate = zeros(length(alpha),length(N),length(TX_power));
% Total Latency of Multi-Hop Network
latency = zeros(length(alpha),length(N),length(TX_power));
% Total Througput of Multi-Hop Network
throughput = zeros(length(alpha),length(N),length(TX_power));

for i = 1:length(alpha)
    R = zeros(length(N),length(TX_power));
    for j = 1:length(N)
            for k = 1:length(TX_power)
                % Calculating Receive SNR for each Transmit Power/Hop/Alpha
                RX_SNR(i,j,k) = pow2db(db2pow(TX_power(k))*d^-alpha(i)*N(j)^(alpha(i)-1)/M);
                RX_SNR(i,j,k) = db2pow(RX_SNR(i,j,k) - noise_floor);
                % Capacity of Each Hop for the received SNR
                R(j,k) = log2(det(eye(M)+(1/M)*RX_SNR(i,j,k)));
                % Compute the Probablity of Error for each Recieve SNR
                [error_rate(i,j,k), mod_scheme] = turbo(RX_SNR(i,j,k), number_of_code_blocks, info_bit_length, R(j,k));
%                 [error_rate(i,j,k), mod_scheme] = turbo_code(RX_SNR(i,j,k), number_of_code_blocks, info_bit_length, R(j,k));

                switch mod_scheme              
                    case '64QAM'
                        bits_per_symbol = 6;
                    case '16QAM'
                        bits_per_symbol = 4;
                    case 'QPSK'
                        bits_per_symbol = 2;
                    otherwise
                        bits_per_symbol = 1;
                end
                transmission_rate(i,j,k) = bits_per_symbol * code_rate * signal_bandwidth;
                fprintf('Codeblock Error Rate - %f | Rx SNR = %fdB | Tx Power = %fdB | Modulation Scheme - %s | %d Hops | Alpha - %d | Capacity/Hop - %f\n', error_rate(i,j,k), pow2db(RX_SNR(i,j,k)), TX_power(k), mod_scheme, N(j), alpha(i), R(j,k));
%                 fid = fopen('log.txt', 'a+');
%                 fprintf(fid, 'Codeblock Error Rate - %f | Rx SNR = %fdB | Tx Power = %fdB | Modulation Scheme - %s | %d Hops | Alpha - %d | Capacity/Hop - %f\n', error_rate(i,j,k), pow2db(RX_SNR(i,j,k)), TX_power(k), mod_scheme, N(j), alpha(i), (1/code_rate)*R(j,k));
%                 fclose(fid);
            end
    end
    per_hop_capacity(i,:,:) = R;
end

% Calculating Latency and End-to-End Througput
% Loading Precomputed Monte Carlo Simulation Values
% load error_rate.mat;
% load transmission_rate.mat;

for i = 1:length(alpha)
    for j = 1:length(N)
        for k = 1:length(TX_power)
            latency(i,j,k) = N(j)* info_bit_length/((1-error_rate(i,j,k))*transmission_rate(i,j,k)) + N(j)*decode_delay/(1-error_rate(i,j,k));
            throughput(i,j,k) = info_bit_length/latency(i,j,k);
        end
    end
end

for i = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    R(:,:) = throughput(i,:,:);
    cap(:,:) = per_hop_capacity(i,:,:);
    hold on;
    for j = 1:length(N)
        plot(TX_power,abs(R(j,:)),'Color',color(j,:),'LineWidth',1,'DisplayName',j +" Hop Throughput");
        ylabel("Throughput (bits/s)");
        xlabel('Transmit Power (dB)');
    end
    xlim tight
    hold off;
    legend('Location','northwest')
%     ax = gca;
%     file_name = "rate_alpha_"+num2str(alpha(i))+".eps";
%     exportgraphics(ax,file_name,'Resolution',300);
end

% Visualize Probablity of Error
for i = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    R(:,:) = error_rate(i,:,:);
    hold on;
    for j = 1:length(N)
        plot(TX_power,R(j,:),'Color',color(j,:),'LineWidth',1,'DisplayName',j +" Hop Error Rate");
        ylabel("Codeword Error Rate");
        xlabel('Transmit Power (dB)');
    end
    xlim tight
    hold off;
    legend('Location','northwest')
%     ax = gca;
%     file_name = "error_rate_apha"+num2str(alpha(i))+".eps";
%     exportgraphics(ax,file_name,'Resolution',300);
end

for i = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    R(:,:) = throughput(i,:,:);
    cap(:,:) = per_hop_capacity(i,:,:);
    hold on;
    for j = 1:length(N)
        plot(TX_power,abs(R(j,:)),'Color',color(j,:),'LineWidth',1,'DisplayName',j +" Hop Throughput");
        plot(TX_power,(1/N(j))*signal_bandwidth*cap(j,:),'--','Color',color(j,:),'LineWidth',1, 'DisplayName',j +" Hop Max Achieveable Rate");
        ylabel("Transmission Rate (bits/s)");
        xlabel('Transmit Power (dB)');
    end
    xlim tight
    hold off;
    legend('Location','northwest')
%     ax = gca;
%     file_name = "rate_and_cap_alpha_"+num2str(alpha(i))+".eps";
%     exportgraphics(ax,file_name,'Resolution',300);
end