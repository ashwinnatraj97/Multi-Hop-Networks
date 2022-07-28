% Simulation Parameters
N = 1:6;
alpha = 2:4;
f = 5e+9;
wav = 3e+8/f;
d = 20000;
iter = 500;
M = 4;

H = zeros(M,M,iter);
mean_mag_h_sq = 0;
for a =1:iter
    H(:,:,a) = sqrt(1/2)*(randn(M,M)+1i*randn(M,M));
    mean_mag_h_sq = mean_mag_h_sq + det(H(:,:,a)*H(:,:,a)');
end
mean_mag_h_sq = mean_mag_h_sq/iter;

% Powers in dB
TX_SNR = -10:5:200;


% Per Hop Spectral Efficiency
hop_different_alpha = zeros(length(alpha),length(N),length(TX_SNR));
% Calculate End-to-end Capacity
cap_different_alpha = zeros(length(alpha),length(N),length(TX_SNR));
for i = 1:length(alpha)
    R = zeros(length(N),length(TX_SNR));
    R_hop = zeros(length(N),length(TX_SNR));
    for j = 1:length(N)
            for k = 1:length(TX_SNR)
                for l = 1:iter
                    H_inst = H(:,:,l);
                    SNR = db2pow(TX_SNR(k))*d^-alpha(i)/M;
                    R(j,k) = R(j,k)+1/N(j)*log2(det(eye(M)+H_inst*H_inst'*SNR*N(j)^(alpha(i)-1)));
                    R_hop(j,k) = R_hop(j,k)+log2(det(eye(M)+H_inst*H_inst'*SNR*N(j)^(alpha(i)-1)));
                end
                R(j,k) = R(j,k)/iter;
                R_hop(j,k) = R_hop(j,k)/iter;
            end
    end
    cap_different_alpha(i,:,:) = R;
    hop_different_alpha(i,:,:) = R_hop;
end

for i = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    R(:,:) = cap_different_alpha(i,:,:);
    hold on;
    for j = 1:length(N)
        SNR_limit = N(j)^((alpha(i)-1)/(N(j)-1))*(d^(alpha(i))/mean_mag_h_sq);
        SNR_limit = pow2db(SNR_limit);
        plot(pow2db(db2pow(TX_SNR)),abs(R(j,:)),'Color',color(j,:),'LineWidth',1,'DisplayName',j +" Hop Capacity");
        xlim([min(pow2db(db2pow(TX_SNR))) max(pow2db(db2pow(TX_SNR)))]);
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
hop = zeros(length(alpha), length(TX_SNR));
for i = 1:length(alpha)
    R(:,:) = cap_different_alpha(i,:,:);
    R_hop(:,:) = hop_different_alpha(i,:,:);
    [~,optimal_hop] = max(R);
    A = TX_SNR.*(mean_mag_h_sq/d^(-alpha(i)));
    A = A.^(1/(alpha(i)-1));
    hop(i,:) = nearest(-lambertw(-1,-log(A)./A)./log(A));
    figure;
    stairs(TX_SNR, optimal_hop,'LineWidth',1);
    title(['Path Loss Exponent \alpha = ',num2str(alpha(i))]);
    xlim([min(TX_SNR) max(TX_SNR)]);
    ylim([0 N(end)]);
    xlabel('Transmit SNR - \gamma_{Tx}');
    ylabel("Optimal Number of Hops");
end