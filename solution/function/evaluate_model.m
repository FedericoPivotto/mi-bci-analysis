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
    bar_classes = ["Overall", "771 - Both feet", "773 - Both hands"];
    bar_accuracies = [overall_accuracy; class_accuracies(1); class_accuracies(2)];
    bar(bar_classes, bar_accuracies);
    set(gca, ...
        'Title', text('String', 'Single sample accuracy on testset'), ...
        'YLabel', text('String', 'Accuracy [%]'), ...
        'YLim', [0, 100], ...
        'YGrid', 'on');

    % Save the accuracy plot
    image_filename = char(strcat(dirpath_out, 'trialbasedaccuracy.', filename, '.png'));
    saveas(gcf, image_filename);
end
