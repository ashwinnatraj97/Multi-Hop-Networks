function [error_rate] = turbo(RX_SNR, number_of_frames, info_bit_length)
    pkt_error = 0;
    noise_var = 1;
    for i = 1:number_of_frames
        txBits = randi([0 1],info_bit_length,1);
        codedData = lteTurboEncode(txBits);
        txSymbols = lteSymbolModulate(codedData,'BPSK');
        noise = sqrt(noise_var/2)*complex(randn(size(txSymbols)),randn(size(txSymbols)));
        rxSymbols = sqrt(RX_SNR/2)*txSymbols + noise;

        softBits = lteSymbolDemodulate(rxSymbols,'BPSK','Soft');
        rxBits = lteTurboDecode(softBits);
        if ~isequal(txBits, rxBits)
            pkt_error = pkt_error + 1;
        end
    end
    error_rate = pkt_error/number_of_frames;
end
