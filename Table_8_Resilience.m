% =========================================================================
% Table 8. Resilience instruments used across included studies.
%   Resilience_Conceptualization | N_Studies | Construct_Measured |
%   Instrument | Instrument_Author | N_Studies_per_Instrument
%
% Format assumed per entry in Resilience_Instrument: Name [ABBR] (Authors)
%   - [ABBR] is optional
%   - (Authors) is optional
%   - Entries within a cell are separated by ';' at the top level (i.e.
%     outside any parentheses/brackets).
% =========================================================================

clear; clc;

csv_path = 'Insert_Your_Data_File_Path_Here.csv';

opts                   = detectImportOptions(csv_path, 'Delimiter', ',');
opts.VariableNamesLine = 1;
opts.DataLines         = [2 Inf];
opts                   = setvartype(opts, 'char');
T                      = readtable(csv_path, opts);

% -------------------------------------------------------------------------
% Build the long-format table (one row per instrument; studies with no
% reported instrument still get one row, with Instrument left blank)
% -------------------------------------------------------------------------
rows_authors  = {};
rows_concept  = {};
rows_measure  = {};
rows_instr    = {};
rows_instr_au = {};

for i = 1:height(T)
    concept_val = strtrim(T.Resilience_conceptualization{i});
    measure_val = strtrim(T.Resilience_Measure{i});
    if isempty(measure_val) || strcmpi(measure_val, 'nan')
        measure_val = '';
    else
        % Relabel "Resilience scale" -> "Resilience" (case-insensitive)
        measure_val = regexprep(measure_val, 'Resilience scale', 'Resilience', 'ignorecase');
    end

    instr_val = strtrim(T.Resilience_Instrument{i});

    if isempty(instr_val) || strcmpi(instr_val, 'nan')
        % No instrument reported for this study — still keep one row so
        % the study is not silently dropped from the N_Studies count
        rows_authors{end+1}  = T.Authors{i};   %#ok<AGROW>
        rows_concept{end+1}  = concept_val;     %#ok<AGROW>
        rows_measure{end+1}  = measure_val;      %#ok<AGROW>
        rows_instr{end+1}    = '';                %#ok<AGROW>
        rows_instr_au{end+1} = '';                 %#ok<AGROW>
        continue
    end

    entries = split_top_level(instr_val, ';');

    for k = 1:numel(entries)
        entry = strtrim(entries{k});
        if isempty(entry), continue; end

        [instr_name, instr_author] = extract_trailing_paren(entry);

        rows_authors{end+1}  = T.Authors{i};   %#ok<AGROW>
        rows_concept{end+1}  = concept_val;     %#ok<AGROW>
        rows_measure{end+1}  = measure_val;      %#ok<AGROW>
        rows_instr{end+1}    = instr_name;        %#ok<AGROW>
        rows_instr_au{end+1} = instr_author;       %#ok<AGROW>
    end
end

ResultTable = table(rows_authors(:), rows_concept(:), rows_measure(:), rows_instr(:), rows_instr_au(:), ...
    'VariableNames', {'Study_Authors', 'Resilience_Conceptualization', 'Construct_Measured', ...
                       'Instrument', 'Instrument_Author'});

% Restore [ABBR] -> (ABBR) in Instrument for display purposes
ResultTable.Instrument = strrep(strrep(ResultTable.Instrument, '[', '('), ']', ')');

% -------------------------------------------------------------------------
% N_Studies: distinct studies per Resilience_Conceptualization
% -------------------------------------------------------------------------
[unique_concepts, ~, concept_idx] = unique(ResultTable.Resilience_Conceptualization);
n_studies_per_concept = zeros(numel(unique_concepts), 1);
for u = 1:numel(unique_concepts)
    mask = strcmp(ResultTable.Resilience_Conceptualization, unique_concepts{u});
    n_studies_per_concept(u) = numel(unique(ResultTable.Study_Authors(mask)));
end
ResultTable.N_Studies = n_studies_per_concept(concept_idx);

% -------------------------------------------------------------------------
% N_Studies_per_Instrument: distinct studies per exact Instrument string
% (blank Instrument, i.e. studies with no reported instrument, excluded
% from this count)
% -------------------------------------------------------------------------
ResultTable.N_Studies_per_Instrument = nan(height(ResultTable), 1);
has_instr = ~strcmp(ResultTable.Instrument, '');
[unique_instr, ~, instr_idx] = unique(ResultTable.Instrument(has_instr));
n_studies_per_instr = zeros(numel(unique_instr), 1);
for u = 1:numel(unique_instr)
    mask = strcmp(ResultTable.Instrument, unique_instr{u});
    n_studies_per_instr(u) = numel(unique(ResultTable.Study_Authors(mask)));
end
ResultTable.N_Studies_per_Instrument(has_instr) = n_studies_per_instr(instr_idx);

% -------------------------------------------------------------------------
% Reorder columns as requested
% -------------------------------------------------------------------------
ResultTable = ResultTable(:, {'Resilience_Conceptualization', 'N_Studies', ...
    'Construct_Measured', 'Instrument', 'Instrument_Author', 'N_Studies_per_Instrument'});

disp(ResultTable)
openvar('ResultTable');

% -------------------------------------------------------------------------
% Save to CSV
% -------------------------------------------------------------------------
out_path = fullfile(fileparts(csv_path), 'Resilience_Instrument_parsed.csv');
writetable(ResultTable, out_path);
fprintf('\nParsed table saved to:\n  %s\n', out_path);


% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function entries = split_top_level(str, delim)
% Split str on delim, but only where depth of '(' and '[' is zero.
    entries = {};
    depth = 0;
    buf = '';
    for c = str
        if c == '(' || c == '['
            depth = depth + 1;
        elseif c == ')' || c == ']'
            depth = max(depth - 1, 0);
        end
        if c == delim && depth == 0
            entries{end+1} = buf; %#ok<AGROW>
            buf = '';
        else
            buf = [buf, c]; %#ok<AGROW>
        end
    end
    if ~isempty(strtrim(buf))
        entries{end+1} = buf;
    end
end

function [instr_name, instr_author] = extract_trailing_paren(entry)
% If entry ends in a top-level (...) group, treat it as the citation
% (Instrument_Author); everything before it (including [ABBR]) is the
% Instrument name. If no trailing paren, Instrument_Author is empty.
    entry = strtrim(entry);
    instr_author = '';
    instr_name = entry;

    if isempty(entry) || entry(end) ~= ')'
        return
    end

    depth = 0;
    open_idx = -1;
    for idx = numel(entry):-1:1
        if entry(idx) == ')'
            depth = depth + 1;
        elseif entry(idx) == '('
            depth = depth - 1;
            if depth == 0
                open_idx = idx;
                break
            end
        end
    end

    if open_idx == -1
        return   % unbalanced parens -> leave as-is for manual review
    end

    instr_author = strtrim(entry(open_idx+1:end-1));
    instr_name   = strtrim(entry(1:open_idx-1));
end
