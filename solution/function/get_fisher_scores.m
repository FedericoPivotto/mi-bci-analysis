%% Function to compute Fisher score matrix of a given PSD
function [fisher_scores_matrix] = get_fisher_scores(PSD, Pk)
    PSD = PSD(logical(Pk), :, :);
    Pk = Pk(Pk ~= 0);

    n_windows = size(PSD, 1);
    n_frequencies = size(PSD, 2);
    n_channels = size(PSD, 3);
    n_features = n_frequencies * n_channels;

    PSD_feature = reshape(PSD, n_windows, n_features);
    
    for i = 1:n_features
        feature = PSD_feature(:, i);

        numerator = abs(mean(feature(Pk == 771)) - mean(feature(Pk == 773)));
        denominator = sqrt(var(feature(Pk == 771)) + var(feature(Pk == 773)));
        fisher_scores(i) = numerator / denominator;
    end
    
    % Fisher scores matrix [frequencies x channels]
    fisher_scores_matrix = reshape(fisher_scores, n_frequencies, n_channels);
end