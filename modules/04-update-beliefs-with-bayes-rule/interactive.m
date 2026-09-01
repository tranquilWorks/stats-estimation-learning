function interactive
%INTERACTIVE Explore how prior and alarm quality change a Bayes update.

clear model;
modelFcn = @model;
existingUi = findall(groot, 'Type', 'figure', 'Name', ...
    'P04 Bayes Rule Explorer');
if ~isempty(existingUi)
    close(existingUi);
end

fig = uifigure('Name', 'P04 Bayes Rule Explorer', ...
    'Position', [100 100 1180 720]);
layout = uigridlayout(fig, [3 2]);
layout.RowHeight = {64, '1x', 175};
layout.ColumnWidth = {'1x', '1x'};

prompt = uilabel(layout, 'Text', ...
    ['Move one lever at a time. The prior changes how many candidates begin ' ...
    'in each condition; sensitivity and false-alarm probability change how ' ...
    'each condition contributes to the observed alarm.'], ...
    'WordWrap', 'on', 'FontWeight', 'bold');
prompt.Layout.Row = 1;
prompt.Layout.Column = [1 2];

beliefAxes = uiaxes(layout);
beliefAxes.Layout.Row = 2;
beliefAxes.Layout.Column = 1;
sourceAxes = uiaxes(layout);
sourceAxes.Layout.Row = 2;
sourceAxes.Layout.Column = 2;

controls = uigridlayout(layout, [3 4]);
controls.Layout.Row = 3;
controls.Layout.Column = [1 2];
controls.RowHeight = {28, 58, 70};
controls.ColumnWidth = {280, 280, 280, '1x'};

priorLabel = uilabel(controls, ...
    'Text', 'Prior fault probability (dimensionless)');
priorLabel.Layout.Row = 1;
priorLabel.Layout.Column = 1;
priorSlider = uislider(controls, 'Limits', [0.001 0.50], ...
    'Value', 0.01, 'MajorTicks', [0.001 0.01 0.10 0.25 0.50]);
priorSlider.Layout.Row = 2;
priorSlider.Layout.Column = 1;

sensitivityLabel = uilabel(controls, ...
    'Text', 'Sensitivity P(alarm | fault) (dimensionless)');
sensitivityLabel.Layout.Row = 1;
sensitivityLabel.Layout.Column = 2;
sensitivitySlider = uislider(controls, 'Limits', [0.05 1.00], ...
    'Value', 0.90, 'MajorTicks', [0.05 0.25 0.50 0.75 1.00]);
sensitivitySlider.Layout.Row = 2;
sensitivitySlider.Layout.Column = 2;

falseAlarmLabel = uilabel(controls, ...
    'Text', 'False-alarm P(alarm | healthy) (dimensionless)');
falseAlarmLabel.Layout.Row = 1;
falseAlarmLabel.Layout.Column = 3;
falseAlarmSlider = uislider(controls, 'Limits', [0.00 0.50], ...
    'Value', 0.10, 'MajorTicks', [0.00 0.01 0.10 0.25 0.50]);
falseAlarmSlider.Layout.Row = 2;
falseAlarmSlider.Layout.Column = 3;

resetButton = uibutton(controls, 'push', 'Text', 'Reset baseline');
resetButton.Layout.Row = 2;
resetButton.Layout.Column = 4;

summary = uilabel(controls, 'Text', '', 'WordWrap', 'on');
summary.Layout.Row = 3;
summary.Layout.Column = [1 4];

priorSlider.ValueChangedFcn = @(~,~) updatePlots();
sensitivitySlider.ValueChangedFcn = @(~,~) updatePlots();
falseAlarmSlider.ValueChangedFcn = @(~,~) updatePlots();
resetButton.ButtonPushedFcn = @(~,~) resetBaseline();
updatePlots();

    function resetBaseline()
        priorSlider.Value = 0.01;
        sensitivitySlider.Value = 0.90;
        falseAlarmSlider.Value = 0.10;
        updatePlots();
    end

    function updatePlots()
        referencePopulationCount = 10000;
        out = modelFcn(priorSlider.Value, sensitivitySlider.Value, ...
            falseAlarmSlider.Value, referencePopulationCount);

        cla(beliefAxes);
        bar(beliefAxes, 100 * [out.prior_fault_probability, ...
            out.posterior_fault_given_alarm_probability]);
        beliefAxes.XTick = 1:2;
        beliefAxes.XTickLabel = {'Prior fault', 'Fault after alarm'};
        grid(beliefAxes, 'on');
        xlabel(beliefAxes, 'Belief stage');
        ylabel(beliefAxes, 'Fault probability (%)');
        title(beliefAxes, 'Bayes update after one alarm');
        ylim(beliefAxes, [0 100]);

        cla(sourceAxes);
        bar(sourceAxes, [out.expected_fault_alarm_count, ...
            out.expected_healthy_alarm_count]);
        sourceAxes.XTick = 1:2;
        sourceAxes.XTickLabel = {'Fault alarms', 'Healthy alarms'};
        grid(sourceAxes, 'on');
        xlabel(sourceAxes, 'Source of observed alarms');
        ylabel(sourceAxes, ...
            'Expected alarms per 10000 systems (count)');
        title(sourceAxes, 'Prior-weighted alarm paths');
        ylim(sourceAxes, [0 5500]);

        summary.Text = sprintf(['prior = %.3f (%.2f%%) | sensitivity = %.3f | ' ...
            'false alarm = %.3f | P(alarm) = %.3f\n' ...
            'expected alarm sources = %.1f fault + %.1f healthy per 10000 | ' ...
            'posterior P(fault | alarm) = %.4f (%.2f%%)'], ...
            out.prior_fault_probability, 100 * out.prior_fault_probability, ...
            out.alarm_given_fault_probability, ...
            out.alarm_given_healthy_probability, out.alarm_probability, ...
            out.expected_fault_alarm_count, ...
            out.expected_healthy_alarm_count, ...
            out.posterior_fault_given_alarm_probability, ...
            100 * out.posterior_fault_given_alarm_probability);
        drawnow limitrate;
    end
end
