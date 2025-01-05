%% Function to compute and save the feature map of the given MAT file
function compute_featuremap(dirpath_in, filename, fileext, dirpath_out)
    % INFO: dirpath_in: 'solution/psd/<subject>/', or 'solution/psd/population/'
    % INFO: filename: '<filename_without_ext>'
    % INFO: fileext: '.mat'
    % INFO: dirpath_out: 'solution/result/micontinuous/featuremap/<subject>/', 'solution/result/micontinuous/featuremap/population/'

    % NOTE: there is the need to use the functions get_fisher_scores and get_label_vectors

    % 1. Load file .mat
    filepath_in = fullfile(dirpath_in, [filename, fileext]);
    psd_mat = load(filepath_in);
    
    % 2. Compute Tk, Ck, CFbK, Pk, Mk
    [psd_mat.LABEL.Tk, psd_mat.LABEL.Ck, psd_mat.LABEL.CFbK, psd_mat.LABEL.Pk, psd_mat.LABEL.Mk] = get_label_vectors(psd_mat.PSD, psd_mat.EVENT, 'offline');
    
    % 3. Compute Fisher's score
    fisher_scores = get_fisher_score(psd_mat.PSD, psd_mat.LABEL.Pk);
    
    % 4. Save feature's map
    featuremap_filename = fullfile(dirpath_out, [filename, '_featuremap', fileext]);
    save(featuremap_filename, 'fisher_scores');

     % 5. Visualize the feature map
    n_channels = size(psd_mat.PSD, 3); % Number of channels
    channel_labels = {'Fz', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2', 'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
    clim = [0 1]; % Color limits for visualization
    FREQ_subset = psd_mat.FREQ_subset; % Frequency subset for x-axis
    channels = dictionary(channel_labels, 1:n_channels);

    figure;
    imagesc(FREQ_subset, 1:n_channels, flip(rot90(fisher_scores, 1), 1), clim);
    colorbar;
    set(gca, ...
        'Title', text('String', ['Feature Map: ', filename]), ...
        'XLabel', text('String', 'Frequency [Hz]'), ...
        'YLabel', text('String', 'Channel'), ...
        'XTickLabelRotation', 90, ...
        'XTick', FREQ_subset, ...
        'YTickLabel', keys(channels), ...
        'YTick', values(channels));
end