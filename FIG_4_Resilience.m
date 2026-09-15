% =========================================================================
% Figure 4.Versión2 Assessment of Adverse Childhood Experiences (ACEs).
%   4A: Horizontal bar chart — ACE types by framework category
%   4B: Heatmap — N of ACE categories vs. N of instruments per article
%       (cross-tabulation, replaces the previous separate C/D bar charts)
%
% Input:  CSV file with extracted data
% Output: Figure saved as .png and .fig in the same folder as the CSV
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% 1. File paths
% -------------------------------------------------------------------------
csv_path = 'Insert_Your_Data_File_Path_Here.csv';

output_name = 'Figure4_Versión2_ACEs_Assessment';

output_dir = fileparts(csv_path);
out_png    = fullfile(output_dir, [output_name '.png']);
out_fig    = fullfile(output_dir, [output_name '.fig']);

% -------------------------------------------------------------------------
% 2. Load data
% -------------------------------------------------------------------------
opts                   = detectImportOptions(csv_path, 'Delimiter', ',');
opts.VariableNamesLine = 1;
opts.DataLines         = [2 Inf];
opts                   = setvartype(opts, 'char');
T                      = readtable(csv_path, opts);

% -------------------------------------------------------------------------
% 3. Parse variables
% -------------------------------------------------------------------------

% -- Types_ACEs: pool all categories + count per article --
types_raw = T.Types_ACEs;
all_types       = {};
n_types_per_art = zeros(height(T), 1);
for i = 1:height(T)
    val = strtrim(types_raw{i});
    if isempty(val) || strcmpi(val, 'nan')
        n_types_per_art(i) = 0;
        continue
    end
    % Split on ';' OR ',' — one row in the source CSV uses a comma instead
    % of a semicolon as the category separator (typo); this field never
    % contains commas as part of a category name, so it's safe to treat
    % both as delimiters here.
    parts = reshape(strtrim(regexp(val, '[;,]', 'split')), 1, []);
    parts = parts(~cellfun(@isempty, parts));   % drop empty pieces from double delimiters
    all_types = [all_types, parts]; %#ok<AGROW>
    n_types_per_art(i) = numel(parts);
end

% -- Specific_ACEs_Instruments: pool all instruments + count per article --
instr_raw = T.Specific_ACEs_Instruments;
all_instruments   = {};
n_instr_per_art   = zeros(height(T), 1);
for i = 1:height(T)
    val = strtrim(instr_raw{i});
    if isempty(val) || strcmpi(val, 'nan')
        n_instr_per_art(i) = 0;
        continue
    end
    parts = reshape(strtrim(strsplit(val, ';')), 1, []);
    all_instruments = [all_instruments, parts]; %#ok<AGROW>
    n_instr_per_art(i) = numel(parts);
end

% -------------------------------------------------------------------------
% 4. Aggregate counts
% -------------------------------------------------------------------------

% 4A — frequency of each ACE category across articles
[unique_types, ~, idx_t] = unique(strtrim(all_types));
type_counts = accumarray(idx_t, 1);

% Fixed display order instead of sorting by count. barh plots index 1 at
% the bottom and the last index at the top, so listing the categories
% bottom-to-top here makes the figure read, top to bottom:
% Abuse, Neglect, Household dysfunction, Community-Level ACEs.
desired_order = {'Community-Level ACEs', 'Household dysfunction', 'Neglect', 'Abuse'};
[tf, loc] = ismember(lower(desired_order), lower(unique_types));
if ~all(tf)
    error('Panel 4A: could not match these categories to Types_ACEs values: %s', ...
          strjoin(desired_order(~tf), ', '));
end
type_labels_sorted = unique_types(loc);
type_counts_sorted = type_counts(loc);

% 4B — cross-tabulation: N ACE categories x N instruments per article
max_types  = max(n_types_per_art);
max_instr  = max(n_instr_per_art);
type_n_vals  = 1:max_types;
instr_n_vals = 1:max_instr;

cross_matrix = zeros(numel(type_n_vals), numel(instr_n_vals));
for i = 1:height(T)
    r = n_types_per_art(i);
    c = n_instr_per_art(i);
    if r >= 1 && c >= 1
        cross_matrix(r, c) = cross_matrix(r, c) + 1;
    end
end

% Drop rows/columns that are entirely zero, so the heatmap only shows
% combinations that actually occur in the data
keep_rows_cm = any(cross_matrix, 2);
keep_cols_cm = any(cross_matrix, 1);
cross_matrix = cross_matrix(keep_rows_cm, keep_cols_cm);
type_n_vals  = type_n_vals(keep_rows_cm);
instr_n_vals = instr_n_vals(keep_cols_cm);

% Spearman correlation between the two counts (reported as an inset)
rho = corr(n_types_per_art, n_instr_per_art, 'Type', 'Spearman');

% -------------------------------------------------------------------------
% 5. Style settings
% -------------------------------------------------------------------------
clr_bar  = [0.45 0.45 0.45];

fs_tick  = 13;
fs_label = 14;
fs_title = 16;

% -------------------------------------------------------------------------
% 6. Build figure (A centered on top, heatmap below)
% -------------------------------------------------------------------------
fig = figure('Units', 'centimeters', 'Position', [2 2 36 22], ...
             'Color', 'w');

% ---- 4A: ACE types (top, centered) ----------------------------------------
n_types = numel(type_labels_sorted);
ax_a = axes('Position', [0.31  0.55  0.38  0.38]);   % centered: (1 - 0.38) / 2 = 0.31
barh(1:n_types, type_counts_sorted, 0.6, ...
     'FaceColor', clr_bar, 'EdgeColor', 'none');
yticks(1:n_types);
yticklabels(type_labels_sorted);
xlabel('Number of articles', 'FontSize', fs_label);
title('A', 'FontWeight', 'bold', 'FontSize', fs_title, ...
      'Units', 'normalized', 'Position', [0 1 0], ...
      'HorizontalAlignment', 'left');
ax_a.XAxis.TickValues = 0:1:max(type_counts_sorted)+1;
ax_a.Box       = 'off';
ax_a.FontSize  = fs_tick;
ax_a.XGrid     = 'on';
ax_a.GridAlpha = 0.3;
xlim([0, max(type_counts_sorted) + 1]);

% ---- 4B: N ACE categories x N instruments (heatmap, bottom, full width) ---
ax_c = axes('Position', [0.14  0.08  0.72  0.38]);
imagesc(ax_c, cross_matrix);
axis(ax_c, 'xy');   % keep row 1 (fewest categories) at the bottom
colormap(ax_c, [linspace(1, 0.20, 256)', linspace(1, 0.20, 256)', linspace(1, 0.20, 256)']);
cb = colorbar(ax_c);
cb.Label.String = 'Number of articles';
cb.Label.FontSize = fs_label;
cb.Ticks = 0:max(cross_matrix(:));   % integer-only ticks (removes 0.5/1.5/2.5)

xticks(1:numel(instr_n_vals));
xticklabels(arrayfun(@num2str, instr_n_vals, 'UniformOutput', false));
yticks(1:numel(type_n_vals));
yticklabels(arrayfun(@num2str, type_n_vals, 'UniformOutput', false));
xlabel('Number of instruments',    'FontSize', fs_label);
ylabel('Number of ACE categories', 'FontSize', fs_label);
title(sprintf('B', rho), ...
      'FontWeight', 'bold', 'FontSize', fs_title, ...
      'Units', 'normalized', 'Position', [0 1 0], ...
      'HorizontalAlignment', 'left');
ax_c.FontSize = fs_tick;
ax_c.Box      = 'on';

% Print the article count inside each non-empty cell, in a contrasting color
for r = 1:size(cross_matrix, 1)
    for c = 1:size(cross_matrix, 2)
        if cross_matrix(r, c) > 0
            if cross_matrix(r, c) / max(cross_matrix(:)) > 0.5
                txt_color = 'w';
            else
                txt_color = 'k';
            end
            text(ax_c, c, r, num2str(cross_matrix(r, c)), ...
                 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                 'FontSize', fs_tick, 'Color', txt_color);
        end
    end
end
% Note: cells with 0 articles are left blank (background color) rather than
% printed as "0", to keep the heatmap readable.

% -------------------------------------------------------------------------
% 7. Export
% -------------------------------------------------------------------------
exportgraphics(fig, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
savefig(fig, out_fig);

fprintf('\nFigure saved:\n  %s\n  %s\n', out_png, out_fig);
