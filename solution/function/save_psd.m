%% Function to load and process the given GDF file
function save_psd(dirpath_in, filename, fileext, dirpath_out)
    % Load the offline GDF file
    filepath = [dirpath_in, filename, fileext];
    [s, h] = sload(filepath);
    n_channels = h.NS - 1;
    
    % Apply the Laplacian filter. Use the Laplacian mask provided in the moodle.
    disp(pwd);
    lap_mask = load('resource/laplacian16.mat');
    lap_s = s(:, 1:n_channels) * lap_mask.lap;
    
    % Compute the PSD over time exploiting the function proc_spectrogram() provided in the moodle.
    % The parameters for the function are the following:
    PSD_params.wlength = 0.5; % Length of the external window [seconds]
    PSD_params.pshift = 0.25; % Shift of the internal windows [seconds]
    PSD_params.wshift = 0.0625; % Shift of the external window [seconds]
    PSD_params.samplerate = h.SampleRate;
    PSD_params.mlength = 1; % [seconds]
    
    [PSD, FREQ] = proc_spectrogram(lap_s, PSD_params.wlength, PSD_params.wshift, PSD_params.pshift, PSD_params.samplerate, PSD_params.mlength);
    
    % Select only a subset of frequency from the PSD. Use the frequency grid to select meaningful frequencies (e.g., from 4 Hz to 48 Hz, step 2 Hz)
    FREQ_range = 4:2:48; % List with values start:step:end
    [FREQ_subset, FREQ_index] = intersect(FREQ, FREQ_range);
    
    % Recompute the h.EVENT.POS and .DUR with respect to the PSD windows
    PSD_params.winconv = 'backward';
    EVENT.POS = proc_pos2win(h.EVENT.POS, PSD_params.wshift*PSD_params.samplerate, PSD_params.winconv, PSD_params.wlength*PSD_params.samplerate);
    EVENT.DUR = ceil((h.EVENT.DUR / PSD_params.samplerate) / PSD_params.wshift); % Convert number of samples to number of windows
    EVENT.TYP = h.EVENT.TYP;
    
    % Save the PSDs, the selected frequencies, the events, and all the information you consider relevant into a .mat file with the same name of the processed GDF
    if ~exist(dirpath_out, 'dir')
       mkdir(dirpath_out)
    end
    save([dirpath_out, filename, '.mat'], 'PSD', 'PSD_params', 'FREQ', 'FREQ_subset', 'FREQ_index', 'EVENT');
end