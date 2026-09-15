% =========================================================================
% Figure 3. Research methods used.
%   3A: Pie chart — general methods (quantitative / qualitative / mixed)
%   3B: Pie chart — study design (cross-sectional / longitudinal / intervention)
%   3C: Horizontal bar chart — brain measures (no / EEG / fMRI / etc.)
%
% Input:  CSV file with extracted data
% Output: Figure saved as .png and .fig in the same folder as the CSV
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% 1. File paths
% -------------------------------------------------------------------------
csv_path = 'Insert_Your_Data_File_Path_Here.csv;

output_name = 'Figure3_Research_Methods';

output_dir = fileparts(csv_path);
out_png    = fullfile(output_dir, [output_name '.png']);
out_fig    = fullfile(output_dir, [output_name '.fig']);

% -------------------------------------------------------------------------
% 2. Load data
% -------------------------------------------------------------------------
opts                   = detectImportOptions(csv_path, 'Delimiter', ',');
opts.VariableNamesLine = 1;
opts.DataLines         = [3 Inf];
opts                   = setvartype(opts, 'char');
T                      = readtable(csv_path, opts);

% -------------------------------------------------------------------------
% 3. Parse variables
% -------------------------------------------------------------------------

% -- Used_Methods --
methods_raw = T.Used_Methods;
methods = {};
for i = 1:height(T)
    val = strtrim(methods_raw{i});
    if isempty(val) || strcmpi(val, 'nan'); continue; end
    parts = reshape(strtrim(strsplit(val, ';')), 1, []);
    methods = [methods, parts]; %#ok<AGROW>
end
methods = lower(methods);

% -- Study_Type --
design_raw = T.Study_Type;
designs = {};
for i = 1:height(T)
    val = strtrim(design_raw{i});
    if isempty(val) || strcmpi(val, 'nan'); continue; end
    parts = reshape(strtrim(strsplit(val, ';')), 1, []);
    designs = [designs, parts]; %#ok<AGROW>
end
designs = lower(designs);

% -- Brain_Evaluation_YesNo and Brain_Method --
brain_yn_raw     = T.Brain_Evaluation_YesNo;
brain_method_raw = T.Brain_Method;

brain_labels = {};   % one entry per article
for i = 1:height(T)
    yn  = strtrim(brain_yn_raw{i});
    mth = strtrim(brain_method_raw{i});
    if strcmpi(yn, 'No') || isempty(yn) || strcmpi(yn, 'nan')
        brain_labels{end+1} = 'No brain measure'; %#ok<AGROW>
    else
        if isempty(mth) || strcmpi(mth, 'nan')
            brain_labels{end+1} = 'Unspecified'; %#ok<AGROW>
        else
            brain_labels{end+1} = mth; %#ok<AGROW>
        end
    end
end

% -------------------------------------------------------------------------
% 4. Aggregate counts
% -------------------------------------------------------------------------

% -- Merge "fMRI" and "fMRI; MRI" into a single "fMRI" category (panel C) --
brain_labels = strrep(brain_labels, 'fMRI; MRI', 'fMRI');

% 3A — general methods
method_cats   = {'quantitative', 'qualitative', 'mixed'};
method_labels = {'Quantitative', 'Qualitative', 'Mixed'};
method_counts = cellfun(@(c) sum(strcmp(methods, c)), method_cats);
keep_m = method_counts > 0;
method_labels = method_labels(keep_m);
method_counts = method_counts(keep_m);

% 3B — study design
design_cats   = {'cross sectional', 'longitudinal', 'intervention'};
design_labels = {'Cross-sectional', 'Longitudinal', 'Intervention'};
design_counts = cellfun(@(c) sum(strcmp(designs, c)), design_cats);
keep_d = design_counts > 0;
design_labels = design_labels(keep_d);
design_counts = design_counts(keep_d);

% 3C — brain measures
[unique_brain, ~, idx_br] = unique(brain_labels);
brain_counts = accumarray(idx_br, 1);
% Sort by count, ascending (shortest bar first)
[brain_counts_sorted, sort_idx] = sort(brain_counts, 'descend');
brain_display_names  = reshape(unique_brain(sort_idx), 1, []);
brain_display_counts = reshape(brain_counts_sorted, 1, []);

% -------------------------------------------------------------------------
% 4b. Diagnostic: show which CSV rows fall into each Brain_Method category
%     (Brain_Method is used verbatim, with no lower()/strsplit() cleanup —
%     unlike Used_Methods and Study_Type — so any inconsistent text in that
%     column becomes its own category in panel C. Use this to check for
%     unexpected categories.)
% -------------------------------------------------------------------------
fprintf('\n--- Brain_Method categories found (panel C) ---\n');
for k = 1:numel(unique_brain)
    rows = find(idx_br == k);
    fprintf('  "%s"  (n=%d)  -> CSV row(s): %s\n', ...
            unique_brain{k}, numel(rows), mat2str(rows(:)'));
end
fprintf('-------------------------------------------------\n');


% -------------------------------------------------------------------------
% 5. Style settings
% -------------------------------------------------------------------------
clr_pie = [0.25 0.25 0.25;
           0.60 0.60 0.60;
           0.65 0.65 0.65;
           0.80 0.80 0.80;
           0.92 0.92 0.92];
clr_bar  = [0.45 0.45 0.45];

fs_tick  = 13;
fs_label = 14;
fs_title = 16;

% -------------------------------------------------------------------------
% 6. Build figure
% -------------------------------------------------------------------------
fig = figure('Units', 'centimeters', 'Position', [2 2 28 22], ...
             'Color', 'w');

% ---- 3A: Pie — general methods ------------------------------------------
ax_a = axes('Position', [0.05  0.55  0.35  0.38]);
p_a = pie(ax_a, method_counts);
colormap(ax_a, clr_pie(1:numel(method_counts), :));
txt_idx = 2:2:numel(p_a);
for k = 1:numel(txt_idx)
    p_a(txt_idx(k)).FontSize = fs_tick;
    pct = round(100 * method_counts(k) / sum(method_counts));
    p_a(txt_idx(k)).String = sprintf('%s\n%d (%d%%)', method_labels{k}, method_counts(k), pct);
end
title('A', 'FontWeight', 'bold', 'FontSize', fs_title, ...
      'HorizontalAlignment', 'left', 'Units', 'normalized', ...
      'Position', [0 1 0]);

% ---- 3B: Pie — study design ---------------------------------------------
ax_b = axes('Position', [0.55  0.55  0.35  0.38]);
p_b = pie(ax_b, design_counts);
colormap(ax_b, clr_pie(1:numel(design_counts), :));
txt_idx = 2:2:numel(p_b);
for k = 1:numel(txt_idx)
    p_b(txt_idx(k)).FontSize = fs_tick;
    pct = round(100 * design_counts(k) / sum(design_counts));
    p_b(txt_idx(k)).String = sprintf('%s\n%d (%d%%)', design_labels{k}, design_counts(k), pct);
end
title('B', 'FontWeight', 'bold', 'FontSize', fs_title, ...
      'HorizontalAlignment', 'left', 'Units', 'normalized', ...
      'Position', [0 1 0]);

% ---- 3C: Horizontal bar — brain measures --------------------------------
ax_c = axes('Position', [0.16  0.08  0.78  0.38]);
barh(1:numel(brain_display_names), brain_display_counts, 0.6, ...
     'FaceColor', clr_bar, 'EdgeColor', 'none');
yticks(1:numel(brain_display_names));
yticklabels(brain_display_names);
xlabel('Number of studies', 'FontSize', fs_label);
title('C', 'FontWeight', 'bold', 'FontSize', fs_title, ...
      'HorizontalAlignment', 'left', 'Units', 'normalized', ...
      'Position', [0 1 0]);
ax_c.XAxis.TickValues = 0:1:max(brain_display_counts)+1;
ax_c.Box       = 'off';
ax_c.FontSize  = fs_tick;
ax_c.XGrid     = 'on';
ax_c.GridAlpha = 0.3;
xlim([0, max(brain_display_counts) + 1]);

% -------------------------------------------------------------------------
% 7. Export
% -------------------------------------------------------------------------
exportgraphics(fig, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
savefig(fig, out_fig);

fprintf('\nFigure saved:\n  %s\n  %s\n', out_png, out_fig);
