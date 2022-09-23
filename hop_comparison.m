close all;
clear;
clc;

% Simulation Parameters
N = 1:6;                                                % Number of Hops
alpha = 2:4;                                            % Environmental Factor
d = 20000;                                              % Distance between the transmitter and receiver
rho = 0:0.0125:1;                                       % Different values of \rho to maximize RCEE
rate = 0:0.05:10;                                       % X-Axis for RCEE
signalBandwidth = 1e6;                                  % Signal Bandwidth
noiseFloor = -204 + 10*log10(signalBandwidth)+2;        % Noise Floor 174 dBm/Hz = -204 dB/Hz


% Powers in dB
txPower = -40:1:15;
rceeTxPower = [-5,0,15];

% Calculate Per-Hop Spectral efficiency
capacity = zeros(length(alpha),length(N),length(txPower));
rxSNR = zeros(length(alpha), length(N), length(txPower));
for iAlpha = 1:length(alpha)
    capPerAlpha = zeros(length(N),length(txPower));
    for jN = 1:length(N)
            for kTxPower = 1:length(txPower)
                % Calculating Receive SNR for each Transmit Power/Hop/Alpha
                rxSNR(iAlpha,jN,kTxPower) = computerxsnr(txPower(kTxPower), d, alpha(iAlpha), N(jN), noiseFloor);
                % Capacity of Each Hop
                capPerAlpha(jN,kTxPower) = computecapacity(rxSNR(iAlpha,jN,kTxPower));
            end
    end
    capacity(iAlpha,:,:) = capPerAlpha;
end

% Random Coding Error Exponent (RCEE)
rcee = zeros(length(alpha),length(rceeTxPower),length(N),length(rate));
criticalRate = zeros(length(alpha),length(rceeTxPower),length(N),length(rate));
for iAlpha = 1:length(alpha)
    rceePerAlpha = zeros(length(rceeTxPower),length(N), length(rate));
    criticalRatePerAlpha = zeros(length(rceeTxPower),length(N), length(rate));
    for jSampleTxPower = 1:length(rceeTxPower)
        rceePerTxPower = zeros(length(N), length(rate));
        for kN = 1:length(N)
            rxSNR = computerxsnr(rceeTxPower(jSampleTxPower), d, alpha(iAlpha), N(kN), noiseFloor);
            capacityRceePerTxPower = computecapacity(rxSNR);
            for lRate = 1:length(rate)
                rceePerTxPower(kN, lRate) = computercee(rho, N(kN), rxSNR, rate(lRate), capacityRceePerTxPower);
            end
        end
        rceePerAlpha(jSampleTxPower,:,:) = rceePerTxPower;
    end
    rcee(iAlpha,:,:,:) = rceePerAlpha;
    criticalRate(iAlpha,:,:,:) = criticalRatePerAlpha;
end

% Visualizations
for iAlpha = 1:length(alpha)    
    color = jet(length(N));
    figure;
    title(['Path Loss Exponent \alpha = ',num2str(alpha(iAlpha))]);
    cap(:,:) = capacity(iAlpha,:,:);
    hold on;
    for jN = 1:length(N)
        plot(txPower,(1/N(jN))*cap(jN,:),'Color',color(jN,:),'LineWidth',1,'DisplayName',jN +" Hop Throughput");
        ylabel("Spectral Efficiency (nats/s/Hz)");
        xlabel('Transmit Power (dB)');
    end
    xlim tight
    hold off;
    legend('Location','northwest')
%     ax = gca;
%     file_name = "rate_alpha_"+num2str(alpha(i))+".eps";
%     exportgraphics(ax,file_name,'Resolution',300);
end

% Visualize RCEE
for iAlpha = 1:length(alpha)
    for jSampleTxPower = 1:length(rceeTxPower)
        rceePerAlphaTxPower(:,:) = rcee(iAlpha, jSampleTxPower, :, :);
        color = jet(length(N));
        figure;
        title(['RCEE | Path Loss Exponent \alpha = ',num2str(alpha(iAlpha)), ' | Transmit Power = ',num2str(rceeTxPower(jSampleTxPower)), '(dB)']);
        hold on;
        for kN = 1:length(N)
            plot(rate, rceePerAlphaTxPower(kN,:), 'Color', color(kN,:),'LineWidth',1,'DisplayName',kN +" Hop");
            ylabel("Random Coding Error Exponent");
            xlabel("Transmission rate (nats/s/Hz)");
        end
        ylim([0 max(rceePerAlphaTxPower, [], 'all')])
        hold off;
        legend('Location','northeast')
    end
end

% % Optimal number of Hops
% for iAlpha = 1:length(alpha)
%     for jSampleTxPower = 1:length(rceeTxPower)
%         rceePerAlphaTxPower(:,:) = rcee(iAlpha, jSampleTxPower, :, :);
%         [~,hops] = max(rceePerAlphaTxPower,[],1);
%         color = jet(length(N));
%         figure;
%         title(['Optimal Number of Hops | Path Loss Exponent \alpha = ',num2str(alpha(iAlpha)), ' | Transmit Power = ',num2str(rceeTxPower(jSampleTxPower)), '(dB)']);
%         hold on;
%         for kN = 1:length(N)
%             plot(rate, rceePerAlphaTxPower(kN,:), 'Color', color(kN,:),'LineWidth',1,'DisplayName',kN +" Hop");
%             ylabel("Random Coding Error Exponent");
%             xlabel("Transmission rate (nats/s/Hz)");
%         end
%         ylim([0 max(rceePerAlphaTxPower, [], 'all')])
%         hold off;
%         legend('Location','northeast')
%     end
% end