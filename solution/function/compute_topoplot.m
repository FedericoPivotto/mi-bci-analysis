%% Function to compute and save the topoplot of the given GDF file
function compute_topoplot(dirpath_in, filename, fileext, dirpath_out)
    % Path to retrieve the GDF file from
    file = char(strcat(dirpath_in, filename, fileext));
    if strcmpi(fileext,'.gdf') 
        [signal.original,h] = sload(file);
    elseif strcmpi(fileext,'.mat')
        res = load(file);
        signal.original = res.s;
        h = res.h;
    end

    num_channels = h.NS-1; % Number of channels without the 17th which is just for control purposes during data acquisition
    fs = h.SampleRate; % SampleRate of the signal
    laplacian_mask = load('resource/laplacian16.mat');
    signal.laplacian = signal.original(:,1:num_channels) * laplacian_mask.lap; % Application of the Laplacian mask to the signal

    % Definition of the parameters used for the creation of the filters for the mu and beta band
    filter_order = 4;
    mu_freq.low = 8; mu_freq.high = 12;
    beta_freq.low = 18; beta_freq.high = 22;
    
    % Creation of the two butterworth bandpass filters
    [mu_filter.b, mu_filter.a] = butter(filter_order, [mu_freq.low,mu_freq.high]/(fs/2),'bandpass');
    [beta_filter.b, beta_filter.a] = butter(filter_order, [beta_freq.low,beta_freq.high]/(fs/2),'bandpass');
        
    % Application of the two filters to the signal obtained by using the laplacian mask on the original signal
    signal.mu_filtered = filtfilt(mu_filter.b, mu_filter.a, signal.laplacian);
    signal.beta_filtered = filtfilt(beta_filter.b, beta_filter.a, signal.laplacian);

    % Rectification of the signals
    signal.mu_rectified = abs(signal.mu_filtered).^2;
    signal.beta_rectified = abs(signal.beta_filtered).^2;

    % Definition of the moving aberage window parameters
    window_lenght = 1; % Lenght in seconds of the window
    numerator = ones(1, window_lenght*fs) * 1/window_lenght * 1/fs; % Forward contribution: vector of equal weights for every value in sample
    denominator = 1; % No backward contribution in MATLAB filter control scheme

    % Computation of the moving average
    signal.mu_mov_avg = filter(numerator, denominator, signal.mu_rectified);
    signal.beta_mov_avg = filter(numerator, denominator, signal.beta_rectified);
    
    indices.start_trial = find(h.EVENT.TYP(:,1) == 1); % Indices of start events
    indices.fix = find(h.EVENT.TYP(:,1) == 786); % Indices of fixation events
    indices.cues = find(h.EVENT.TYP(:,1) == 771 | h.EVENT.TYP(:,1) == 773 | h.EVENT.TYP(:,1) == 783); % Indices of cue events
    indices.cont_feed = find(h.EVENT.TYP(:,1) == 781); % Indices of continuous feedback events
    indices.hit_miss = find(h.EVENT.TYP(:,1) == 897 | h.EVENT.TYP(:,1) == 898);

    n_trials = size(indices.cont_feed,1); % Retrieve the total number of trials

    min_duration.fix = min(h.EVENT.DUR(indices.fix));
    min_duration.cue = min(h.EVENT.DUR(indices.cues));
    min_duration.cont_feed = min(h.EVENT.DUR(indices.cont_feed));

    % Smallest possible duration of a trial not considering the start event duration
    min_duration.single_trial = min_duration.fix + min_duration.cue + min_duration.cont_feed;

    % Creation of trial matrices that will contain fixation, cue and continuous feedback of every single trial of the file
    trial_matrix.mu = zeros(min_duration.single_trial,16,n_trials);
    trial_matrix.beta = zeros(min_duration.single_trial,16,n_trials);
    % Will contain useful info about every trial in the trial_matrix that does not contain the start or trial hit/miss periods
    trial_info_matrix = zeros(n_trials,4);
    trial_starting_pos = 1; % Used for keeping track of the corresponding starting position of every trial
    
    for j = 1 : n_trials
        
        trial_info_matrix(j,1) = trial_starting_pos;
        trial_info_matrix(j,2) = trial_info_matrix(j,1) + min_duration.fix;
        trial_info_matrix(j,3) = trial_info_matrix(j,2) + min_duration.cue;
        trial_info_matrix(j,4) = h.EVENT.TYP(indices.cues(j,1));

        trial_matrix.mu(:,:,j) = signal.mu_mov_avg( h.EVENT.POS(indices.fix(j)) : h.EVENT.POS(indices.fix(j)) + min_duration.single_trial-1, : );
        trial_matrix.beta(:,:,j) = signal.beta_mov_avg( h.EVENT.POS(indices.fix(j)) : h.EVENT.POS(indices.fix(j)) + min_duration.single_trial-1, : );

        trial_starting_pos = trial_starting_pos + min_duration.single_trial;
    end

    % Definition of fixation periods on both mu and beta bands for the three MI tasks
    mu_fixation_data.feet = trial_matrix.mu(1 : min_duration.fix, : , trial_info_matrix(:,4) == 771);
    mu_fixation_data.hands = trial_matrix.mu(1 : min_duration.fix, : , trial_info_matrix(:,4) == 773);

    beta_fixation_data.feet = trial_matrix.beta(1 : min_duration.fix, : , trial_info_matrix(:,4) == 771);
    beta_fixation_data.hands = trial_matrix.beta(1 : min_duration.fix, : , trial_info_matrix(:,4) == 773);

    % Definition of the reference value in the mu and beta bands, it will be used to determine if a desynchronization or a synchronization has occured

    mu_reference.feet = repmat(mean( mu_fixation_data.feet), [size(trial_matrix.mu, 1) 1 1]);
    mu_reference.hands = repmat(mean( mu_fixation_data.hands), [size(trial_matrix.mu, 1) 1 1]);

    beta_reference.feet = repmat(mean( beta_fixation_data.feet), [size(trial_matrix.beta, 1) 1 1]);
    beta_reference.hands = repmat(mean( beta_fixation_data.hands), [size(trial_matrix.beta, 1) 1 1]);
    
    % Computation of ERD in percentage with respect to the zero defined by the reference period computed above

    mu_ERD.feet = log(trial_matrix.mu(:,:,trial_info_matrix(:,4) == 771)./mu_reference.feet);
    mu_ERD.hands = log(trial_matrix.mu(:,:,trial_info_matrix(:,4) == 773)./mu_reference.hands);

    beta_ERD.feet = log(trial_matrix.beta(:,:,trial_info_matrix(:,4) == 771)./ beta_reference.feet);
    beta_ERD.hands = log(trial_matrix.beta(:,:,trial_info_matrix(:,4) == 773)./ beta_reference.hands);

    % Split of the computed ERD into Reference period (value should be around 0%) and Activity period with respect to the baseline defined by the reference period

    FixPeriod(1) = 1; % Starting index of every fixation period is the same
    FixPeriod(2) = min_duration.fix; % Ending index of every fixation period is the same
    CFPeriod(1) = min_duration.fix+min_duration.cue+1; % Starting index of every continuous feedback period is the same
    CFPeriod(2) = min_duration.fix+min_duration.cue+min_duration.cont_feed; % Ending index of every continuous feedback period is the same
    
    ERD_Ref_mu.feet = mean(mean(mu_ERD.feet(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    ERD_Ref_mu.hands = mean(mean(mu_ERD.hands(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    
    ERD_Act_mu.feet = mean(mean(mu_ERD.feet(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    ERD_Act_mu.hands = mean(mean(mu_ERD.hands(CFPeriod(1):CFPeriod(2), :, :), 3), 1);

    ERD_Ref_beta.feet = mean(mean(beta_ERD.feet(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    ERD_Ref_beta.hands = mean(mean(beta_ERD.hands(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    
    ERD_Act_beta.feet = mean(mean(beta_ERD.feet(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    ERD_Act_beta.hands = mean(mean(beta_ERD.hands(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    
    % Load of the file containing the position of the electrodes
    load('resource/chanlocs16.mat');

    % Check if dirpath_out exists, if not create it
    if ~exist(char(dirpath_out), 'dir')
       mkdir(char(dirpath_out));
    end

    % Plot mu ERD/ERS topoplot

    if not(any(isnan(ERD_Ref_mu.feet(:)))) % check if the ERD contains NaN values, if not then plot
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Ref_mu.feet), chanlocs16, 'maplimits', [-2.4 0.6],  'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Feet mu band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_reference_bothfeet_mu_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Ref_mu.hands(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Ref_mu.hands), chanlocs16, 'maplimits', [-2.4 0.6],  'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Hands mu band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_reference_bothhands_mu_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Act_mu.feet(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Act_mu.feet), chanlocs16, 'maplimits', [-2.4 0.6],  'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Feet mu band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_activity_bothfeet_mu_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Act_mu.hands(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Act_mu.hands), chanlocs16, 'maplimits', [-2.4 0.6], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Hands mu band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_activity_bothhands_mu_band.', filename, '.png')));
    end
    
    % Plot beta ERD/ERS topoplot

    if not(any(isnan(ERD_Ref_beta.feet(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Ref_beta.feet), chanlocs16, 'maplimits', [-2.4 0.6], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Feet beta band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_reference_bothfeet_beta_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Ref_beta.hands(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Ref_beta.hands), chanlocs16, 'maplimits', [-2.4 0.6], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Hands beta band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_reference_bothhands_beta_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Act_beta.feet(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Act_beta.feet), chanlocs16, 'maplimits', [-2.4 0.6], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Feet beta band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_activity_bothfeet_beta_band.', filename, '.png')));
    end
    if not(any(isnan(ERD_Act_beta.hands(:))))
        figure('Visible', 'off');
        topoplot(squeeze(ERD_Act_beta.hands), chanlocs16, 'maplimits', [-2.4 0.6], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Hands beta band');
        saveas(gcf, char(strcat(dirpath_out, 'erd_activity_bothhands_beta_band.', filename, '.png')));
    end
end