%% Function to evaluate the model for the given MAT file
function evaluate_model(path_model, dirpath_in, filename, fileext, dirpath_out)
    % INFO: path_model: 'solution/model/micontinuous/<subject>/<filename_with_ext>', 'solution/model/micontinuous/population/<filename_with_ext>'
    % INFO: dirpath_in: 'solution/psd/micontinuous/<subject>/', 'solution/psd/micontinuous/population/'
    % INFO: filename: '<filename_without_ext>'
    % INFO: fileext: '.mat'
    % INFO: dirpath_out: 'solution/model/micontinuous/<subject>/', 'solution/model/micontinuous/population/'

    % NOTE: there is the need to use the MAT file in resource/ (think how to organize the MAT files with the most relevant features)
    % REMEMBER: compute required metrics
    % NOTE: obviously, the plots need to be saved

    % Load the trained model
    model_data = load(char(path_model));
    Model = model_data.Model; % Trained model
    FeaturesIdx = model_data.FeaturesIdx; % Selected feature indices

    % Load the MAT file containing the PSD data
    filepath = char(strcat(dirpath_in, filename, fileext));
    psd_data = load(filepath);

    % Extract label vectors using the EVENT field
    [psd_data.LABEL.Tk, psd_data.LABEL.Ck, psd_data.LABEL.CFbK, psd_data.LABEL.Pk, psd_data.LABEL.Mk] = get_label_vectors(psd_data.PSD, psd_data.EVENT, 'online');

    % Pre-process the PSD data
    n_windows = size(psd_data.PSD, 1); 
    n_frequencies = size(psd_data.PSD, 2); 
    n_channels = size(psd_data.PSD, 3); 
    n_features = n_frequencies * n_channels; 

    % Reshape PSD data into a feature vector
    psd_features = reshape(psd_data.PSD, n_windows, n_features);

    % Filter the data for relevant windows (TYP = 771 and TYP = 781)
    LabelIdx = psd_data.LABEL.CFbK == 781 & psd_data.LABEL.Mk == 1;

    % Predict labels using the trained model
    [Gk, pp] = predict(Model, psd_features(LabelIdx, FeaturesIdx));

    % Compute evaluation metrics
    true_labels = psd_data.LABEL.Pk(LabelIdx); % Ground truth labels
    overall_accuracy = mean(Gk == true_labels) * 100; % Overall accuracy

    % Compute accuracy for each class
    classes = unique(true_labels); % Unique class labels
    class_accuracies = zeros(length(classes), 1); % Initialize class-wise accuracies
    for i = 1:length(classes)
        class_accuracies(i) = mean(Gk(true_labels == classes(i)) == classes(i)) * 100;
    end
    
    % Check if dirpath_out exists, if not create it
    if ~exist(char(dirpath_out), 'dir')
       mkdir(char(dirpath_out));
    end

    % Bar plot for accuracies
    figure('Visible', 'off');
    bar_accuracies = [overall_accuracy; class_accuracies(1); class_accuracies(2)];
    bar(bar_accuracies);
    set(gca, ...
        'XTick', 1:length(bar_accuracies), ...
        'XTickLabel', ["Overall", "771 - Both feet", "773 - Both hands"], ... 
        'Title', text('String', 'Single sample accuracy on testset'), ...
        'YLabel', text('String', 'Accuracy [%]'), ...
        'YLim', [0, 100], ...
        'YGrid', 'on');

    % Save the accuracy plot
    image_filename = char(strcat(dirpath_out, 'singleSampleAccuracy.', filename, '.png'));
    saveas(gcf, image_filename);
% Application of exponential smoothing to obtain trial based accuracy
    alpha = 0.97; % Integration parameter: Tip: 0.96-0.98
    threshold.both_feet = 0.8; % Decision threshold for both feet
    threshold.both_hands = 0.2; % Decision threshold for both hands
    
    n_step = size(pp, 1); % corresponds to the number of windows
    
    Tk_trials = psd_data.LABEL.Tk(psd_data.LABEL.Tk ~= 0);
    n_trials = size(unique(Tk_trials), 1);
    decisions = zeros(n_trials, 1); % Decisions vector
    
    D = 0.5; % Initial value for D(t)
    trial_id = 0; % Trial number from 1
    i = 1; % variable used to sync the CFbK vector indices values with the indices of the pp vector

    decision_taken = false; % Flag to know if a decision has already been made for the current trial
    % contains trial start, trial end, window in which the decision is taken
    trial_info.start = zeros(n_trials,1); 
    trial_info.end = zeros(n_trials,1);
    trial_info.decision_window = zeros(n_trials,1);
    true_trials_labels = zeros(n_trials,1);
    
    for t = 1 : n_step
        % Reset D(t) at trial start
        if psd_data.LABEL.CFbK(i) == 0

            if trial_id > 0
                trial_info.end(trial_id) = t-1; % saves the index of the ending window of the trial
            end

            decision_taken = false; % reset the flag for keeping track if a decision for the current trial has already been made

            % Advance in the ContFeed label vector until a value different from 0 is found(a cont feed period has started)
            while psd_data.LABEL.CFbK(i) == 0 
                i = i + 1;
                if psd_data.LABEL.Ck(i) ~= 0 % Retrieve true label for the current trial
                    true_trials_labels(trial_id+1) = psd_data.LABEL.Ck(i); % it's trial_id+1 but it actually refers to the current trial
                end
            end
            
            D = 0.5;
            trial_id = trial_id + 1;
            trial_info.start(trial_id) = t; % saves the index of the starting window of the trial
        end
    
        % Exponential smoothing
        D = alpha * D + (1 - alpha) * pp(t, 1);
        
        % Make a decision if threshold reached
        if (D > threshold.both_feet & ~decision_taken)
            decisions(trial_id) = 771; % Both feet decision
            trial_info.decision_window(trial_id) = t; % saves the index of the windows where the decision is made
            decision_taken = true;
        elseif (D < threshold.both_hands & ~decision_taken)
            decisions(trial_id) = 773; % Both hands decision
            trial_info.decision_window(trial_id) = t; % saves the index of the windows where the decision is made
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

    plot_title = strcat('Trial accuracy on testset, with average decision time: ', average_decision_time);

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
    image_filename = char(strcat(dirpath_out, 'TrialAccuracy.', filename, '.png'));
    saveas(gcf, image_filename);

end