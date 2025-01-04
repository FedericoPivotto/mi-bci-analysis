%% Function to compute and save the topoplot of the given GDF file
function compute_topoplot(dirpath_in, filename, fileext, dirpath_out)
    % INFO: dirpath_in: 'solution/dataset/micontinuous/<subject>/'
    % INFO: filename: '<filename_without_ext>'
    % INFO: fileext: '.gdf'
    % INFO: dirpath_out: 'solution/result/micontinuous/topoplot/<subject>/' or 'solution/result/micontinuous/topoplot/population/'
    
    file = strcat(dirpath_in,filename,fileext); % path to retrieve the gdf file from

    if strcmpi(fileext,'.gdf') 
        [signal.original,h] = sload(file);
    elseif strcmpi(fileext,'.mat')
        res = load(file); % load of the gdf file
        signal.original = res.s;
        h = res.h;
    end
    

    num_channels = h.NS-1; % h.NS contains the number of channels, the 17th one is just for control purposes during data acquisition
    fs = h.SampleRate; % SampleRate of the signal
    laplacian_mask = load('resource/laplacian16.mat');
    signal.laplacian = signal.original(:,1:num_channels) * laplacian_mask.lap; % application of the laplacian mask to the signal

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
    window_lenght = 1; % lenght in seconds of the window
    numerator = ones(1, window_lenght*fs) * 1/window_lenght * 1/fs; % Forward contribution: vector of equal weights for every value in sample
    denominator = 1; % No backward contribution in MATLAB filter control scheme

    % Computation of the moving average
    signal.mu_mov_avg = filter(numerator, denominator, signal.mu_rectified);
    signal.beta_mov_avg = filter(numerator, denominator, signal.beta_rectified);

    % Trial extraction for the MI tasks (Both Feet - 771, Both Hands - 773, Rest - 783)
    % It seems that there is no rest event even though it is stated in the PDF of the assignment
    
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
    disp(min_duration.single_trial);

    % Creation of trial matrices that will contain fixation, cue and continuous feedback of every single trial of the file
    trial_matrix.mu = zeros(min_duration.single_trial,16,n_trials);
    trial_matrix.beta = zeros(min_duration.single_trial,16,n_trials);
    % Will contain useful info about every trial in the trial_matrix that does not contain the start or trial hit/miss periods
    % [fixation_start, cue_start, cont_feed_start, cue_type]
    trial_info_matrix = zeros(n_trials,4);
    trial_starting_pos = 1; % used for keeping track of the corresponding starting position of every trial
    
    for j = 1 : n_trials
        
        trial_info_matrix(j,1) = trial_starting_pos;
        trial_info_matrix(j,2) = trial_info_matrix(j,1) + min_duration.fix;
        trial_info_matrix(j,3) = trial_info_matrix(j,2) + min_duration.cue;
        trial_info_matrix(j,4) = h.EVENT.TYP(indices.cues(j,1));

        trial_matrix.mu(:,:,j) = signal.mu_mov_avg( h.EVENT.POS(indices.fix(j)) : h.EVENT.POS(indices.fix(j)) + min_duration.single_trial-1, : );
        trial_matrix.beta(:,:,j) = signal.beta_mov_avg( h.EVENT.POS(indices.fix(j)) : h.EVENT.POS(indices.fix(j)) + min_duration.single_trial-1, : );

        trial_starting_pos = trial_starting_pos + min_duration.single_trial;
    end

    mu_fixation_data.feet = trial_matrix.mu(1 : min_duration.fix, : , trial_info_matrix(:,4) == 771);
    mu_fixation_data.hands = trial_matrix.mu(1 : min_duration.fix, : , trial_info_matrix(:,4) == 773);
    mu_fixation_data.rest = trial_matrix.mu(1 : min_duration.fix, : , trial_info_matrix(:,4) == 783); % Might be empty if there are no rest cues 

    beta_fixation_data.feet = trial_matrix.beta(1 : min_duration.fix, : , trial_info_matrix(:,4) == 771);
    beta_fixation_data.hands = trial_matrix.beta(1 : min_duration.fix, : , trial_info_matrix(:,4) == 773);
    beta_fixation_data.rest = trial_matrix.beta(1 : min_duration.fix, : , trial_info_matrix(:,4) == 783); % Might be empty if there are no rest cues 

    mu_reference.feet = repmat(mean( mu_fixation_data.feet), [size(trial_matrix.mu, 1) 1 1]);
    mu_reference.hands = repmat(mean( mu_fixation_data.hands), [size(trial_matrix.mu, 1) 1 1]);
    mu_reference.rest = repmat(mean( mu_fixation_data.rest), [size(trial_matrix.mu, 1) 1 1]);

    beta_reference.feet = repmat(mean( beta_fixation_data.feet), [size(trial_matrix.beta, 1) 1 1]);
    beta_reference.hands = repmat(mean( beta_fixation_data.hands), [size(trial_matrix.beta, 1) 1 1]);
    beta_reference.rest = repmat(mean( beta_fixation_data.rest), [size(trial_matrix.beta, 1) 1 1]);
    

    mu_ERD.feet = 100 * (trial_matrix.mu(:,:,trial_info_matrix(:,4) == 771) - mu_reference.feet)./ mu_reference.feet;
    mu_ERD.hands = 100 * (trial_matrix.mu(:,:,trial_info_matrix(:,4) == 773) - mu_reference.hands)./ mu_reference.hands;
    mu_ERD.rest = 100 * (trial_matrix.mu(:,:,trial_info_matrix(:,4) == 783) - mu_reference.rest)./ mu_reference.rest;

    % Final ERD computation
    

    FixPeriod(1) = 1;
    FixPeriod(2) = min_duration.fix;
    CFPeriod(1) = min_duration.fix+min_duration.cue+1;
    CFPeriod(2) = min_duration.fix+min_duration.cue+min_duration.cont_feed;
    
    ERD_Ref.feet = mean(mean(mu_ERD.feet(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    ERD_Ref.hands = mean(mean(mu_ERD.hands(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    ERD_Ref.rest = mean(mean(mu_ERD.rest(FixPeriod(1):FixPeriod(2), : , : ), 3), 1);
    
    ERD_Act.feet = mean(mean(mu_ERD.feet(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    ERD_Act.hands = mean(mean(mu_ERD.hands(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    ERD_Act.rest = mean(mean(mu_ERD.rest(CFPeriod(1):CFPeriod(2), :, :), 3), 1);
    
    load('resource/chanlocs16.mat'); 
    if not(any(isnan(ERD_Ref.feet(:))))
        figure
        topoplot(squeeze(ERD_Ref.feet), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Feet');
        saveas(gcf,strcat(dirpath_out,"ERD_Reference_both_feet.png"));
        close(gcf);
    end
    if not(any(isnan(ERD_Ref.hands(:))))
        figure
        topoplot(squeeze(ERD_Ref.hands), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Both Hands');
        saveas(gcf,strcat(dirpath_out,"ERD_Reference_both_hands.png"));
        close(gcf);
    end
    if not(any(isnan(ERD_Ref.rest(:))))
        figure
        topoplot(squeeze(ERD_Ref.rest), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Reference Period Rest');
        saveas(gcf,strcat(dirpath_out,"ERD_Reference_rest.png"));
        close(gcf);
    end
    if not(any(isnan(ERD_Act.feet(:))))
        figure
        topoplot(squeeze(ERD_Act.feet), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Feet');
        saveas(gcf,strcat(dirpath_out,"ERD_Activity_both_feet.png"));
        close(gcf);
    end
    if not(any(isnan(ERD_Act.hands(:))))
        figure
        topoplot(squeeze(ERD_Act.hands), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Both Hands');
        saveas(gcf,strcat(dirpath_out,"ERD_Activity_both_hands.png"));
        close(gcf);
    end
    if not(any(isnan(ERD_Act.rest(:))))
        figure
        topoplot(squeeze(ERD_Act.rest), chanlocs16, 'maplimits', [-50 100], 'colormap', jet);
        colorbar;
        subtitle('ERD/ERS Activity Period Rest');
        saveas(gcf,strcat(dirpath_out,"ERD_Activity_rest.png"));
        close(gcf);
    end
    
end