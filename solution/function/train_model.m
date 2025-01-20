%% Function to train the model for the given MAT file
function train_model(dirpath_in, filename, fileext, dirpath_out, dirpath_res)
    % Load PSD
    filepath = char(strcat(dirpath_in, filename, fileext));
    psd_mat = load(filepath);

    % Extract label vectors using the EVENT field
    [psd_mat.LABEL.Tk, psd_mat.LABEL.Ck, psd_mat.LABEL.CFbK, psd_mat.LABEL.Pk, psd_mat.LABEL.Mk] = get_label_vectors(psd_mat.PSD, psd_mat.EVENT, 'offline');
    
    % Check if dirpath_out exists, if not create it
    if ~exist(char(dirpath_out), 'dir')
       mkdir(char(dirpath_out));
    end

    % Features attributes
    n_channels = size(psd_mat.PSD, 3);
    channel_labels = {'Fz', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2', 'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
    channels = dictionary(channel_labels, 1:n_channels);
    frequencies = dictionary(psd_mat.FREQ_subset, psd_mat.FREQ_index);

    % Dimensions
    n_windows = size(psd_mat.PSD, 1);
    n_frequencies = size(psd_mat.PSD, 2);
    n_channels = size(psd_mat.PSD, 3);
    n_features = n_frequencies * n_channels;  
    
    % Get subject ID
    subject_id = char(extractBefore(filename, '.'));
    % Select the most discriminative features
    features = load(char(strcat(dirpath_res, '/features.mat')));
    channel = features.(subject_id).channel;
    frequency = features.(subject_id).frequency;
    selected_features = [];
    for i = 1:size(channel, 2)
        selected_features = [selected_features; frequencies(cell2mat(frequency(i))), channels(channel(i))];
    end
    
    % Extract features from matrix
    FeaturesIdx = sub2ind([n_frequencies, n_channels], selected_features(:, 1), selected_features(:, 2));
    
    % Train a model with the data
    psd_mat.PSD_feature = reshape(psd_mat.PSD, n_windows, n_features); % [windows x features]
    LabelIdx = psd_mat.LABEL.CFbK == 781 & psd_mat.LABEL.Mk == 0; % Offline data during continuous feedback
    
    % Train model
    Model = fitcdiscr(psd_mat.PSD_feature(LabelIdx, FeaturesIdx), psd_mat.LABEL.Pk(LabelIdx), 'DiscrimType','quadratic');
    
    % Evaluate the model with data
    [Gk, pp] = predict(Model, psd_mat.PSD_feature(LabelIdx, FeaturesIdx));
    
    % Compute overall accuracy
    true_labels = psd_mat.LABEL.Pk(LabelIdx);
    predictions = Gk;
    overall_accuracy = mean(predictions == true_labels) * 100;
    
    % Unique class labels
    classes = unique(true_labels);
    class_accuracies = zeros(length(classes), 1); % Initialize class-wise accuracies
    for i = 1:length(classes)
        class_accuracies(i) = mean(Gk(true_labels == classes(i)) == classes(i)) * 100;
    end

    % Bar plot for accuracies
    figure('Visible', 'off');
    bar_classes = ["Overall", "771 - Both feet", "773 - Both hands"];
    bar_accuracies = [overall_accuracy; class_accuracies(1) ; class_accuracies(2)];
    bar(1:length(bar_accuracies), bar_accuracies);
    set(gca, ...
        'XTick', 1:length(bar_classes), ...
        'XTickLabel', bar_classes, ...
        'Title', text('String', 'Single sample accuracy on trainset'), ...
        'YLabel', text('String', 'Accuracy [%]'), ...
        'YLim', [0, 100], ...
        'YGrid', 'on');
    % Save the plot as an image
    image_filename = char(strcat(dirpath_out, 'singlesampleaccuracy.', filename, '.png'));
    saveas(gcf, image_filename);

    % Save the trained model as a .mat file
    model_filename = char(strcat(dirpath_out, 'model.', filename, '.mat'));
    save(model_filename, 'Model', 'FeaturesIdx' ,'Gk', 'pp');
    
    % Application of exponential smoothing to obtain trial based accuracy
    alpha = 0.97; % Integration parameter; tip: 0.96-0.98
    threshold.both_feet = 0.8; % Decision threshold for both feet
    threshold.both_hands = 0.2; % Decision threshold for both hands
    
    n_step = size(pp, 1); % Corresponds to the number of windows
    
    Tk_trials = psd_mat.LABEL.Tk(psd_mat.LABEL.Tk ~= 0);
    n_trials = size(unique(Tk_trials), 1);
    decisions = zeros(n_trials, 1); % Decisions vector
    
    D = 0.5; % Initial value for D(t)
    trial_id = 0; % Trial number from 1
    i = 1; % Variable used to sync the CFbK vector indices values with the indices of the pp vector

    decision_taken = false; % Flag to know if a decision has already been made for the current trial
    % Store trial start, trial end, window in which the decision is taken
    trial_info.start = zeros(n_trials,1); 
    trial_info.end = zeros(n_trials,1);
    trial_info.decision_window = zeros(n_trials,1);
    true_trials_labels = zeros(n_trials,1);

    for t = 1 : n_step
        % Reset D(t) at trial start
        if psd_mat.LABEL.CFbK(i) == 0

            if trial_id > 0
                trial_info.end(trial_id) = t-1; % Saves the index of the ending window of the trial
            end

            decision_taken = false; % Reset the flag for keeping track if a decision for the current trial has already been made

            % Advance in the ContFeed label vector until a value different from 0 is found(a cont feed period has started)
            while psd_mat.LABEL.CFbK(i) == 0 
                i = i + 1;
                if psd_mat.LABEL.Ck(i) ~= 0 % Retrieve true label for the current trial
                    true_trials_labels(trial_id+1) = psd_mat.LABEL.Ck(i); % it's trial_id+1 but it actually refers to the current trial
                end
            end
            
            D = 0.5;
            trial_id = trial_id + 1;
            trial_info.start(trial_id) = t; % Saves the index of the starting window of the trial
        end
    
        % Exponential smoothing
        D = alpha * D + (1 - alpha) * pp(t, 1);
        
        % Make a decision if threshold reached
        if (D > threshold.both_feet & ~decision_taken)
            decisions(trial_id) = 771; % Both feet decision
            trial_info.decision_window(trial_id) = t; % Saves the index of the windows where the decision is made
            decision_taken = true;
        elseif (D < threshold.both_hands & ~decision_taken)
            decisions(trial_id) = 773; % Both hands decision
            trial_info.decision_window(trial_id) = t; % Saves the index of the windows where the decision is made
            decision_taken = true;
        end
        i = i + 1;
    end
    
    trial_info.end(n_trials) = n_step;

    % Compute class accuracies for trial based accuracy
    overall_trial_accuracy = mean(decisions == true_trials_labels) * 100;
    both_feet_class_trial_accuracy = mean(decisions(true_trials_labels == 771) == 771) * 100;
    both_hands_class_trial_accuracy = mean(decisions(true_trials_labels == 773) == 773) * 100;

    % Compute average time for taking a decision
    time_for_decision = zeros(n_trials,1);
    window_shift = 0.0625;
    
    for j = 1 : n_trials
        if trial_info.decision_window(j) == 0
            time_for_decision(j) = (trial_info.end(j) - trial_info.start(j)) * window_shift;
        else
            time_for_decision(j) = (trial_info.decision_window(j) - trial_info.start(j)) * window_shift;
        end
    end

    average_decision_time = num2str(mean(time_for_decision));

    plot_title = strcat('Trial accuracy on trainset, with average decision time:', {' '}, average_decision_time, ' s');

    % Bar plot for accuracies
    figure('Visible', 'off');
    bar_accuracies = [overall_trial_accuracy; both_feet_class_trial_accuracy; both_hands_class_trial_accuracy];
    bar(bar_accuracies);
    set(gca, ...
        'XTick', 1:length(bar_accuracies), ...
        'XTickLabel', ["Overall", "771 - Both feet", "773 - Both hands"], ... 
        'Title', text('String', plot_title), ...
        'YLabel', text('String', 'Accuracy [%]'), ...
        'YLim', [0, 100], ...
        'YGrid', 'on');

    % Save the accuracy plot
    image_filename = char(strcat(dirpath_out, 'trialaccuracy.', filename, '.png'));
    saveas(gcf, image_filename);
 end