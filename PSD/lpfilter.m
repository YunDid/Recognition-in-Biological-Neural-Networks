function y = lpfilter(x, w,sr, N)
%MY_LPFILTER Applies a zero-phase low-pass Butterworth filter to input signal
%
%   y = MY_LPFILTER(x, w0, N)
%   Inputs:
%       x  - input signal (vector)
%       w -  cutoff frequency
%       sr - sampling_rate
%       N  - filter order (default: 4)
%
%   Output:
%       y  - filtered signal (zero-phase distortion using filtfilt)
%
%   This function uses a Butterworth low-pass filter and zero-phase filtering.
%   See also BUTTER, FILTFILT

if nargin < 3
    N = 4; % default order
end
w0 = 2 * w / sr;%w0 = 2 * cutoff_freq / sampling_rate,- normalized cutoff frequency (between 0 and 1)
% Check w0 validity
if w0 <= 0 || w0 >= 1
    error('w0 must be in the range (0,1)');
end

% Design Butterworth filter
[b, a] = butter(N, w0, 'low');

% Apply zero-phase filtering
y = filtfilt(b, a, x);
end
