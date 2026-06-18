function y = bpfilter(x, wl, wh, sr,N)
%MY_BPFILTER Applies a bandpass Butterworth filter to input signal
%
%   y = MY_BPFILTER(x, w0, w1, N, bf)
%
%   Inputs:
%       x   - input signal (vector)
%       wl  - lower cutoff frequency (0 < w0 < w1 < 1)
%       wh  - upper cutoff frequency
%       N   - filter order (default = 4)
%       bf  - if true (default), use filtfilt (zero-phase); else use filter (causal)
%
%   Output:
%       y   - filtered signal
   
    if nargin < 4
        N = 4;
    end

 w0=2 * wl / sr; %lower normalized cutoff frequency (0 < w0 < w1 < 1)
 w1=2 * wh / sr; %upper normalized cutoff frequency
    % Check frequency bounds
    if w0 <= 0 || w1 >= 1 || w0 >= w1
        error('Frequencies must satisfy 0 < w0 < w1 < 1');
    end

    % Design bandpass Butterworth filter
    [b, a] = butter(N, [w0, w1], 'bandpass');

    % Apply filtering

        y = filtfilt(b, a, x);  % Zero-phase filtering

end
