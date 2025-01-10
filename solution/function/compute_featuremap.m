%% Function to compute and save the feature map of the given MAT file
function compute_featuremap(dirpath_in, filename, fileext, dirpath_out)
    % INFO: dirpath_in: 'solution/psd/micontinuous/<subject>/', 'solution/psd/micontinuous/population/'
    % INFO: filename: '<filename_without_ext>'
    % INFO: fileext: '.mat'
    % INFO: dirpath_out: 'solution/result/micontinuous/<subject>/featuremap/' or 'solution/result/micontinuous/population/featuremap/'

    % Load file .mat
    filepath = char(strcat(dirpath_in, filename, fileext));
    psd_mat = load(filepath);
    
    % Compute Tk, Ck, CFbK, Pk, Mk
    [psd_mat.LABEL.Tk, psd_mat.LABEL.Ck, psd_mat.LABEL.CFbK, psd_mat.LABEL.Pk, psd_mat.LABEL.Mk] = get_label_vectors(psd_mat.PSD, psd_mat.EVENT, 'offline');
    
    % Compute Fisher's score
    fisher_scores = get_fisher_scores(psd_mat.PSD, psd_mat.LABEL.Pk);
    
    % Plot the feature map
    n_channels = size(psd_mat.PSD, 3); % Number of channels
    channel_labels = {'Fz', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2', 'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
    clim = [0 1]; % Color limits for visualization
    FREQ_subset = psd_mat.FREQ_subset; % Frequency subset for x-axis
    channels = dictionary(channel_labels, 1:n_channels);

    figure('Visible', 'off');
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

    % Check if dirpath_out exists, if not create it
    if ~exist(char(dirpath_out), 'dir')
       mkdir(char(dirpath_out));
    end

    % Save the plot as an image
    image_filename = char(strcat(dirpath_out, 'featuremap.', filename, '.png'));
    saveas(gcf, image_filename);
end
