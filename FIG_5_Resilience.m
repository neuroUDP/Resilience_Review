clear; clc;

% =========================================================================
% Figure 5. Executive functions evaluated.
%   5A: Horizontal bar chart — Executive functions studied
%
% Built from EF_Instrument_parsed.csv (long-format table: one row per
% Study x Instrument x EF_Category), instead of the raw EF_Evaluated
% column, since that column had verified discrepancies with the actual
% instrument-level data (e.g. some instruments' EF mapping were missing
% from EF_Evaluated but present in EF_Instrument).
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% 1. File paths
% -------------------------------------------------------------------------
parsed_csv_path = '/Users/josefinamattoli/Library/CloudStorage/GoogleDrive-josefinamattoli@gmail.com/.shortcut-targets-by-id/1x8K59aCdWa9nTsSzm0qLX40R4OEzEE2o/Practica_Electiva_Entre_Mentes_Y_Metodos_Alumnos/Nuestro paper/Revision_2/Analisis_Revision_2/EF_Instrument_parsed.csv';

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
% 3. Map each (free-text) EF_Category entry to one of the five canonical
%    executive function categories, via keyword/synonym matching — the
%    same approach used to build Table 6. Anything that doesn't match is
%    left unmapped and pooled into "Others".
% -------------------------------------------------------------------------
canonical_labels = {'Working memory', 'Inhibitory control', 'Cognitive flexibility', ...
                     'Attention', 'Cognitive control'};

synonym_terms  = {'working memory', 'digit span', ...
                   'inhibitory control', 'inhibit', 'inhibition', ...
                   'cognitive flexibility', 'shift', ...
                   'attention', 'attentional control', ...
                   'cognitive control'};
synonym_target = {'Working memory', 'Working memory', ...
                   'Inhibitory control', 'Inhibitory control', 'Inhibitory control', ...
                   'Cognitive flexibility', 'Cognitive flexibility', ...
                   'Attention', 'Attention', ...
                   'Cognitive control'};

n_rows = height(P);
P.EF_Canonical = repmat({'Others'}, n_rows, 1);

for r = 1:n_rows
    raw_lower = lower(P.EF_Category{r});
    for s = 1:numel(synonym_terms)
        if contains(raw_lower, synonym_terms{s})
            P.EF_Canonical{r} = synonym_target{s};
            break   % first match wins; canonical terms are checked before
                     % their broader synonyms in the list above
        end
    end
end

% -------------------------------------------------------------------------
% 4. Count N STUDIES (not N rows/instruments) per canonical EF category,
%    so that a study using two instruments for the same function is only
%    counted once
% -------------------------------------------------------------------------
ef_labels_final = [canonical_labels, {'Others'}]';
ef_counts_final = zeros(numel(ef_labels_final), 1);

for c = 1:numel(ef_labels_final)
    mask = strcmp(P.EF_Canonical, ef_labels_final{c});
    ef_counts_final(c) = numel(unique(P.Study_Authors(mask)));
end

% Drop categories with zero studies (shouldn't happen, but just in case)
keep = ef_counts_final > 0;
ef_labels_final = ef_labels_final(keep);
ef_counts_final = ef_counts_final(keep);

[ef_counts_sorted, sort_idx_ef] = sort(ef_counts_final, 'ascend');
ef_labels_sorted = ef_labels_final(sort_idx_ef);

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