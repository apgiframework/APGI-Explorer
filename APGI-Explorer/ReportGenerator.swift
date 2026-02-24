import Foundation

struct ReportSnapshot {
    let name: String
    let date: Date
    let profileType: APGIProfileType
    let apgiProfile: APGIProfile
}

class ReportGenerator {
    static func generateInteractiveHTMLReport(
        for profile: QuizProfile,
        apgiProfile: APGIProfile,
        profileType: APGIProfileType,
        history: [ReportSnapshot]
    ) -> String {
        let timelineEntries = (history + [ReportSnapshot(
            name: profile.name,
            date: profile.dateCreated,
            profileType: profileType,
            apgiProfile: apgiProfile
        )])
        let sortedTimeline = timelineEntries
            .sorted(by: { $0.date < $1.date })

        let parameterData: [(label: String, value: Double, descriptor: String)] = [
            ("ε (Epsilon)", apgiProfile.epsilon, apgiProfile.epsilonCategory.rawValue),
            ("π (Precision)", apgiProfile.precision, apgiProfile.precisionCategory.rawValue),
            ("θₜ (Threshold)", apgiProfile.threshold, apgiProfile.thresholdCategory.rawValue),
            ("β (Somatic Bias)", apgiProfile.somaticBias, apgiProfile.somaticCategory.rawValue),
        ]

        let parameterBlocks = parameterData.map { self.parameterBar(label: $0.label, value: $0.value, descriptor: $0.descriptor) }

        let strengthsHTML = profileType.strengths.map { "<li>\(self.escape($0))</li>" }.joined()
        let challengesHTML = profileType.challenges.map { "<li>\(self.escape($0))</li>" }.joined()
        let strategiesHTML = profileType.strategies.map { "<li>\(self.escape($0))</li>" }.joined()

        let statesHTML = profileType.likelyStates.map {
            """
            <div class="state-card">
                <div class="state-name">#\($0.stateId) — \($0.likelihood.rawValue)</div>
                <p>\(self.escape($0.reason))</p>
            </div>
            """
        }.joined()

        let normsHTML = parameterData.map { item -> String in
            let delta = Int(item.value - 50)
            let direction = delta > 0 ? "above" : delta < 0 ? "below" : "on par with"
            let displayDelta = delta == 0 ? "on par with" : "\(abs(delta)) pts \(direction) the normative anchor (50)"
            return """
            <li>
                <span class="norm-label">\(self.escape(item.label))</span>
                <span class="norm-value">\(String(format: "%.0f", item.value))</span>
                <span class="norm-detail">\(displayDelta)</span>
            </li>
            """
        }.joined()

        let historyHTML: String = if sortedTimeline.isEmpty {
            "<p class=\"hint\">No saved snapshots yet. Your current profile will populate once you store it.</p>"
        } else {
            sortedTimeline.map { entry in
                let summary = """
                ε: \(Int(entry.apgiProfile.epsilon)), π: \(Int(entry.apgiProfile.precision)), θₜ: \(Int(entry.apgiProfile.threshold)), β: \(Int(entry.apgiProfile.somaticBias))
                """
                return """
                <div class="history-card">
                    <div class="history-header">
                        <strong>\(self.escape(entry.name))</strong>
                        <span>\(self.formattedDate(entry.date))</span>
                    </div>
                    <div class="history-meta">
                        <span>\(self.escape(entry.profileType.rawValue))</span>
                        <span>\(summary)</span>
                    </div>
                </div>
                """
            }.joined()
        }

        let resourcesHTML = self.resourceRecommendations.map {
            """
            <li>
                <strong>\(self.escape($0.title))</strong>
                <p>\(self.escape($0.subtitle))</p>
            </li>
            """
        }.joined()

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <title>\(self.escape("APGI Profile — \(profile.name)"))</title>
            <style>
                :root {
                    color-scheme: light;
                    font-family: "Inter", "SF Pro Display", system-ui, sans-serif;
                    background-color: #f2f4f8;
                    color: #0f172a;
                }

                * {
                    box-sizing: border-box;
                }

                body {
                    margin: 0;
                    padding: 0;
                    background: radial-gradient(circle at top right, #e0e7ff 0%, transparent 45%),
                                #f2f4f8;
                }

                .page {
                    max-width: 1000px;
                    margin: 0 auto;
                    padding: 32px 24px 64px;
                }

                header.hero {
                    background: linear-gradient(135deg, #1d4ed8, #2563eb);
                    padding: 32px;
                    border-radius: 22px;
                    color: white;
                    box-shadow: 0 20px 40px rgba(15, 23, 42, 0.35);
                    margin-bottom: 24px;
                }

                header.hero h1 {
                    margin: 0;
                    font-size: 2.2rem;
                }

                header.hero p {
                    margin-top: 12px;
                    opacity: 0.9;
                    max-width: 600px;
                    line-height: 1.5;
                }

                .section-card {
                    background: white;
                    border-radius: 20px;
                    padding: 24px;
                    margin-bottom: 20px;
                    box-shadow: 0 15px 35px rgba(15, 23, 42, 0.08);
                }

                .section-card h2 {
                    margin-top: 0;
                    margin-bottom: 16px;
                    font-size: 1.3rem;
                    color: #0f172a;
                }

                .parameter-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 16px;
                }

                .parameter-block {
                    border: 1px solid #e5e7eb;
                    border-radius: 18px;
                    padding: 16px;
                    background: #f8fafc;
                }

                .parameter-block .value {
                    font-size: 1.8rem;
                    font-weight: 600;
                }

                .parameter-block .descriptor {
                    font-size: 0.9rem;
                    color: #475569;
                }

                .bar-track {
                    width: 100%;
                    height: 8px;
                    background: #e5e7eb;
                    border-radius: 999px;
                    margin-top: 12px;
                    overflow: hidden;
                }

                .bar-fill {
                    height: 100%;
                    border-radius: 999px;
                    transition: width 0.6s ease;
                    background: linear-gradient(135deg, #2563eb, #4f46e5);
                }

                .two-columns {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
                    gap: 16px;
                }

                .two-columns ul {
                    margin: 0;
                    padding-left: 20px;
                    color: #0f172a;
                    line-height: 1.6;
                }

                .state-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
                    gap: 14px;
                }

                .state-card {
                    padding: 16px;
                    border-radius: 16px;
                    border: 1px solid #e4e7ec;
                    background: linear-gradient(135deg, #f8fafc, #eef2ff);
                    min-height: 120px;
                }

                .state-card p {
                    margin: 8px 0 0;
                    color: #475569;
                }

                .state-name {
                    font-weight: 600;
                    color: #111827;
                }

                .norm-list {
                    list-style: none;
                    margin: 0;
                    padding: 0;
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
                    gap: 16px;
                }

                .norm-list li {
                    border-radius: 16px;
                    padding: 16px;
                    border: 1px solid #e5e7eb;
                    background: #fefefe;
                }

                .history-card {
                    border-radius: 16px;
                    padding: 16px;
                    border: 1px solid #e5e7eb;
                    background: #fff;
                    margin-bottom: 12px;
                }

                .history-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: baseline;
                    font-size: 0.95rem;
                }

                .history-meta {
                    margin-top: 8px;
                    display: flex;
                    flex-direction: column;
                    gap: 4px;
                    font-size: 0.9rem;
                    color: #475569;
                }

                .history-meta span:first-child {
                    font-weight: 600;
                    color: #0f172a;
                }

                .resources-list {
                    list-style: none;
                    margin: 0;
                    padding: 0;
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                    gap: 16px;
                }

                .resources-list li {
                    border-radius: 16px;
                    padding: 16px;
                    border: 1px solid #cbd5f5;
                    background: #f8fafc;
                }

                .resources-list strong {
                    display: block;
                    margin-bottom: 6px;
                }

                .hint {
                    color: #475569;
                    font-size: 0.95rem;
                }

                @media (max-width: 600px) {
                    .section-card {
                        padding: 18px;
                    }

                    header.hero {
                        padding: 24px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="page">
                <header class="hero">
                    <h1>\(self.escape(profile.name))</h1>
                    <p>\(self.escape(profileType.description))</p>
                    <p><strong>\(self.escape(profileType.rawValue))</strong> · Generated on \(self.formattedDate(Date()))</p>
                </header>

                <section class="section-card">
                    <h2>Parameter Breakdown</h2>
                    <div class="parameter-grid">
                        \(parameterBlocks.joined())
                    </div>
                </section>

                <section class="section-card">
                    <h2>Profile Narrative</h2>
                    <div class="two-columns">
                        <div>
                            <h3>Strengths</h3>
                            <ul>\(strengthsHTML)</ul>
                        </div>
                        <div>
                            <h3>Challenges</h3>
                            <ul>\(challengesHTML)</ul>
                        </div>
                    </div>
                </section>

                <section class="section-card">
                    <h2>Personalized Strategies</h2>
                    <ul>\(strategiesHTML)</ul>
                </section>

                <section class="section-card">
                    <h2>Likely States in Action</h2>
                    <div class="state-grid">
                        \(statesHTML)
                    </div>
                </section>

                <section class="section-card">
                    <h2>Comparison to Norms</h2>
                    <ul class="norm-list">
                        \(normsHTML)
                    </ul>
                </section>

                <section class="section-card">
                    <h2>Trajectory</h2>
                    \(historyHTML)
                </section>

                <section class="section-card">
                    <h2>Scientific Background</h2>
                    <p>\(self.escape(profileType.scientificBackground))</p>
                </section>

                <section class="section-card">
                    <h2>Resources</h2>
                    <ul class="resources-list">
                        \(resourcesHTML)
                    </ul>
                </section>
            </div>
        </body>
        </html>
        """
    }

    private static func parameterBar(label: String, value: Double, descriptor: String) -> String {
        let clamped = max(0, min(100, value))
        return """
        <div class="parameter-block">
            <div class="label">\("\(self.escape(label))")</div>
            <div class="value">\(String(format: "%.0f", clamped))</div>
            <div class="descriptor">\(self.escape(descriptor))</div>
            <div class="bar-track">
                <div class="bar-fill" style="width:\(clamped)%"></div>
            </div>
        </div>
        """
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func escape(_ string: String) -> String {
        var sanitized = string
        let replacements: [String: String] = [
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            "\"": "&quot;",
            "'": "&#39;",
        ]
        replacements.forEach { sanitized = sanitized.replacingOccurrences(of: $0.key, with: $0.value) }
        return sanitized
    }

    private static let resourceRecommendations: [(title: String, subtitle: String)] = [
        (
            "APGI Primer",
            "Review the science behind ε, π, θₜ and β so you can reference the report confidently."
        ),
        (
            "State Explorer Toolkit",
            "Use curated state-maps to anticipate transitions and design micro-interventions."
        ),
        (
            "Embodied Strategy Cards",
            "Take the personalized strategies and embed them into rituals, bookmarks or reminders."
        ),
    ]
}

private extension APGIProfileType {
    var scientificBackground: String {
        switch self {
        case .sensitiveIntegrator:
            "Sensitive Integrators combine heightened ε and β with a lower θₜ so that subtle prediction errors are felt and acted upon immediately."
        case .analyticalGuard:
            "Analytical Guards blend low ε with high π and θₜ, preserving tight models that resist noise while defending against uncertainty."
        case .adaptiveBalancer:
            "Adaptive Balancers smoothly allocate ε, π, θₜ and β, shifting between exploration and grounded focus."
        case .openExplorer:
            "Open Explorers keep ε high and θₜ loose, allowing novelty to enter freely while curiosity sustains ongoing shifts."
        case .contemplativeAnchor:
            "Contemplative Anchors stabilize with lower ε and elevated π/θₜ, supporting calm reflection even when surprises arise."
        case .somaticNavigator:
            "Somatic Navigators keep the body central—high β and steady π help translate interoception into adaptive decisions."
        case .cognitiveArchitect:
            "Cognitive Architects pair high π and θₜ with moderate ε so that models remain precise and protected from distraction."
        case .dynamicResponder:
            "Dynamic Responders flex ε, β and θₜ so that emotional salience can trigger rapid, yet calibrated, mobilization."
        }
    }
}
