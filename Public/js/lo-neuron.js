/**
 * LO-Neuron — Interactive Neuron Slider
 * Like One Academy — AI Foundations
 * Vanilla JS, zero dependencies, SVG visualization
 */
(function() {
  'use strict';

  function init(container) {
    if (container.dataset.init) return;
    container.dataset.init = '1';

    var state = {
      inputs: [0.5, 0.3, 0.7],
      weights: [0.8, -0.4, 0.6],
      bias: 0.1,
      activation: 'relu'
    };

    var colors = {
      inputs: ['#34d399', '#8b5cf6', '#38bdf8'],
      positive: '#34d399',
      negative: '#f87171',
      neutral: '#71717a',
      purple: '#c084fc',
      bg: '#0a0a0f',
      card: '#1a1a24',
      border: '#27272a',
      text: '#f5f5f7',
      muted: '#a1a1aa'
    };

    // Build DOM
    container.innerHTML = '';
    container.style.cssText = 'background:#111118;border:1px solid ' + colors.border + ';border-radius:16px;padding:24px;margin:16px 0;';

    // SVG Visualization
    var svgWrap = document.createElement('div');
    svgWrap.style.cssText = 'margin-bottom:20px;overflow:hidden;border-radius:12px;background:#0a0a0f;border:1px solid rgba(255,255,255,.06);';
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 480 200');
    svg.setAttribute('width', '100%');
    svg.style.display = 'block';
    svgWrap.appendChild(svg);
    container.appendChild(svgWrap);

    // Controls
    var controlsWrap = document.createElement('div');
    controlsWrap.style.cssText = 'display:grid;grid-template-columns:1fr 1fr;gap:16px;';
    container.appendChild(controlsWrap);

    var leftCol = document.createElement('div');
    var rightCol = document.createElement('div');
    controlsWrap.appendChild(leftCol);
    controlsWrap.appendChild(rightCol);

    // Activation selector
    var actRow = document.createElement('div');
    actRow.style.cssText = 'display:flex;gap:6px;margin-top:16px;justify-content:center;';
    container.appendChild(actRow);

    // Output display
    var outputRow = document.createElement('div');
    outputRow.style.cssText = 'margin-top:16px;padding:14px 16px;background:#0a0a0f;border:1px solid rgba(255,255,255,.06);border-radius:10px;font-family:"SF Mono","JetBrains Mono",monospace;font-size:.82rem;color:' + colors.muted + ';line-height:1.6;';
    container.appendChild(outputRow);

    function makeSlider(label, value, min, max, step, color, onChange) {
      var wrap = document.createElement('div');
      wrap.style.cssText = 'margin-bottom:12px;';

      var row = document.createElement('div');
      row.style.cssText = 'display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;';

      var lbl = document.createElement('span');
      lbl.style.cssText = 'font-size:.78rem;font-weight:600;color:' + color + ';';
      lbl.textContent = label;

      var val = document.createElement('span');
      val.style.cssText = 'font-size:.82rem;font-weight:700;color:' + colors.text + ';font-variant-numeric:tabular-nums;font-family:"SF Mono","JetBrains Mono",monospace;';
      val.textContent = value.toFixed(2);

      row.appendChild(lbl);
      row.appendChild(val);
      wrap.appendChild(row);

      var input = document.createElement('input');
      input.type = 'range';
      input.min = min;
      input.max = max;
      input.step = step;
      input.value = value;
      input.style.cssText = 'width:100%;height:4px;-webkit-appearance:none;appearance:none;background:' + colors.border + ';border-radius:2px;outline:none;cursor:pointer;accent-color:' + color + ';';
      input.addEventListener('input', function() {
        val.textContent = parseFloat(input.value).toFixed(2);
        onChange(parseFloat(input.value));
      });
      wrap.appendChild(input);
      return wrap;
    }

    // Input sliders
    var inputLabel = document.createElement('div');
    inputLabel.style.cssText = 'font-size:.7rem;font-weight:700;letter-spacing:.08em;color:' + colors.muted + ';text-transform:uppercase;margin-bottom:8px;';
    inputLabel.textContent = 'Inputs';
    leftCol.appendChild(inputLabel);

    for (var i = 0; i < 3; i++) {
      (function(idx) {
        leftCol.appendChild(makeSlider(
          'x' + (idx + 1), state.inputs[idx], 0, 1, 0.01, colors.inputs[idx],
          function(v) { state.inputs[idx] = v; update(); }
        ));
      })(i);
    }

    // Weight + Bias sliders
    var weightLabel = document.createElement('div');
    weightLabel.style.cssText = 'font-size:.7rem;font-weight:700;letter-spacing:.08em;color:' + colors.muted + ';text-transform:uppercase;margin-bottom:8px;';
    weightLabel.textContent = 'Weights & Bias';
    rightCol.appendChild(weightLabel);

    for (var j = 0; j < 3; j++) {
      (function(idx) {
        rightCol.appendChild(makeSlider(
          'w' + (idx + 1), state.weights[idx], -1, 1, 0.01, colors.inputs[idx],
          function(v) { state.weights[idx] = v; update(); }
        ));
      })(j);
    }
    rightCol.appendChild(makeSlider(
      'bias', state.bias, -1, 1, 0.01, colors.purple,
      function(v) { state.bias = v; update(); }
    ));

    // Activation buttons
    var actLabel = document.createElement('span');
    actLabel.style.cssText = 'font-size:.7rem;font-weight:700;letter-spacing:.08em;color:' + colors.muted + ';text-transform:uppercase;margin-right:8px;line-height:32px;';
    actLabel.textContent = 'Activation';
    actRow.appendChild(actLabel);

    ['relu', 'sigmoid', 'step'].forEach(function(name) {
      var btn = document.createElement('button');
      btn.textContent = name.charAt(0).toUpperCase() + name.slice(1);
      btn.dataset.act = name;
      btn.style.cssText = 'padding:6px 14px;border-radius:9999px;font-size:.78rem;font-weight:600;cursor:pointer;border:1px solid ' + colors.border + ';background:transparent;color:' + colors.muted + ';font-family:inherit;transition:all .2s;min-height:32px;';
      btn.addEventListener('click', function() {
        state.activation = name;
        actRow.querySelectorAll('button').forEach(function(b) {
          var active = b.dataset.act === name;
          b.style.background = active ? 'rgba(168,85,247,.15)' : 'transparent';
          b.style.borderColor = active ? 'rgba(168,85,247,.4)' : colors.border;
          b.style.color = active ? colors.purple : colors.muted;
        });
        update();
      });
      if (name === state.activation) {
        btn.style.background = 'rgba(168,85,247,.15)';
        btn.style.borderColor = 'rgba(168,85,247,.4)';
        btn.style.color = colors.purple;
      }
      actRow.appendChild(btn);
    });

    function activate(z, type) {
      switch (type) {
        case 'relu': return Math.max(0, z);
        case 'sigmoid': return 1 / (1 + Math.exp(-z));
        case 'step': return z >= 0 ? 1 : 0;
        default: return z;
      }
    }

    function drawSVG(z, output) {
      var ns = 'http://www.w3.org/2000/svg';
      svg.innerHTML = '';

      // Background grid (subtle)
      for (var gx = 0; gx < 480; gx += 20) {
        var gl = document.createElementNS(ns, 'line');
        gl.setAttribute('x1', gx); gl.setAttribute('y1', 0);
        gl.setAttribute('x2', gx); gl.setAttribute('y2', 200);
        gl.setAttribute('stroke', 'rgba(255,255,255,.02)');
        svg.appendChild(gl);
      }
      for (var gy = 0; gy < 200; gy += 20) {
        var glh = document.createElementNS(ns, 'line');
        glh.setAttribute('x1', 0); glh.setAttribute('y1', gy);
        glh.setAttribute('x2', 480); glh.setAttribute('y2', gy);
        glh.setAttribute('stroke', 'rgba(255,255,255,.02)');
        svg.appendChild(glh);
      }

      // Input nodes (left)
      var inputPositions = [[60, 40], [60, 100], [60, 160]];
      // Neuron (center)
      var neuronPos = [240, 100];
      // Output node (right)
      var outputPos = [420, 100];

      // Connection lines (input → neuron)
      for (var ci = 0; ci < 3; ci++) {
        var w = state.weights[ci];
        var absW = Math.min(Math.abs(w), 1);
        var lineColor = w >= 0 ? colors.positive : colors.negative;
        var opacity = 0.2 + absW * 0.6;
        var width = 1 + absW * 3;

        var line = document.createElementNS(ns, 'line');
        line.setAttribute('x1', inputPositions[ci][0] + 18);
        line.setAttribute('y1', inputPositions[ci][1]);
        line.setAttribute('x2', neuronPos[0] - 28);
        line.setAttribute('y2', neuronPos[1]);
        line.setAttribute('stroke', lineColor);
        line.setAttribute('stroke-opacity', opacity);
        line.setAttribute('stroke-width', width);
        svg.appendChild(line);

        // Weight label on line
        var midX = (inputPositions[ci][0] + 18 + neuronPos[0] - 28) / 2;
        var midY = (inputPositions[ci][1] + neuronPos[1]) / 2 - 6;
        var wLabel = document.createElementNS(ns, 'text');
        wLabel.setAttribute('x', midX);
        wLabel.setAttribute('y', midY);
        wLabel.setAttribute('font-size', '9');
        wLabel.setAttribute('fill', lineColor);
        wLabel.setAttribute('text-anchor', 'middle');
        wLabel.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
        wLabel.setAttribute('opacity', '0.7');
        wLabel.textContent = 'w' + (ci + 1) + '=' + w.toFixed(2);
        svg.appendChild(wLabel);
      }

      // Neuron → Output line
      var outLine = document.createElementNS(ns, 'line');
      outLine.setAttribute('x1', neuronPos[0] + 28);
      outLine.setAttribute('y1', neuronPos[1]);
      outLine.setAttribute('x2', outputPos[0] - 18);
      outLine.setAttribute('y2', outputPos[1]);
      var outOpacity = 0.2 + Math.min(Math.abs(output), 1) * 0.6;
      outLine.setAttribute('stroke', output > 0 ? colors.positive : colors.neutral);
      outLine.setAttribute('stroke-opacity', outOpacity);
      outLine.setAttribute('stroke-width', 1 + Math.min(Math.abs(output), 1) * 3);
      svg.appendChild(outLine);

      // Input circles
      for (var ni = 0; ni < 3; ni++) {
        var inVal = state.inputs[ni];
        var circle = document.createElementNS(ns, 'circle');
        circle.setAttribute('cx', inputPositions[ni][0]);
        circle.setAttribute('cy', inputPositions[ni][1]);
        circle.setAttribute('r', 16);
        circle.setAttribute('fill', colors.bg);
        circle.setAttribute('stroke', colors.inputs[ni]);
        circle.setAttribute('stroke-width', 1.5);
        svg.appendChild(circle);

        // Glow based on input value
        var glow = document.createElementNS(ns, 'circle');
        glow.setAttribute('cx', inputPositions[ni][0]);
        glow.setAttribute('cy', inputPositions[ni][1]);
        glow.setAttribute('r', 16);
        glow.setAttribute('fill', colors.inputs[ni]);
        glow.setAttribute('opacity', inVal * 0.25);
        svg.appendChild(glow);

        var inLabel = document.createElementNS(ns, 'text');
        inLabel.setAttribute('x', inputPositions[ni][0]);
        inLabel.setAttribute('y', inputPositions[ni][1] + 4);
        inLabel.setAttribute('font-size', '11');
        inLabel.setAttribute('fill', colors.text);
        inLabel.setAttribute('text-anchor', 'middle');
        inLabel.setAttribute('font-weight', '600');
        inLabel.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
        inLabel.textContent = inVal.toFixed(1);
        svg.appendChild(inLabel);

        // x label
        var xLbl = document.createElementNS(ns, 'text');
        xLbl.setAttribute('x', inputPositions[ni][0]);
        xLbl.setAttribute('y', inputPositions[ni][1] - 22);
        xLbl.setAttribute('font-size', '9');
        xLbl.setAttribute('fill', colors.inputs[ni]);
        xLbl.setAttribute('text-anchor', 'middle');
        xLbl.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
        xLbl.textContent = 'x' + (ni + 1);
        svg.appendChild(xLbl);
      }

      // Neuron body
      var neuronGrad = document.createElementNS(ns, 'radialGradient');
      neuronGrad.id = 'neuron-grad';
      neuronGrad.innerHTML = '<stop offset="0%" stop-color="' + colors.purple + '" stop-opacity="0.15"/><stop offset="100%" stop-color="' + colors.bg + '" stop-opacity="0"/>';
      var defs = document.createElementNS(ns, 'defs');
      defs.appendChild(neuronGrad);
      svg.appendChild(defs);

      var neuronBg = document.createElementNS(ns, 'circle');
      neuronBg.setAttribute('cx', neuronPos[0]);
      neuronBg.setAttribute('cy', neuronPos[1]);
      neuronBg.setAttribute('r', 36);
      neuronBg.setAttribute('fill', 'url(#neuron-grad)');
      svg.appendChild(neuronBg);

      var neuronCircle = document.createElementNS(ns, 'circle');
      neuronCircle.setAttribute('cx', neuronPos[0]);
      neuronCircle.setAttribute('cy', neuronPos[1]);
      neuronCircle.setAttribute('r', 26);
      neuronCircle.setAttribute('fill', colors.bg);
      neuronCircle.setAttribute('stroke', colors.purple);
      neuronCircle.setAttribute('stroke-width', 2);
      svg.appendChild(neuronCircle);

      // Sigma symbol
      var sigma = document.createElementNS(ns, 'text');
      sigma.setAttribute('x', neuronPos[0]);
      sigma.setAttribute('y', neuronPos[1] + 6);
      sigma.setAttribute('font-size', '18');
      sigma.setAttribute('fill', colors.purple);
      sigma.setAttribute('text-anchor', 'middle');
      sigma.setAttribute('font-weight', '300');
      sigma.textContent = '\u03A3';
      svg.appendChild(sigma);

      // Bias label
      var biasLbl = document.createElementNS(ns, 'text');
      biasLbl.setAttribute('x', neuronPos[0]);
      biasLbl.setAttribute('y', neuronPos[1] + 44);
      biasLbl.setAttribute('font-size', '9');
      biasLbl.setAttribute('fill', colors.purple);
      biasLbl.setAttribute('text-anchor', 'middle');
      biasLbl.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
      biasLbl.setAttribute('opacity', '0.8');
      biasLbl.textContent = 'bias=' + state.bias.toFixed(2);
      svg.appendChild(biasLbl);

      // Activation label
      var actLbl = document.createElementNS(ns, 'text');
      actLbl.setAttribute('x', (neuronPos[0] + outputPos[0]) / 2);
      actLbl.setAttribute('y', neuronPos[1] - 16);
      actLbl.setAttribute('font-size', '9');
      actLbl.setAttribute('fill', colors.muted);
      actLbl.setAttribute('text-anchor', 'middle');
      actLbl.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
      actLbl.textContent = state.activation + '(z)';
      svg.appendChild(actLbl);

      // Output node
      var outFired = output > 0;
      var outCircle = document.createElementNS(ns, 'circle');
      outCircle.setAttribute('cx', outputPos[0]);
      outCircle.setAttribute('cy', outputPos[1]);
      outCircle.setAttribute('r', 16);
      outCircle.setAttribute('fill', colors.bg);
      outCircle.setAttribute('stroke', outFired ? colors.positive : colors.neutral);
      outCircle.setAttribute('stroke-width', 1.5);
      svg.appendChild(outCircle);

      if (outFired) {
        var outGlow = document.createElementNS(ns, 'circle');
        outGlow.setAttribute('cx', outputPos[0]);
        outGlow.setAttribute('cy', outputPos[1]);
        outGlow.setAttribute('r', 16);
        outGlow.setAttribute('fill', colors.positive);
        outGlow.setAttribute('opacity', Math.min(output, 1) * 0.3);
        svg.appendChild(outGlow);
      }

      var outVal = document.createElementNS(ns, 'text');
      outVal.setAttribute('x', outputPos[0]);
      outVal.setAttribute('y', outputPos[1] + 4);
      outVal.setAttribute('font-size', '11');
      outVal.setAttribute('fill', outFired ? colors.positive : colors.neutral);
      outVal.setAttribute('text-anchor', 'middle');
      outVal.setAttribute('font-weight', '600');
      outVal.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
      outVal.textContent = output.toFixed(2);
      svg.appendChild(outVal);

      var outLbl = document.createElementNS(ns, 'text');
      outLbl.setAttribute('x', outputPos[0]);
      outLbl.setAttribute('y', outputPos[1] - 22);
      outLbl.setAttribute('font-size', '9');
      outLbl.setAttribute('fill', outFired ? colors.positive : colors.neutral);
      outLbl.setAttribute('text-anchor', 'middle');
      outLbl.setAttribute('font-family', '"SF Mono","JetBrains Mono",monospace');
      outLbl.textContent = 'output';
      svg.appendChild(outLbl);
    }

    function update() {
      var products = [];
      var z = state.bias;
      for (var k = 0; k < 3; k++) {
        var p = state.inputs[k] * state.weights[k];
        products.push(p);
        z += p;
      }
      var output = activate(z, state.activation);

      drawSVG(z, output);

      // Update output display
      var parts = [];
      for (var m = 0; m < 3; m++) {
        parts.push('<span style="color:' + colors.inputs[m] + '">' + state.inputs[m].toFixed(2) + ' x ' + state.weights[m].toFixed(2) + ' = ' + products[m].toFixed(4) + '</span>');
      }
      outputRow.innerHTML =
        '<div style="margin-bottom:4px"><span style="color:' + colors.muted + '">weighted sum:</span> ' + parts.join(' + ') + '</div>' +
        '<div style="margin-bottom:4px"><span style="color:' + colors.muted + '">z = sum + bias:</span> <span style="color:' + colors.text + ';font-weight:700">' + z.toFixed(4) + '</span></div>' +
        '<div><span style="color:' + colors.muted + '">' + state.activation + '(' + z.toFixed(2) + ') =</span> <span style="color:' + (output > 0 ? colors.positive : colors.neutral) + ';font-weight:700;font-size:1.1em">' + output.toFixed(4) + '</span>' +
        (output > 0 ? ' <span style="color:' + colors.positive + '">FIRES</span>' : ' <span style="color:' + colors.neutral + '">SILENT</span>') + '</div>';
    }

    update();
  }

  // Auto-init on DOMContentLoaded
  document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.lo-neuron').forEach(init);
  });

  // Expose for manual init
  window.LONeuron = { init: init };
})();
