function interactive
%INTERACTIVE Explore shared-motion sign and Sensor B scale independently.

clear model;
modelFcn = @model;
existingUi = findall(groot, 'Type', 'figure', 'Name', ...
    'P03 Covariance as Shared Motion');
if ~isempty(existingUi)
    close(existingUi);
end
fig = uifigure('Name', 'P03 Covariance as Shared Motion', ...
    'Position', [100 100 1180 700]);
layout = uigridlayout(fig, [3 4]);
layout.RowHeight = {52, '1x', 125};
layout.ColumnWidth = {'1x', '1x', '1x', 300};

prompt = uilabel(layout, 'Text', ...
    ['Change one lever at a time. rho changes the signed weight of shared ' ...
    'standardized motion. Sensor B scale changes covariance in mm^2 but not correlation.'], ...
    'WordWrap', 'on', 'FontWeight', 'bold');
prompt.Layout.Row = 1;
prompt.Layout.Column = [1 4];

traceAxes = uiaxes(layout);
traceAxes.Layout.Row = 2;
traceAxes.Layout.Column = [1 2];
scatterAxes = uiaxes(layout);
scatterAxes.Layout.Row = 2;
scatterAxes.Layout.Column = [3 4];

controls = uigridlayout(layout, [2 4]);
controls.Layout.Row = 3;
controls.Layout.Column = [1 4];
controls.RowHeight = {28, 58};
controls.ColumnWidth = {300, 170, 150, 300};

rhoLabel = uilabel(controls, ...
    'Text', 'Shared-motion coefficient rho (dimensionless)');
rhoLabel.Layout.Row = 1; rhoLabel.Layout.Column = 1;
rhoSlider = uislider(controls, 'Limits', [-0.95 0.95], 'Value', 0.70, ...
    'MajorTicks', [-0.9 -0.5 0 0.5 0.9]);
rhoSlider.Layout.Row = 2; rhoSlider.Layout.Column = 1;

scaleLabel = uilabel(controls, 'Text', 'Sensor B RMS scale (mm)');
scaleLabel.Layout.Row = 1; scaleLabel.Layout.Column = 2;
scaleSpinner = uispinner(controls, 'Limits', [0.25 4.00], ...
    'Value', 1.50, 'Step', 0.25);
scaleSpinner.Layout.Row = 2; scaleSpinner.Layout.Column = 2;

seedLabel = uilabel(controls, 'Text', 'Realization seed');
seedLabel.Layout.Row = 1; seedLabel.Layout.Column = 3;
seedSpinner = uispinner(controls, 'Limits', [0 10000], ...
    'Value', 303, 'Step', 1, 'RoundFractionalValues', 'on');
seedSpinner.Layout.Row = 2; seedSpinner.Layout.Column = 3;

summary = uilabel(controls, 'Text', '', 'WordWrap', 'on');
summary.Layout.Row = [1 2]; summary.Layout.Column = 4;

rhoSlider.ValueChangedFcn = @(~,~) updatePlots();
scaleSpinner.ValueChangedFcn = @(~,~) updatePlots();
seedSpinner.ValueChangedFcn = @(~,~) updatePlots();
updatePlots();

    function updatePlots()
        sampleCount = 400;
        rho = rhoSlider.Value;
        sigmaBMillimeters = scaleSpinner.Value;
        seed = round(seedSpinner.Value);
        out = modelFcn(sampleCount, rho, 1.0, sigmaBMillimeters, seed);

        visibleCount = min(sampleCount, 160);
        cla(traceAxes);
        plot(traceAxes, 1:visibleCount, ...
            out.centered_a_millimeters(1:visibleCount), 'LineWidth', 1.0);
        hold(traceAxes, 'on');
        plot(traceAxes, 1:visibleCount, ...
            out.centered_b_millimeters(1:visibleCount), 'LineWidth', 1.0);
        yline(traceAxes, 0, 'k--');
        hold(traceAxes, 'off');
        grid(traceAxes, 'on');
        xlabel(traceAxes, 'Observation index (sample)');
        ylabel(traceAxes, 'Centered displacement (mm)');
        title(traceAxes, sprintf('First %d paired deviations', visibleCount));
        legend(traceAxes, {'Sensor A', 'Sensor B'}, 'Location', 'best');

        cla(scatterAxes);
        scatter(scatterAxes, out.centered_a_millimeters, ...
            out.centered_b_millimeters, 14, 'filled');
        hold(scatterAxes, 'on');
        xline(scatterAxes, 0, 'k--');
        yline(scatterAxes, 0, 'k--');
        hold(scatterAxes, 'off');
        grid(scatterAxes, 'on');
        axis(scatterAxes, 'equal');
        maximumInteractiveSigmaBMillimeters = 4.00;
        unitScaleB = out.centered_b_millimeters / sigmaBMillimeters;
        stableXLimitMillimeters = 1.05 * max(abs(out.centered_a_millimeters));
        stableYLimitMillimeters = 1.05 * maximumInteractiveSigmaBMillimeters * ...
            max(abs(unitScaleB));
        xlim(scatterAxes, ...
            [-stableXLimitMillimeters stableXLimitMillimeters]);
        ylim(scatterAxes, ...
            [-stableYLimitMillimeters stableYLimitMillimeters]);
        xlabel(scatterAxes, 'Sensor A deviation (mm)');
        ylabel(scatterAxes, 'Sensor B deviation (mm)');
        title(scatterAxes, sprintf('rho = %.2f; covariance = %.2f mm^2', ...
            out.correlation_coefficient, out.covariance_millimeters_squared));

        summary.Text = sprintf(['N = %d pairs\nsigma_A = %.2f mm\nsigma_B = %.2f mm\n' ...
            'covariance = %.3f mm^2\ncorrelation = %.3f\n' ...
            'same-direction products = %.1f%%'], ...
            out.sample_count, out.standard_deviation_a_millimeters, ...
            out.standard_deviation_b_millimeters, ...
            out.covariance_millimeters_squared, ...
            out.correlation_coefficient, 100 * out.same_direction_fraction);
        drawnow limitrate;
    end
end
