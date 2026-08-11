function interactive
%INTERACTIVE Explore Bernoulli convergence with live controls.
fig = uifigure('Name','P01 Randomness and Repetition','Position',[100 100 1100 700]);
grid = uigridlayout(fig,[3 4]);
grid.RowHeight = {'1x','1x',90};
grid.ColumnWidth = {'1x','1x','1x','1x'};

axRun = uiaxes(grid); axRun.Layout.Row = 1; axRun.Layout.Column = [1 2];
axHist = uiaxes(grid); axHist.Layout.Row = 1; axHist.Layout.Column = [3 4];
axTrials = uiaxes(grid); axTrials.Layout.Row = 2; axTrials.Layout.Column = [1 4];

nSlider = uislider(grid,'Limits',[10 1000],'Value',200, ...
    'MajorTicks',[10 100 250 500 1000]);
nSlider.Layout.Row = 3; nSlider.Layout.Column = 1;
pSlider = uislider(grid,'Limits',[0.05 0.95],'Value',0.5, ...
    'MajorTicks',[0.05 0.25 0.5 0.75 0.95]);
pSlider.Layout.Row = 3; pSlider.Layout.Column = 2;
seedSpinner = uispinner(grid,'Limits',[0 10000],'Value',84,'Step',1);
seedSpinner.Layout.Row = 3; seedSpinner.Layout.Column = 3;
summary = uilabel(grid,'Text','','WordWrap','on');
summary.Layout.Row = 3; summary.Layout.Column = 4;

nSlider.ValueChangingFcn = @(~,e) updatePlots(round(e.Value),pSlider.Value,seedSpinner.Value);
nSlider.ValueChangedFcn = @(~,~) updatePlots(round(nSlider.Value),pSlider.Value,seedSpinner.Value);
pSlider.ValueChangingFcn = @(~,e) updatePlots(round(nSlider.Value),e.Value,seedSpinner.Value);
pSlider.ValueChangedFcn = @(~,~) updatePlots(round(nSlider.Value),pSlider.Value,seedSpinner.Value);
seedSpinner.ValueChangedFcn = @(~,~) updatePlots(round(nSlider.Value),pSlider.Value,seedSpinner.Value);
updatePlots(round(nSlider.Value),pSlider.Value,seedSpinner.Value);

    function updatePlots(n,p,seed)
        out = model(n,p,seed);
        cla(axRun); plot(axRun,1:n,out.running_probability,'LineWidth',1.3);
        hold(axRun,'on'); yline(axRun,p,'--'); hold(axRun,'off');
        grid(axRun,'on'); xlabel(axRun,'Trial'); ylabel(axRun,'Running proportion');
        title(axRun,'Does the estimate settle?'); ylim(axRun,[0 1]);

        cla(axHist); histogram(axHist,out.counts,'BinMethod','integers', ...
            'Normalization','probability');
        hold(axHist,'on'); xline(axHist,out.expected_count,'--'); hold(axHist,'off');
        grid(axHist,'on'); xlabel(axHist,'Success count'); ylabel(axHist,'Probability');
        title(axHist,'Sampling distribution');

        window = min(n,120);
        cla(axTrials); stem(axTrials,1:window,double(out.trials(1:window)),'filled');
        grid(axTrials,'on'); ylim(axTrials,[-0.1 1.1]);
        xlabel(axTrials,'Trial'); ylabel(axTrials,'Outcome');
        title(axTrials,sprintf('First %d outcomes: randomness remains locally irregular',window));

        summary.Text = sprintf(['n = %d\np = %.3f\nobserved p-hat = %.3f\n' ...
            'nominal standard error = %.4f'],n,p,out.observed_probability,out.standard_error);
    end
end
