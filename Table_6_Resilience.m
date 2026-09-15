% =========================================================================
% Parse EF_Instrument into a clean long-format table:
%   Authors | Instrument_Name | Instrument_Author | EF_Category
%
% This script assumes:
%   - The LAST top-level (...) group is always the EF category list,
%     semicolon-separated.
%   - Any remaining top-level (...) group before it is the citation.
%   - Anything left (including [ABBR]) is the instrument name.
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
% Build the long-format table
% -------------------------------------------------------------------------
rows_authors  = {};
rows_ef_orig  = {};   % EF_Evaluated (study-level, repeated per instrument row)
rows_instr    = {};
rows_instr_au = {};
rows_ef       = {};
rows_raw      = {};   % keep the raw entry too, for manual QC

for i = 1:height(T)
    val = strtrim(T.EF_Instrument{i});
    if isempty(val) || strcmpi(val, 'nan')
        continue
    end

    ef_original_val = strtrim(T.EF_Evaluated{i});
    if isempty(ef_original_val) || strcmpi(ef_original_val, 'nan')
        ef_original_val = '';
    end

    entries = split_top_level(val, ';');

    for k = 1:numel(entries)
        entry = strtrim(entries{k});
        if isempty(entry), continue; end

        [core, ef_list] = extract_last_paren(entry);
        [instr_name, instr_author] = extract_trailing_paren(core);

        if isempty(ef_list)
            % No EF category found for this instrument — flag for review
            rows_authors{end+1}  = T.Authors{i};        %#ok<AGROW>
            rows_ef_orig{end+1}  = ef_original_val;       %#ok<AGROW>
            rows_instr{end+1}    = instr_name;             %#ok<AGROW>
            rows_instr_au{end+1} = instr_author;            %#ok<AGROW>
            rows_ef{end+1}       = '[NO EF CATEGORY FOUND — REVIEW]'; %#ok<AGROW>
            rows_raw{end+1}      = entry;                   %#ok<AGROW>
        else
            for e = 1:numel(ef_list)
                rows_authors{end+1}  = T.Authors{i};       %#ok<AGROW>
                rows_ef_orig{end+1}  = ef_original_val;      %#ok<AGROW>
                rows_instr{end+1}    = instr_name;            %#ok<AGROW>
                rows_instr_au{end+1} = instr_author;           %#ok<AGROW>
                rows_ef{end+1}       = strtrim(ef_list{e});     %#ok<AGROW>
                rows_raw{end+1}      = entry;                    %#ok<AGROW>
            end
        end
    end
end

ResultTable = table(rows_authors(:), rows_ef_orig(:), rows_instr(:), rows_instr_au(:), rows_ef(:), rows_raw(:), ...
    'VariableNames', {'Study_Authors', 'EF_Original', 'Instrument_Name', 'Instrument_Author', 'EF_Category', 'Raw_Entry'});

% Restore [ABBR] -> (ABBR) in Instrument_Name for display purposes
% (brackets were only needed internally to protect the abbreviation from
% being mistaken for the citation/EF-list parentheses during parsing)
ResultTable.Instrument_Name = strrep(strrep(ResultTable.Instrument_Name, '[', '('), ']', ')');

% Add a column counting how many DISTINCT STUDIES (Study_Authors) used
% each exact Instrument_Name string — not how many rows it appears in.
% This avoids inflating the count when the same study maps one instrument
% to several EF categories (e.g. the BRIEF Screener, used by a single
% study across 4 EF categories, should show "1" here, not "4").
[unique_names, ~, name_idx] = unique(ResultTable.Instrument_Name);
n_studies_per_name = zeros(numel(unique_names), 1);
for u = 1:numel(unique_names)
    mask = strcmp(ResultTable.Instrument_Name, unique_names{u});
    n_studies_per_name(u) = numel(unique(ResultTable.Study_Authors(mask)));
end
ResultTable.Instrument_N_Occurrences = n_studies_per_name(name_idx);

disp(ResultTable)

% -------------------------------------------------------------------------
% Quick QC: entries that need manual review
% -------------------------------------------------------------------------
flagged = ResultTable(strcmp(ResultTable.EF_Category, '[NO EF CATEGORY FOUND — REVIEW]'), :);
if ~isempty(flagged)
    fprintf('\n=== %d entries with NO EF category found — review these ===\n', height(flagged));
    disp(flagged(:, {'Study_Authors','Instrument_Name','Raw_Entry'}))
end

% -------------------------------------------------------------------------
% Save only the sorted-by-EF_Category table
% -------------------------------------------------------------------------
ResultTable_by_EF = sortrows(ResultTable, 'EF_Category');
openvar('ResultTable_by_EF');

output_dir_parsed = '/Users/josefinamattoli/Library/CloudStorage/GoogleDrive-josefinamattoli@gmail.com/.shortcut-targets-by-id/1x8K59aCdWa9nTsSzm0qLX40R4OEzEE2o/Practica_Electiva_Entre_Mentes_Y_Metodos_Alumnos/Nuestro paper/Revision_2/Analisis_Revision_2/Tablas_Parsed_Data';

out_path_by_ef = fullfile(output_dir_parsed, 'EF_Instrument_parsed_by_EF.csv');
writetable(ResultTable_by_EF, out_path_by_ef);
fprintf('\nParsed table (sorted by EF_Category) saved to:\n  %s\n', out_path_by_ef);


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

function [core, ef_list] = extract_last_paren(entry)
% Find the LAST top-level (...) group in entry (balancing nested parens
% inside it), treat its content as the EF category list (split by ';'),
% and return the entry with that group removed as "core".
    entry = strtrim(entry);
    ef_list = {};
    core = entry;

    if isempty(entry) || entry(end) ~= ')'
        return   % doesn't end in a parenthesis -> no EF list present
    end

    % Walk backwards from the final ')' to find its matching '('
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

    content = entry(open_idx+1 : end-1);
    ef_list = strtrim(split_top_level(content, ';'));
    ef_list = ef_list(~cellfun(@isempty, ef_list));

    core = strtrim(entry(1:open_idx-1));
end

function [instr_name, instr_author] = extract_trailing_paren(core)
% If core ends in a top-level (...) group, treat it as the citation
% (Instrument_Author); everything before it (including [ABBR]) is the
% Instrument_Name. If no trailing paren remains, Instrument_Author is empty.
    core = strtrim(core);
    instr_author = '';
    instr_name = core;

    if isempty(core) || core(end) ~= ')'
        return
    end

    depth = 0;
    open_idx = -1;
    for idx = numel(core):-1:1
        if core(idx) == ')'
            depth = depth + 1;
        elseif core(idx) == '('
            depth = depth - 1;
            if depth == 0
                open_idx = idx;
                break
            end
        end
    end

    if open_idx == -1
        return
    end

    instr_author = strtrim(core(open_idx+1:end-1));
    instr_name   = strtrim(core(1:open_idx-1));
end
