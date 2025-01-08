%% Function to compute and save the spectrogram of the given MAT file
function compute_spectrogram(dirpath_in, filename, fileext, dirpath_out)
    % Load PSD
    input_file = fullfile(dirpath_in, [filename, fileext]);
    psd_mat = load(input_file);

    % Create a matrix Activity [windows x frequencies x channels x trials].
    fix_event.POS = psd_mat.EVENT.POS(psd_mat.EVENT.TYP == 786);
    fix_event.END = fix_event.POS + ceil(psd_mat.EVENT.DUR(psd_mat.EVENT.TYP == 786));
    fix_event.DUR = fix_event.END - fix_event.POS;
    fix_event.MIN_DUR = min(fix_event.DUR);
    fix_event.MIN_END = fix_event.POS + fix_event.MIN_DUR;
    
    csf_event.POS = psd_mat.EVENT.POS(psd_mat.EVENT.TYP == 781);
    csf_event.END = csf_event.POS + ceil(psd_mat.EVENT.DUR(psd_mat.EVENT.TYP == 781));
    csf_event.DUR = csf_event.END - csf_event.POS;
    csf_event.MIN_DUR = min(csf_event.DUR);
    csf_event.MIN_END = csf_event.POS + csf_event.MIN_DUR;
    
    n_frequencies = size(psd_mat.PSD, 2);
    n_channels = size(psd_mat.PSD, 3);
    n_trials = sum(psd_mat.EVENT.TYP == 786);
    
    cue.both_feet = (psd_mat.EVENT.TYP == 771);
    cue.both_hands = (psd_mat.EVENT.TYP == 773);

    % Each trial ranges from the event related to the fixation cross (TYP=786) to the end of the event related to the continuous feedback (TYP=781)
    % Create a matrix Reference [windows x frequencies x channels x trials] related only to the fixation period
    for i_trial = 1 : n_trials
        psd_trial.TYP(i_trial) = psd_mat.EVENT.TYP((i_trial * 4) - 1);
    
        psd_trial.activity(1:size(fix_event.POS(i_trial):csf_event.MIN_END(i_trial), 2), :, :, i_trial) = psd_mat.PSD(fix_event.POS(i_trial):csf_event.MIN_END(i_trial), 1:n_frequencies, 1:n_channels);
        psd_trial.reference(1:size(fix_event.POS(i_trial):fix_event.MIN_END(i_trial), 2), :, :, i_trial) = psd_mat.PSD(fix_event.POS(i_trial):fix_event.MIN_END(i_trial), 1:n_frequencies, 1:n_channels);
    
        activity.both(1:size(psd_trial.activity, 1), 1:n_frequencies, 1:n_channels, i_trial) = psd_trial.activity(:, :, :, i_trial);
        reference.both(1:size(psd_trial.reference, 1), 1:n_frequencies, 1:n_channels, i_trial) = psd_trial.reference(:, :, :, i_trial);
    end
    
    activity.both_feet = activity.both(:, :, :, psd_trial.TYP == 771);
    activity.both_hands = activity.both(:, :, :, psd_trial.TYP == 773);
    reference.both_feet = reference.both(:, :, :, psd_trial.TYP == 771);
    reference.both_hands = reference.both(:, :, :, psd_trial.TYP == 773);

    % Compute the ERD/ERS for each trial exploiting these two matrices
    baseline.both_feet = repmat(mean(reference.both_feet), [size(activity.both_feet, 1) 1 1 1]);
    baseline.both_hands = repmat(mean(reference.both_hands), [size(activity.both_hands, 1) 1 1 1]);
    ERD.both_feet = log(activity.both_feet ./ baseline.both_feet);
    ERD.both_hands = log(activity.both_hands ./ baseline.both_hands);
    
    % g. Select meaningful channels for the motor imagery task
    mi_channels = [7, 9, 11]; % C3: 7, Cz: 9, C4: 11
    
    % h. Visualize the ERD/ERS averaged across trials for the two MI classes (hint: use the function imagesc())
    figure % Create plot window
    m = 2; n = 3; % Subplots window size
    sgtitle('Average ERD/ERS across Trials');
    clim = [-2.4 0.6];
    
    time_window = psd_mat.PSD_params.wshift; time_range = 0 : time_window : time_window*(size(ERD.both_hands, 1)-1); % Time values from 0
    
    subplot(m, n, 1);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_hands(:, psd_mat.FREQ_index, mi_channels(1), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel C3 | Both hands');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    subplot(m, n, 2);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_hands(:, psd_mat.FREQ_index, mi_channels(2), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel Cz | Both hands');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    subplot(m, n, 3);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_hands(:, psd_mat.FREQ_index, mi_channels(3), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel C4 | Both hands');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    time_window = psd_mat.PSD_params.wshift; time_range = 0 : time_window : time_window*(size(ERD.both_feet, 1)-1); % Time values from 0
    
    subplot(m, n, 4);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_feet(:, psd_mat.FREQ_index, mi_channels(1), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel C3 | Both feet');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    subplot(m, n, 5);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_feet(:, psd_mat.FREQ_index, mi_channels(2), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel Cz | Both feet');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    subplot(m, n, 6);
    imagesc(time_range, psd_mat.FREQ_subset, flip(rot90(mean(ERD.both_feet(:, psd_mat.FREQ_index, mi_channels(3), :), 4), 1), 1), clim);
    xline([3 4], 'LineWidth', 1);
    set(gca, 'YDir', 'normal');
    subtitle('Channel C4 | Both feet');
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');
    colormap hot;
    colorbar;
    
    % Check if dirpath_out exists, if not create it
    if ~isfolder(dirpath_out)
        mkdir(dirpath_out);
    end

    % Save the plot as an image (PNG format)
    image_filename = fullfile(dirpath_out, [filename, '_spectrogram.png']);
    saveas(gcf, image_filename); % Save as PNG
    close(gcf); % Close the figure to free memory
end