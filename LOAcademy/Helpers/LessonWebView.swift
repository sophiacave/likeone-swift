import SwiftUI
import WebKit

struct LessonWebView: UIViewRepresentable {
    let html: String
    let courseSlug: String
    let lessonSlug: String
    var onQuizPassed: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onQuizPassed: onQuizPassed)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let handler = context.coordinator
        config.userContentController.add(handler, name: "quizComplete")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onQuizPassed = onQuizPassed
        let wrapped = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, system-ui, sans-serif;
            background: #0a0a0f;
            color: #d4d4dc;
            padding: 16px;
            font-size: 17px;
            line-height: 1.7;
            -webkit-text-size-adjust: 100%;
        }
        h2 { font-size: 1.4rem; font-weight: 600; margin: 2rem 0 0.75rem; color: #f5f5f7; }
        h3 { font-size: 1.15rem; font-weight: 600; margin: 1.5rem 0 0.5rem; color: #f5f5f7; }
        p { margin-bottom: 1rem; }
        ul, ol { margin-bottom: 1rem; padding-left: 1.25rem; }
        li { margin-bottom: 0.4rem; }
        code {
            font-family: 'SF Mono', Menlo, monospace;
            font-size: 0.85em;
            background: rgba(255,255,255,0.06);
            padding: 2px 6px;
            border-radius: 4px;
            color: #c084fc;
        }
        pre {
            background: #161622;
            border: 1px solid #27272a;
            border-radius: 8px;
            padding: 16px;
            overflow-x: auto;
            margin: 1.25rem 0;
        }
        pre code { background: none; padding: 0; color: #d4d4dc; font-size: 0.85rem; }
        a { color: #c084fc; text-decoration: underline; }
        strong { color: #f5f5f7; font-weight: 600; }
        blockquote {
            border-left: 3px solid #a855f7;
            padding-left: 16px;
            margin: 1.25rem 0;
            color: #a1a1aa;
            font-style: italic;
        }
        table { width: 100%; border-collapse: collapse; margin: 1.25rem 0; font-size: 0.9rem; }
        th { text-align: left; padding: 8px 12px; font-weight: 600; color: #f5f5f7; background: rgba(255,255,255,0.03); border-bottom: 2px solid #27272a; }
        td { padding: 8px 12px; border-bottom: 1px solid #27272a; color: #a1a1aa; }
        img { max-width: 100%; height: auto; border-radius: 8px; }

        .lo-vis { background: #161622; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1.25rem 0; }
        .lo-step { padding: 10px 14px; border-radius: 8px; margin: 6px 0; }
        .lo-step--green { background: rgba(52,211,153,0.08); border-left: 3px solid #34d399; }
        .lo-step--purple { background: rgba(168,85,247,0.08); border-left: 3px solid #a855f7; }
        .lo-step--orange { background: rgba(251,146,60,0.08); border-left: 3px solid #fb923c; }
        .learn-card { background: #1a1a24; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1rem 0; }
        .learn-card h3 { font-size: 1rem; margin: 0 0 8px; }

        /* Quiz styles */
        .quiz-block { background: #1a1a24; border: 1px solid #27272a; border-radius: 16px; padding: 20px; margin: 1.25rem 0; }
        .quiz-title { font-size: 1.1rem; font-weight: 600; color: #f5f5f7; margin-bottom: 16px; }
        .quiz-question { margin-bottom: 20px; padding-bottom: 20px; border-bottom: 1px solid #27272a; }
        .quiz-question:last-of-type { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
        .quiz-q { font-size: 1rem; font-weight: 500; color: #f5f5f7; margin-bottom: 12px; line-height: 1.5; display: flex; gap: 10px; }
        .quiz-num { display: inline-flex; align-items: center; justify-content: center; min-width: 28px; height: 28px; background: rgba(168,85,247,0.1); color: #c084fc; border-radius: 8px; font-size: 0.8rem; font-weight: 700; flex-shrink: 0; }
        .quiz-options { display: flex; flex-direction: column; gap: 8px; }
        .quiz-option { display: flex; align-items: center; gap: 12px; width: 100%; padding: 12px 16px; background: #0a0a0f; border: 1px solid #27272a; border-radius: 10px; color: #d4d4dc; font-size: 0.9rem; font-family: inherit; text-align: left; cursor: pointer; min-height: 48px; line-height: 1.4; -webkit-appearance: none; }
        .quiz-letter { display: inline-flex; align-items: center; justify-content: center; min-width: 28px; height: 28px; background: rgba(255,255,255,0.05); border-radius: 8px; font-size: 0.8rem; font-weight: 600; color: #71717a; flex-shrink: 0; }
        .quiz-option.quiz-correct { border-color: #34d399; background: rgba(52,211,153,0.08); }
        .quiz-option.quiz-correct .quiz-letter { background: rgba(52,211,153,0.2); color: #34d399; }
        .quiz-option.quiz-wrong { border-color: #f87171; background: rgba(248,113,113,0.08); }
        .quiz-option.quiz-wrong .quiz-letter { background: rgba(248,113,113,0.2); color: #f87171; }
        .quiz-options.revealed .quiz-option:not(.quiz-correct):not(.quiz-wrong) { opacity: 0.4; }
        .quiz-options.revealed .quiz-option { pointer-events: none; }
        .quiz-explanation { margin-top: 12px; padding: 12px 14px; background: rgba(52,211,153,0.04); border-left: 3px solid #34d399; border-radius: 0 8px 8px 0; font-size: 0.85rem; line-height: 1.5; color: #a1a1aa; }
        .quiz-explanation strong { color: #34d399; }

        /* Sequential quiz mode */
        .quiz-block.quiz-sequential .quiz-question { display: none; }
        .quiz-block.quiz-sequential .quiz-question.quiz-active { display: block; }
        .quiz-unified { margin-top: 32px; border-radius: 16px; padding: 24px; }
        .quiz-progress { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #27272a; }
        .quiz-progress-text { font-size: 0.8rem; color: #71717a; }
        .quiz-progress-dots { display: flex; gap: 6px; }
        .quiz-dot { width: 8px; height: 8px; border-radius: 50%; background: rgba(255,255,255,0.08); transition: background 0.3s; }
        .quiz-dot.dot-correct { background: #34d399; }
        .quiz-dot.dot-wrong { background: #f87171; }
        .quiz-dot.dot-current { background: #c084fc; }
        .quiz-next-btn { display: none; width: 100%; padding: 14px; margin-top: 16px; background: rgba(168,85,247,0.12); border: 1px solid rgba(168,85,247,0.25); border-radius: 12px; color: #c084fc; font-size: 0.95rem; font-weight: 600; font-family: inherit; cursor: pointer; min-height: 48px; -webkit-appearance: none; }
        .quiz-next-btn.visible { display: block; }
        .quiz-complete-msg { text-align: center; padding: 24px 16px; color: #a1a1aa; font-size: 0.95rem; border-radius: 16px; }
        .quiz-complete-msg.quiz-passed { background: rgba(52,211,153,0.06); border: 1px solid rgba(52,211,153,0.2); }
        .quiz-complete-msg.quiz-failed { background: rgba(248,113,113,0.04); border: 1px solid rgba(248,113,113,0.15); }
        .quiz-complete-msg strong { color: #34d399; }
        .quiz-failed strong { color: #f87171; }
        .quiz-pass-label { margin-top: 8px; font-size: 0.8rem; font-weight: 600; color: #34d399; text-transform: uppercase; letter-spacing: 0.06em; }
        .quiz-fail-label { margin-top: 8px; font-size: 0.8rem; color: #71717a; }
        .quiz-score { display: flex; align-items: center; gap: 8px; font-size: 0.8rem; color: #71717a; margin-bottom: 16px; }
        .quiz-score-correct { color: #34d399; font-weight: 600; }
        .quiz-score-wrong { color: #f87171; font-weight: 600; }
        .quiz-score-bar { flex: 1; height: 4px; background: rgba(255,255,255,0.06); border-radius: 2px; overflow: hidden; }
        .quiz-score-fill { height: 100%; background: #34d399; border-radius: 2px; transition: width 0.3s; }

        /* Flashcard styles */
        .flash-block { background: #1a1a24; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1.25rem 0; }
        .flash-card { margin-bottom: 6px; background: #0a0a0f; border: 1px solid #27272a; border-radius: 10px; overflow: hidden; }
        .flash-front { padding: 14px 16px; font-size: 0.95rem; font-weight: 600; color: #f5f5f7; cursor: pointer; list-style: none; display: flex; align-items: center; justify-content: space-between; min-height: 48px; }
        .flash-back { padding: 14px 16px; font-size: 0.9rem; color: #a1a1aa; border-top: 1px solid #27272a; line-height: 1.5; }
        </style>
        </head>
        <body>
        \(html)
        <script>
        // Unified Quiz Engine for iOS
        (function() {
            var blocks = document.querySelectorAll('.quiz-block');
            if (blocks.length === 0) return;
            var allQuestions = [];
            blocks.forEach(function(block) {
                block.querySelectorAll('.quiz-question').forEach(function(q) { allQuestions.push(q); });
            });
            if (allQuestions.length === 0) return;
            blocks.forEach(function(block) { block.style.display = 'none'; });
            var unified = document.createElement('div');
            unified.className = 'quiz-block quiz-sequential quiz-unified';
            unified.innerHTML = '<h3 class="quiz-title">Test Your Knowledge</h3>';
            allQuestions.forEach(function(q) { unified.appendChild(q); });
            allQuestions.forEach(function(q, i) { var num = q.querySelector('.quiz-num'); if (num) num.textContent = i + 1; });
            document.body.appendChild(unified);

            var currentIdx = 0, correct = 0, wrong = 0, answered = {};
            var progressEl = document.createElement('div');
            progressEl.className = 'quiz-progress';
            var dotsHtml = '';
            for (var d = 0; d < allQuestions.length; d++) {
                dotsHtml += '<div class="quiz-dot' + (d === 0 ? ' dot-current' : '') + '"></div>';
            }
            progressEl.innerHTML = '<span class="quiz-progress-text">Question 1 of ' + allQuestions.length + '</span><div class="quiz-progress-dots">' + dotsHtml + '</div>';
            unified.querySelector('.quiz-title').after(progressEl);
            var dots = progressEl.querySelectorAll('.quiz-dot');
            var progText = progressEl.querySelector('.quiz-progress-text');

            var scoreEl = document.createElement('div');
            scoreEl.className = 'quiz-score';
            scoreEl.innerHTML = '<span class="quiz-score-label">Score</span><span class="quiz-score-correct">0</span><span class="quiz-score-divider">/</span><span class="quiz-score-wrong">0</span><span class="quiz-score-total">of ' + allQuestions.length + '</span><div class="quiz-score-bar"><div class="quiz-score-fill"></div></div>';
            progressEl.after(scoreEl);

            var nextBtn = document.createElement('button');
            nextBtn.className = 'quiz-next-btn';
            nextBtn.textContent = 'Next Question \\u2192';

            function showQuestion(idx) {
                allQuestions.forEach(function(q) { q.classList.remove('quiz-active'); });
                if (idx < allQuestions.length) {
                    allQuestions[idx].classList.add('quiz-active');
                    progText.textContent = 'Question ' + (idx + 1) + ' of ' + allQuestions.length;
                    dots.forEach(function(dot, i) { dot.classList.toggle('dot-current', i === idx); });
                    nextBtn.classList.remove('visible');
                    allQuestions[idx].appendChild(nextBtn);
                } else {
                    var pct = Math.round((correct / allQuestions.length) * 100);
                    var passed = pct >= 80;
                    var msg = document.createElement('div');
                    msg.className = 'quiz-complete-msg' + (passed ? ' quiz-passed' : ' quiz-failed');
                    if (passed) {
                        try { window.webkit.messageHandlers.quizComplete.postMessage({passed: true, score: pct}); } catch(e) {}
                        msg.innerHTML = (wrong === 0 ? '<strong>Perfect score!</strong> ' : '<strong>' + correct + ' of ' + allQuestions.length + '</strong> correct ') + '(' + pct + '%)<div class="quiz-pass-label">Lesson Complete</div>';
                    } else {
                        msg.innerHTML = '<strong>' + correct + ' of ' + allQuestions.length + '</strong> correct (' + pct + '%)<div class="quiz-fail-label">Score 80% or higher to complete this lesson</div>';
                    }
                    var retryBtn = document.createElement('button');
                    retryBtn.className = 'quiz-next-btn visible';
                    retryBtn.textContent = passed ? 'Review Again' : 'Try Again';
                    retryBtn.style.marginTop = '12px';
                    retryBtn.addEventListener('click', function() {
                        correct = 0; wrong = 0; currentIdx = 0; answered = {};
                        scoreEl.querySelector('.quiz-score-correct').textContent = '0';
                        scoreEl.querySelector('.quiz-score-wrong').textContent = '0';
                        scoreEl.querySelector('.quiz-score-fill').style.width = '0%';
                        dots.forEach(function(dot) { dot.className = 'quiz-dot'; });
                        allQuestions.forEach(function(q) {
                            q.querySelectorAll('.quiz-option').forEach(function(opt) { opt.classList.remove('quiz-correct', 'quiz-wrong'); opt.style.pointerEvents = ''; });
                            q.querySelectorAll('.quiz-options').forEach(function(opts) { opts.classList.remove('revealed'); });
                            q.querySelectorAll('.quiz-explanation').forEach(function(exp) { exp.style.display = 'none'; });
                        });
                        if (msg.parentNode) msg.remove();
                        if (retryBtn.parentNode) retryBtn.remove();
                        showQuestion(0);
                    });
                    unified.appendChild(msg);
                    unified.appendChild(retryBtn);
                    progText.textContent = 'Complete';
                }
            }
            showQuestion(0);
            nextBtn.addEventListener('click', function() { currentIdx++; showQuestion(currentIdx); });
            unified.addEventListener('click', function(ev) {
                var btn = ev.target.closest('.quiz-option');
                if (!btn || answered[currentIdx]) return;
                answered[currentIdx] = true;
                var isCorrect = btn.classList.contains('quiz-correct');
                if (isCorrect) { correct++; dots[currentIdx].classList.remove('dot-current'); dots[currentIdx].classList.add('dot-correct'); }
                else { wrong++; dots[currentIdx].classList.remove('dot-current'); dots[currentIdx].classList.add('dot-wrong'); }
                scoreEl.querySelector('.quiz-score-correct').textContent = correct;
                scoreEl.querySelector('.quiz-score-wrong').textContent = wrong;
                scoreEl.querySelector('.quiz-score-fill').style.width = Math.round((correct / allQuestions.length) * 100) + '%';
                nextBtn.textContent = currentIdx < allQuestions.length - 1 ? 'Next Question \\u2192' : 'See Results';
                nextBtn.classList.add('visible');
            });
        })();
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(wrapped, baseURL: nil)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onQuizPassed: (() -> Void)?

        init(onQuizPassed: (() -> Void)?) {
            self.onQuizPassed = onQuizPassed
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "quizComplete",
               let body = message.body as? [String: Any],
               body["passed"] as? Bool == true {
                DispatchQueue.main.async { [weak self] in
                    self?.onQuizPassed?()
                }
            }
        }
    }
}
