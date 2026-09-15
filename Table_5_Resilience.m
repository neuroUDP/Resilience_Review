clear; clc;

% =========================================================================
% Figure 5. Executive functions evaluated.
%   5A: Horizontal bar chart — Executive functions studied
%
% Built from Final_EF_Instrument_parsed_by_EF.csv (long-format table: one
% row per Study x Instrument x EF_Category), reading the EF category
% directly from the EF_Category column (already canonicalized upstream —
% no keyword/synonym mapping needed here).
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% 1. File paths
% -------------------------------------------------------------------------
parsed_csv_path = 'Insert_Your_Data_File_Path_Here.csv';

output_name = 'Figure5_ExecutiveFunctions';

output_dir = fileparts(parsed_csv_path);
out_png    = fullfile(output_dir, [output_name '.png']);
out_fig    = fullfile(output_dir, [output_name '.fig']);

% -------------------------------------------------------------------------
% 2. Load the parsed EF_Instrument table
% -------------------------------------------------------------------------
opts = detectImportOptions(parsed_csv_path, 'Delimiter', ',');
opts = setvartype(opts, 'char');
P    = readtable(parsed_csv_path, opts);

% Drop rows flagged during parsing as having no identifiable EF category
P = P(~strcmp(P.EF_Category, '[NO EF CATEGORY FOUND — REVIEW]'), :);

% -------------------------------------------------------------------------
% 3. Fixed display order (top to bottom)
% -------------------------------------------------------------------------
% "Others" is NOT a value that appears in EF_Category — it is a catch-all
% for every row whose EF_Category does not match one of the five named
% categories below (see Section 4).
%
% barh draws category 1 at the bottom of the axis, so the plotting order
% must be the reverse of the requested top-to-bottom display order.
named_categories = {'Working memory', 'Inhibitory control', ...
                     'Cognitive flexibility', 'Attention', ...
                     'Cognitive control'};
display_order_top_to_bottom = [named_categories, {'Others'}];
ef_labels_final = flip(display_order_top_to_bottom)';

% -------------------------------------------------------------------------
% 4. Count N STUDIES (not N rows/instruments) per EF category, so that a
%    study using two instruments for the same function is only counted
%    once. Rows that don't match any of the five named categories
%    (case-insensitive) are pooled into "Others".
% -------------------------------------------------------------------------
is_named = false(height(P), 1);
for c = 1:numel(named_categories)
    is_named = is_named | strcmpi(P.EF_Category, named_categories{c});
end

% --- DIAGNOSTIC (remove once "Others" is confirmed correct) ------------
% If unmatched_values comes back empty even though you expect ~14 studies
% in "Others", the unmatched rows are being dropped upstream — most likely
% by the Section 2 filter on '[NO EF CATEGORY FOUND — REVIEW]', before
% ever reaching this point. Check EF_Category for those rows in the raw
% CSV directly if so.
unmatched_values = unique(P.EF_Category(~is_named));
fprintf('\n[DIAGNOSTIC] Unmatched EF_Category values (-> "Others"):\n');
disp(unmatched_values);
fprintf('[DIAGNOSTIC] Rows unmatched: %d / %d\n', sum(~is_named), height(P));

ef_counts_final = zeros(numel(ef_labels_final), 1);
for c = 1:numel(ef_labels_final)
    if strcmp(ef_labels_final{c}, 'Others')
        mask = ~is_named;   % everything that didn't match a named category
    else
        mask = strcmpi(P.EF_Category, ef_labels_final{c});
    end
    ef_counts_final(c) = numel(unique(P.Study_Authors(mask)));
end

% A zero count for one of the five NAMED categories most likely means a
% spelling/casing mismatch against EF_Category — flag it. A zero count for
% "Others" is fine (it just means every row matched a named category).
zero_named_mask = ef_counts_final == 0 & ~strcmp(ef_labels_final, 'Others');
if any(zero_named_mask)
    warning('FIG5:zeroCount', ...
            'No studies found for: %s. Check exact spelling in EF_Category.', ...
            strjoin(ef_labels_final(zero_named_mask), ', '));
end

ef_labels_sorted = ef_labels_final;
ef_counts_sorted = ef_counts_final;

% -------------------------------------------------------------------------
% 5. Style settings
% -------------------------------------------------------------------------
clr_main   = [0.65 0.65 0.65];   % five main EF categories
clr_others = [0.25 0.25 0.25];   % "Others"

fs_tick  = 13;
fs_label = 16;
fs_title = 18;

% -------------------------------------------------------------------------
% 6. Build figure (single centered panel)
% -------------------------------------------------------------------------
fig = figure('Units', 'centimeters', 'Position', [2 2 20 16], ...
             'Color', 'w');

% ---- 5A: Executive functions studied (centered) ---------------------------
n_ef = numel(ef_labels_sorted);
ax_a = axes('Position', [0.20  0.12  0.60  0.75]);   % centered: (1 - 0.60) / 2 = 0.20
b_ef = barh(1:n_ef, ef_counts_sorted, 0.6, ...
            'FaceColor', 'flat', 'EdgeColor', 'none');

% -- Per-bar color: "Others" gets its own shade, the five main EFs share one --
bar_colors = repmat(clr_main, n_ef, 1);
bar_colors(strcmp(ef_labels_sorted, 'Others'), :) = clr_others;
b_ef.CData = bar_colors;

yticks(1:n_ef);
yticklabels(ef_labels_sorted);
xlabel('Number of studies', 'FontSize', fs_label);
ax_a.XAxis.TickValues = 0:1:max(ef_counts_sorted)+1;
ax_a.Box       = 'off';
ax_a.FontSize  = fs_tick;
ax_a.XGrid     = 'on';
ax_a.GridAlpha = 0.3;
xlim([0, max(ef_counts_sorted) + 1]);

% -------------------------------------------------------------------------
% 7. Export
% -------------------------------------------------------------------------
exportgraphics(fig, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
savefig(fig, out_fig);

fprintf('\nFigure saved:\n  %s\n  %s\n', out_png, out_fig);
