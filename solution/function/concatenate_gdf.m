%% Function to concatenate and save the given GDF files
function concatenate_gdf(dirpath_in, filename, fileext, dirpath_out, filenames)
    % Pre-condition
    if size(filenames, 2) < 1
        return
    end

    % Scan each GDF file
    for i = 1:size(filenames, 2)
        % Load signal and header
        filepath = char(strcat(dirpath_in, char(filenames(i)), fileext));
        [file{i}.s, file{i}.h] = sload(filepath);
    end

    % Initialize resulting signal and header
    s = file{1}.s;
    h.TYPE = file{1}.h.TYPE;
    h.NS = file{1}.h.NS;
    h.SampleRate = file{1}.h.SampleRate;
    h.EVENT = file{1}.h.EVENT;
    h.Label = file{1}.h.Label;
    h.Transducer = file{1}.h.Transducer;
    h.InChanSelect = file{1}.h.InChanSelect;
    
    % Scan each signal from next
    for i = 2:size(filenames, 2)
        % TODO: Check header
        
        % Concatenate events
        h.EVENT.POS = [h.EVENT.POS; size(s, 1) + file{i}.h.EVENT.POS];
        h.EVENT.TYP = [h.EVENT.TYP; file{i}.h.EVENT.TYP];
        h.EVENT.DUR = [h.EVENT.DUR; file{i}.h.EVENT.DUR];
        h.EVENT.CHN = [h.EVENT.CHN; file{i}.h.EVENT.CHN];

        % Concatenate signal
        s = [s; file{i}.s];
    end
    
    % Save the resulting signal and header
    if ~exist(char(dirpath_out), 'dir')
       mkdir(char(dirpath_out));
    end
    save(char(strcat(dirpath_out, filename, '.mat')), 's', 'h');
end