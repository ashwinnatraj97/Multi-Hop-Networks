function [errorRate, modScheme] = turbo_code(RX_SNR, number_trials, info_bit_length, capacity)
    turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port');
    turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4);
    n = log2(turboEnc.TrellisStructure.numOutputSymbols);
    numTails = log2(turboEnc.TrellisStructure.numStates)*n;
    frameLen = info_bit_length;
    
    % Noise Variance
    noiseVar = 1/RX_SNR;
    
    % Error Rate statistics
    numError = 0;
    
    % Defining BPSK Modulator and Demodulator
    bpskmod = comm.BPSKModulator;
    bpskdemod = comm.BPSKDemodulator('DecisionMethod','Log-likelihood ratio', ...
    'Variance',noiseVar);

    % AWGN Channel
%     awgnchan = comm.AWGNChannel('NoiseMethod','Variance','Variance',noiseVar);
    
    for i = 1:number_trials
        M = frameLen*(2*n - 1) + 2*numTails;     % Output codeword packet length
        rate = frameLen/M;                       % Coding rate for current packet
        data = randi([0 1],frameLen,1);
        intrlvrIndices = randperm(frameLen);
        encodedData = turboEnc(data,intrlvrIndices);
        
        % Modulation scheme based on Capacity
%         if (capacity>=10)
%             mod = 1024;
%             modScheme = '1024QAM';
%         else
        if (capacity>=8)
            mod = 256;
            modScheme = '256QAM';
        elseif (capacity>=6)
            mod = 64;
            modScheme = '64QAM';
        elseif (capacity>=4)
            mod = 16;
            modScheme = '16QAM';
        elseif (capacity>=2)
            mod = 4;
            modScheme = 'QPSK';
        else
           mod = 1;
           modScheme = 'BPSK';
        end
        
        % Modulating Coded Data
        if (mod == 1)
            txSymbols = bpskmod(encodedData);
        else
            txSymbols = qammod(encodedData,mod, ...
            'InputType','bit','UnitAveragePower',true);
        end
        
        % Propagation through a LoS channel
        noiseSignal = sqrt(noiseVar/2)*complex(randn(size(txSymbols)),randn(size(txSymbols)));
        rxSymbols = txSymbols + noiseSignal;
%         rxSymbols = awgnchan(txSymbols);
        
        % Demodulation of Rx Symbols
        if (mod == 1)
            demodSignal = bpskdemod(rxSymbols);
        else
            demodSignal = qamdemod(rxSymbols,mod,'OutputType','llr', ...
            'UnitAveragePower',true,'NoiseVariance',noiseVar);
        end
        
        %Decoding the data
        rxBits = turboDec(-demodSignal,intrlvrIndices); % Demodulated signal is negated
        if ~isequal(rxBits,data)
            numError = numError+1;
        end
    end
    errorRate = numError/number_trials;
    fprintf('Codeword error rate = %5.2e\nNumber of errors = %d\nModulation Scheme = %s\nCoding Rate = %f\n', errorRate,numError,modScheme,rate);
end