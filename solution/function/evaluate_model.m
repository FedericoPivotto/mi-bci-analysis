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
    model_data = load(path_model);
    model = model_data.Model; % Trained model
    features_idx = model_data.FeaturesIdx; % Selected feature indices

    % Build the full path to the input MAT file
    mat_filepath = fullfile(dirpath_in, [filename, fileext]);
    if ~isfile(mat_filepath)
        error('MAT file not found: %s', mat_filepath);
    end

    % Load the MAT file containing the PSD data
    psd_data = load(mat_filepath);

    % Pre-process the PSD data
    n_windows = size(psd_data.PSD, 1); 
    n_frequencies = size(psd_data.PSD, 2); 
    n_channels = size(psd_data.PSD, 3); 
    n_features = n_frequencies * n_channels; 

    % Reshape PSD data into a feature vector
    psd_features = reshape(psd_data.PSD, n_windows, n_features);

    % Filter the data for relevant windows (TYP = 771 and TYP = 781)
    label_idx = psd_data.LABEL.CFbK == 781 & psd_data.LABEL.Mk == 1;

    % Predict labels using the trained model
    [Gk, pp] = predict(model, psd_features(label_idx, features_idx));

    % Compute evaluation metrics
    true_labels = psd_data.LABEL.Pk(label_idx); % Ground truth labels
    overall_accuracy = mean(Gk == true_labels) * 100; % Overall accuracy

    % Compute accuracy for each class
    classes = unique(true_labels); % Unique class labels
    class_accuracies = zeros(length(classes), 1); % Initialize class-wise accuracies
    for i = 1:length(classes)
        class_accuracies(i) = mean(Gk(true_labels == classes(i)) == classes(i)) * 100;
    end

    % Visualize the results
    figure;
    bar_classes = ["Overall", arrayfun(@(x) sprintf('Class %d', x), classes, 'UniformOutput', false)];
    bar_accuracies = [overall_accuracy; class_accuracies];
    bar(categorical(bar_classes), bar_accuracies);
    title('Accuracy Evaluation');
    ylabel('Accuracy [%]');
    ylim([0, 100]);
    grid on;

    % Save the accuracy plot
    output_dir = fullfile(dirpath_out, 'accuracy_plots');
    if ~isfolder(output_dir)
        mkdir(output_dir);
    end
    saveas(gcf, fullfile(output_dir, [filename, '_accuracy_plot.png']));

    % Save the metrics to a log file
    metrics_filepath = fullfile(output_dir, [filename, '_metrics.txt']);
    fid = fopen(metrics_filepath, 'w');
    fprintf(fid, 'Overall Accuracy: %.2f%%\n', overall_accuracy);
    for i = 1:length(classes)
        fprintf(fid, 'Accuracy for Class %d: %.2f%%\n', classes(i), class_accuracies(i));
    end
    fclose(fid);
end
