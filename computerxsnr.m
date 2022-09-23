function snr = computerxsnr(tx_power, d, alpha, N, noise_power)
    snr = pow2db(db2pow(tx_power)*d^-alpha*N^(alpha-1));
    snr = db2pow(snr - noise_power);
end