function [error_rate, mod] = turbo(RX_SNR, number_of_frames, info_bit_length, capacity)
    pkt_error = 0;
    noise_var = 1/RX_SNR;
%     if (capacity>=10)
%         mod = '1024QAM';
%     elseif (capacity>=8)
%         mod = '256QAM';
%     else
    if (capacity>=6)
        mod = '64QAM';
    elseif (capacity>=4)
        mod = '16QAM';
    elseif (capacity>=2)
        mod = 'QPSK';
    else
       mod = 'BPSK';
    end
    for i = 1:number_of_frames
        txBits = randi([0 1],info_bit_length,1);
        codedData = lteTurboEncode(txBits);
        txSymbols = lteSymbolModulate(codedData,mod);
        noise = sqrt(noise_var/2)*complex(randn(size(txSymbols)),randn(size(txSymbols)));
        rxSymbols = txSymbols + noise;
        
        %scatter(real(rxSymbols),imag(rxSymbols),'co'); 
        %hold on;

        %scatter(real(txSymbols),imag(txSymbols),'rx')
        %legend('Rx constellation','Tx constellation')
        
        softBits = lteSymbolDemodulate(rxSymbols,mod,'Soft');
        rxBits = lteTurboDecode(softBits);
        if ~isequal(txBits, rxBits)
            pkt_error = pkt_error + 1;
        end
    end
    error_rate = pkt_error/number_of_frames;
end
