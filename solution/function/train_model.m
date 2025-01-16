%% Function to train the model for the given MAT file
function train_model(dirpath_in, filename, fileext, dirpath_out, dirpath_res)
    % INFO: dirpath_in: 'solution/psd/micontinuous/<subject>/', 'solution/psd/micontinuous/population/'
    % INFO: filename: '<filename_without_ext>'
    % INFO: fileext: '.mat'
    % INFO: dirpath_out: 'solution/model/micontinuous/<subject>/', 'solution/model/micontinuous/population/'
    
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
    FeaturesIdx = sub2ind([n_frequencies, n_channels], selected_features(:, 1), selected_features(:, 2)); % Linear indices for the 3D matrix
    
    % Use fitcdiscr() to train a model only with the data
    psd_mat.PSD_feature = reshape(psd_mat.PSD, n_windows, n_features); % [windows x features]
    LabelIdx = psd_mat.LABEL.CFbK == 781 & psd_mat.LABEL.Mk == 0; % Offline data during continuous feedback
    
    % Train model
    Model = fitcdiscr(psd_mat.PSD_feature(LabelIdx, FeaturesIdx), psd_mat.LABEL.Pk(LabelIdx), 'DiscrimType','quadratic');
    
    % Use predict() to evaluate the model with offline data (i.e., training accuracy)
    [Gk, pp] = predict(Model, psd_mat.PSD_feature(LabelIdx, FeaturesIdx));
    
    % The accuracy must be computed for both classes together (i.e., overall accuracy) and for each class separately. Accuracies must be reported as bar plots
    true_labels = psd_mat.LABEL.Pk(LabelIdx); % Ground truth labels
    predictions = Gk;
    
    % Compute overall accuracy
    overall_accuracy = mean(predictions == true_labels) * 100;
    
    classes = unique(true_labels); % Unique class labels
    class_accuracies = arrayfun(@(c) mean(Gk(true_labels == c) == c) * 100, classes); % Class-wise accuracy

    % Bar plot for accuracies
    figure('Visible', 'off');
    bar_classes = ["Overall", "771 - Both feet", "773 - Both hands"];
    bar_accuracies = [overall_accuracy; class_accuracies(1) ; class_accuracies(2)];
    bar(1:length(bar_accuracies), bar_accuracies);
    set(gca, ...
        'XTick', 1:length(bar_classes), ... % Labels
        'XTickLabel', bar_classes, ...
        'XTickLabelRotation', 45, ... 
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
 end