% Simulation Parameters
N = 1:6;
alpha = 2:4;
f = 5e+9;
wav = 3e+8/f;
d = 20000; % Distance between the transmitter and receiver
M = 1; % Number of Antennas
code_rate = 1/3;
signal_bandwidth = 1e+6; % 1 MHz Bandwidth Signal
info_bit_length = 2^10;

% Powers in dB
TX_power = -10:5:200;
RX_SNR = zeros(length(alpha), length(N), length(TX_power));
noise_floor = -174 + 10*log10(signal_bandwidth)+2;

% Calculate End-to-end Capacity
per_hop_capacity = zeros(length(alpha),length(N),length(TX_power));
% Probablity of Error
error_rate = zeros(length(alpha),length(N),length(TX_power));

for i = 1:length(alpha)
    R = zeros(length(N),length(TX_power));
    R_hop = zeros(length(N),length(TX_power));
    for j = 1:length(N)
            for k = 1:length(TX_power)
                % Calculating RX SNR for each hop/alpha/Transmit Power
                RX_SNR(i,j,k) = pow2db(db2pow(TX_power(k))*d^-alpha(i)*N(j)^(alpha(i)-1)/M);
                RX_SNR(i,j,k) = db2pow(RX_SNR(i,j,k) - noise_floor);
                R(j,k) = code_rate*log2(det(eye(M)+RX_SNR(i,j,k)));
                % Compute the Probablity of Error for each Recieve SNR
                error_rate(i,j,k) = turbo(RX_SNR(i,j,k), 10, info_bit_length);
            end
    end
    per_hop_capacity(i,:,:) = R;
end

for i = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    R(:,:) = per_hop_capacity(i,:,:);
    hold on;
    for j = 1:length(N)
        SNR_limit = N(j)^((alpha(i)-1)/(N(j)-1))*(d^(alpha(i))/mean_mag_h_sq);
        SNR_limit = pow2db(SNR_limit);
        plot(pow2db(db2pow(TX_power)),abs(R(j,:)),'Color',color(j,:),'LineWidth',1,'DisplayName',j +" Hop Capacity");
        xlim([min(pow2db(db2pow(TX_power))) max(pow2db(db2pow(TX_power)))]);
        if N(j) ~=1
            xline(abs(SNR_limit),'--','Color',color(j,:),'LineWidth',2, 'DisplayName',j +" Hop SNR Limit");
        end
        ylabel("Ergodic Channel Capacity (bits/s/Hz)");
        xlabel('Transmit SNR - \gamma_{Tx}');
    end
    hold off;
    legend('Location','northwest')
end

% Plot Optimal Number of Hops
% for i = 1:length(alpha)
%     R(:,:) = cap_different_alpha(i,:,:);
%     [~,optimal_hop] = max(R);
%     figure;
%     stairs(TX_SNR, optimal_hop,'LineWidth',1);
%     title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
%     xlim([min(TX_SNR) max(TX_SNR)]);
%     ylim([0 N(end)]);
%     xlabel('Transmit SNR - \gamma_{Tx}');
%     ylabel("Optimal Number of Hops");
% end

% Plot Optimal Number of Hops - Asymptotic
hop = zeros(length(alpha), length(TX_power));
for i = 1:length(alpha)
    R(:,:) = per_hop_capacity(i,:,:);
    R_hop(:,:) = hop_different_alpha(i,:,:);
    [~,optimal_hop] = max(R);
    A = TX_power.*(mean_mag_h_sq/d^(-alpha(i)));
    A = A.^(1/(alpha(i)-1));
    hop(i,:) = nearest(-lambertw(-1,-log(A)./A)./log(A));
    figure;
    stairs(TX_power, optimal_hop,'LineWidth',1);
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    xlim([min(TX_power) max(TX_power)]);
    ylim([0 N(end)]);
    xlabel('Transmit SNR - \gamma_{Tx}');
    ylabel("Optimal Number of Hops");
end