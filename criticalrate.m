function rate = criticalrate(rx_snr)
    rate = log(1+rx_snr/2)+(2/(2+rx_snr));
end