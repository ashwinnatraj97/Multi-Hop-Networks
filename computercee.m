function rcee = computercee(rho, N, snr, rate, capacity)
    if(rate >= capacity)
        rcee = 0;
%         fprintf('Capacity < Rate |Rate - %f | Capacity - %f | SNR - %f(dB) | Hops - %d | RCEE - %f\n', rate, capacity, pow2db(snr), N, rcee);
    end
    if (rate < capacity)
        maximizeRcee = zeros(size(rho));
        for iRho = 1:length(rho)
            maximizeRcee(iRho) = (1/N)*(rho(iRho)*log(1+(snr/(1+rho(iRho)))) - rho(iRho)*rate);
        end
        [rcee,maxIndex] = max(maximizeRcee);
        fprintf('Rate < Capacity | Rate - %f | Capacity - %f | SNR - %f(dB) | Hops - %d | RCEE - %f | rho - %f\n', rate, capacity, pow2db(snr), N, rcee, rho(maxIndex));
    end
end