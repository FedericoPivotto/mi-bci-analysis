%% Function to compute label vectors given a PSD and the corresponding EVENT
function [Tk, Ck, CFbK, Pk, Mk] = get_label_vectors(PSD, EVENT, data_type, classes)
    if nargin < 4,  classes = [771 773];    end

    n_windows = size(PSD, 1);
    n_events = size(EVENT.TYP, 1);
    
    Tk = zeros(n_windows, 1); % Trial label vector
    Ck = zeros(n_windows, 1); % Cue label vector
    CFbK = zeros(n_windows, 1); % Continuous feedback label vector
    Pk = zeros(n_windows, 1); % Cue+feedback label vector
    
    trial_id = 1;

    for i = 1 : n_events
        current.TYP = EVENT.TYP(i);
        current.POS = EVENT.POS(i);
        current.END = current.POS + floor(EVENT.DUR(i)) - 1;

        Tk(current.POS:current.END) = trial_id; % Trial index
        if strcmp(data_type, 'online') && ismember(current.TYP, [897, 898])
            trial_id = trial_id + 1;
        elseif strcmp(data_type, 'offline') && ismember(current.TYP, [781])
            trial_id = trial_id + 1;
        end

        if ismember(current.TYP, classes)
            Ck(current.POS:current.END) = current.TYP; % TYP if TYP is 771 or 773, 0 otherwise

            Pk(current.POS:current.END) = current.TYP;
            if i < n_events
                next.POS = EVENT.POS(i + 1);
                next.END = next.POS + floor(EVENT.DUR(i + 1)) - 1;    
                
                Pk(next.POS:next.END) = current.TYP;
                CFbK(next.POS:next.END) = 781;
            end

            
        end
    end
    
    if data_type == "online"
        Mk = ones(n_windows, 1); % Online data label vector
    elseif data_type == "offline"
        Mk = zeros(n_windows, 1); % Offline data label vector
    end
end