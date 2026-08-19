% =========================================================================
% Figure 2. General characteristics of the included articles.
%   A: Temporal distribution of publications (bar chart)
%
% Panels B (geographic distribution) and C (participant type) were removed
% at the user's request. Map panels (country choropleth, participant-type
% map) were removed previously — those are being added manually outside
% MATLAB.
%
% Input:  CSV file with extracted data (first data row is metadata, skipped)
% Output: Figure saved as .png and .fig in the same folder as the CSV
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% 1. File paths
% -------------------------------------------------------------------------
csv_path = '/Users/josefinamattoli/Library/CloudStorage/GoogleDrive-josefinamattoli@gmail.com/.shortcut-targets-by-id/1x8K59aCdWa9nTsSzm0qLX40R4OEzEE2o/Practica_Electiva_Entre_Mentes_Y_Metodos_Alumnos/Nuestro paper/Revision_2/Analisis_Revision_2/Data_CasiFinal_Resiliencia.csv';

output_name = 'Figure2_General_Characteristics';

output_dir  = fileparts(csv_path);
out_png     = fullfile(output_dir, [output_name '.png']);
out_fig     = fullfile(output_dir, [output_name '.fig']);

% -------------------------------------------------------------------------
% 2. Load data (skip row 1 = metadata row, keep row 2 onward)
% -------------------------------------------------------------------------
opts                     = detectImportOptions(csv_path, 'Delimiter', ',');
opts.VariableNamesLine   = 1;
opts.DataLines           = [3 Inf];          % row 2 is metadata, skip it
opts                     = setvartype(opts, 'char');
T                        = readtable(csv_path, opts);

% -------------------------------------------------------------------------
% 3. Parse variables
% -------------------------------------------------------------------------

% -- Year --
years_raw = T.Year;
years     = [];
for i = 1:height(T)
    y = str2double(strtrim(years_raw{i}));
    if ~isnan(y)
        years(end+1) = y; %#ok<AGROW>
    end
end

% -------------------------------------------------------------------------
% 4. Aggregate counts
% -------------------------------------------------------------------------

% A — year counts
year_min    = min(years);
year_max    = max(years);
year_range  = year_min:year_max;
year_counts = arrayfun(@(y) sum(years == y), year_range);

% -------------------------------------------------------------------------
% 5. Style settings
% -------------------------------------------------------------------------
clr_bar = [0 0 0];   % black bars

fs_tick  = 22;   % tick labels
fs_label = 22;   % xlabel, ylabel
fs_title = 24;   % panel title A

% -------------------------------------------------------------------------
% 6. Build figure
% -------------------------------------------------------------------------
fig = figure('Units', 'centimeters', 'Position', [2 2 20 16], ...
             'Color', 'w');

% ---- A: Temporal distribution ---------------------------------------------
ax_a = axes('Position', [0.14  0.22  0.80  0.65]);
bar(year_range, year_counts, 0.6, 'FaceColor', clr_bar, 'EdgeColor', 'none');
xlabel('Publication year',   'FontSize', fs_label);
ylabel('Number of articles', 'FontSize', fs_label);
ax_a.XTick              = year_range;
ax_a.XTickLabelRotation = 45;
ax_a.YAxis.TickValues   = 0:1:max(year_counts)+1;
ax_a.Box                = 'off';
ax_a.FontSize           = fs_tick;
ax_a.YGrid              = 'on';
ax_a.GridAlpha          = 0.3;
ylim([0, max(year_counts) + 1]);

% -------------------------------------------------------------------------
% 7. Export
% -------------------------------------------------------------------------
exportgraphics(fig, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
savefig(fig, out_fig);

fprintf('\nFigure saved:\n  %s\n  %s\n', out_png, out_fig);