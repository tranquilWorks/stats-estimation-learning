function interactive
%INTERACTIVE Explore how sample count and bin width change a histogram.

clear model;
modelFcn = @model;
existingUi = findall(groot, 'Type', 'figure', 'Name', ...
    'P02 Random Variables into Histograms');
if ~isempty(existingUi)
    close(existingUi);
end
fig = uifigure('Name', 'P02 Random Variables into Histograms', ...
    'Position', [100 100 1180 700]);
layout = uigridlayout(fig, [3 4]);
layout.RowHeight = {42, '1x', 115};
layout.ColumnWidth = {'1x', '1x', '1x', '1x'};

prompt = uilabel(layout, 'Text', ...
    ['Change one lever at a time: N changes support per bar; bin width changes ' ...
    'the intervals used to summarize the same seeded measurements. The listed ' ...
    'widths all preserve the displayed -4 to 4 mV support.'], ...
    'WordWrap', 'on', 'FontWeight', 'bold');
prompt.Layout.Row = 1;
prompt.Layout.Column = [1 4];

sampleAxes = uiaxes(layout);
sampleAxes.Layout.Row = 2;
sampleAxes.Layout.Column = [1 2];
histogramAxes = uiaxes(layout);
histogramAxes.Layout.Row = 2;
histogramAxes.Layout.Column = [3 4];

controls = uigridlayout(layout, [2 4]);
controls.Layout.Row = 3;
controls.Layout.Column = [1 4];
controls.RowHeight = {26, 50};
controls.ColumnWidth = {170, '1x', 170, 300};

nLabel = uilabel(controls, 'Text', 'Sample count N (samples)');
nLabel.Layout.Row = 1; nLabel.Layout.Column = 1;
nSpinner = uispinner(controls, 'Limits', [50 5000], ...
    'Value', 1000, 'Step', 50, 'RoundFractionalValues', 'on');
nSpinner.Layout.Row = 2; nSpinner.Layout.Column = 1;

widthLabel = uilabel(controls, 'Text', 'Bin width (mV)');
widthLabel.Layout.Row = 1; widthLabel.Layout.Column = 2;
widthDropdown = uidropdown(controls, ...
    'Items', {'0.25', '0.50', '1.00', '2.00'}, 'Value', '0.50');
widthDropdown.Layout.Row = 2; widthDropdown.Layout.Column = 2;

seedLabel = uilabel(controls, 'Text', 'Realization seed');
seedLabel.Layout.Row = 1; seedLabel.Layout.Column = 3;
seedSpinner = uispinner(controls, 'Limits', [0 10000], ...
    'Value', 202, 'Step', 1, 'RoundFractionalValues', 'on');
seedSpinner.Layout.Row = 2; seedSpinner.Layout.Column = 3;

summary = uilabel(controls, 'Text', '', 'WordWrap', 'on');
summary.Layout.Row = [1 2]; summary.Layout.Column = 4;

nSpinner.ValueChangedFcn = @(~,~) updatePlots();
widthDropdown.ValueChangedFcn = @(~,~) updatePlots();
seedSpinner.ValueChangedFcn = @(~,~) updatePlots();
updatePlots();

    function updatePlots()
        widthMillivolts = str2double(widthDropdown.Value);
        sampleCount = round(nSpinner.Value);
        seed = round(seedSpinner.Value);
        out = modelFcn(sampleCount, widthMillivolts, 1.0, seed);

        visibleCount = min(sampleCount, 250);
        cla(sampleAxes);
        plot(sampleAxes, 1:visibleCount, ...
            out.samples_millivolts(1:visibleCount), '.', 'MarkerSize', 8);
        hold(sampleAxes, 'on');
        yline(sampleAxes, 0, '--');
        hold(sampleAxes, 'off');
        grid(sampleAxes, 'on');
        xlabel(sampleAxes, 'Measurement index (sample)');
        ylabel(sampleAxes, 'Sensor error X (mV)');
        title(sampleAxes, sprintf('First %d outcomes remain individual numbers', visibleCount));

        cla(histogramAxes);
        bar(histogramAxes, out.bin_centers_millivolts, ...
            out.density_per_millivolt, 1, 'FaceColor', [0.25 0.55 0.85]);
        hold(histogramAxes, 'on');
        plot(histogramAxes, out.bin_centers_millivolts, ...
            out.theoretical_density_per_millivolt, 'k-', 'LineWidth', 1.5);
        hold(histogramAxes, 'off');
        grid(histogramAxes, 'on');
        xlabel(histogramAxes, 'Sensor error x (mV)');
        ylabel(histogramAxes, 'Probability density (1/mV)');
        title(histogramAxes, sprintf('N = %d, bin width = %.2f mV', ...
            sampleCount, widthMillivolts));

        summary.Text = sprintf(['bins = %d\nincluded = %.2f%%\nunderflow = %d samples\n' ...
            'overflow = %d samples\nmean = %.3f mV\nempirical RMS spread = %.3f mV\n' ...
            'area = %.6f'], ...
            numel(out.counts), 100 * out.included_fraction, ...
            out.underflow_count, out.overflow_count, out.sample_mean_millivolts, ...
            out.sample_standard_deviation_millivolts, ...
            out.normalization_area);
        drawnow limitrate;
    end
end
