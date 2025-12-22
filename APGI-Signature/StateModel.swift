import Foundation
import Combine

class StateModel: ObservableObject {
    @Published var states: [PsychologicalState] = [
        PsychologicalState(
            id: 1,
            name: "Flow state",
            description: "Temporal entrainment, metacognitive suppression",
            predictionError: "Highly accurate (>95%), task-aligned predictions",
            precision: "Task: +4σ; Distractor: <0.5σ",
            threshold: "-10 to -15% (stable, <5% variance)",
            somaticBias: "0.9-1.1 (balanced)"
        ),
        PsychologicalState(
            id: 2,
            name: "Joy/Happiness",
            description: "Ventral striatal activation, sustained positive RPE",
            predictionError: "Predictions meet/exceed expectations by >20%",
            precision: "Positive outcomes: +2 to +3σ",
            threshold: "-15 to -20%",
            somaticBias: "1.0-1.3 (mild somatic amplification)"
        ),
        PsychologicalState(
            id: 3,
            name: "Gratitude",
            description: "Oxytocin-mediated, requires temporal extension",
            predictionError: "Social predictions resolved favorably",
            precision: "Social/attachment: +2 to +4σ; Safety interoception elevated",
            threshold: "-10 to -15%",
            somaticBias: "1.2-1.5 (safety signals amplified)"
        ),
        PsychologicalState(
            id: 4,
            name: "Hope",
            description: "Sustained tonic DA maintaining accessibility",
            predictionError: "Moderate confidence (60-75%), high expected value despite uncertainty",
            precision: "Future-oriented: +2 to +3σ",
            threshold: "-12 to -18% (tonic dopamine)",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 5,
            name: "Optimism",
            description: "Stable positive prior distribution, trait-like",
            predictionError: "Generalized positive priors (>70% positive outcomes)",
            precision: "Positive: +1.5 to +2σ constitutively",
            threshold: "-8 to -12%",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 6,
            name: "Awe",
            description: "DMN suppression, model inadequacy signal",
            predictionError: "Massive prediction error (>4σ) from vastness/novelty",
            precision: "Global: +3 to +5σ transiently (2-10s)",
            threshold: "-20 to -30% (brief suppression)",
            somaticBias: "0.8-1.0 (reduced self-focus)"
        ),
        PsychologicalState(
            id: 7,
            name: "Inspiration",
            description: "DMN-FPN coupling, coherence > strength weighting",
            predictionError: "Latent pattern detection, remote associations",
            precision: "Abstract/pattern: +2 to +4σ",
            threshold: "-10 to -15%",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 8,
            name: "Serenity",
            description: "Dual-threshold architecture, parasympathetic dominant",
            predictionError: "High accuracy (>90%), low-surprise environment",
            precision: "Threat: <0.3σ; External vigilance: +15 to +25%",
            threshold: "-10 to -15%",
            somaticBias: "1.2-1.4 (internal safety signals)"
        ),
        PsychologicalState(
            id: 9,
            name: "Pride",
            description: "Strong embodied component, somatic confirmation",
            predictionError: "Self-model prediction confirmed/exceeded",
            precision: "Self-achievement: +3 to +4σ",
            threshold: "-12 to -18%",
            somaticBias: "1.5-2.0 (postural/somatic expansion)"
        ),
        PsychologicalState(
            id: 10,
            name: "Amusement",
            description: "Rapid ignition (<200ms), mesolimbic reinforcement",
            predictionError: "Benign violation (1-2σ surprise in safe context)",
            precision: "Social incongruity: +2 to +3σ; Threat: <0.5σ",
            threshold: "-15 to -20%",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 11,
            name: "Love (romantic)",
            description: "Extreme metabolic cost, oxytocin/vasopressin mediated",
            predictionError: "Long-term attachment predictions, partner-focus",
            precision: "Attachment-specific: +4 to +6σ; Temporal window +40-60%",
            threshold: "-20 to -30%",
            somaticBias: "1.8-2.5 (visceral states dominate)"
        ),
        PsychologicalState(
            id: 12,
            name: "Curiosity",
            description: "Inverted PE response—uncertainty valued",
            predictionError: "Information gaps actively detected",
            precision: "Uncertainty signals: +2 to +4σ (amplified, not minimized)",
            threshold: "-10 to -18%",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 13,
            name: "Engagement",
            description: "Effortful control maintained, no metacognitive suppression",
            predictionError: "Task-aligned, sustained accuracy",
            precision: "Task: +3 to +4σ; Distractor: <0.8σ",
            threshold: "-10 to -15% (±10-20% variance)",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 14,
            name: "Mindfulness",
            description: "Non-judgmental, dual threshold adjustment",
            predictionError: "Reduced top-down strength (-30-40%), error acceptance",
            precision: "Equalized (Πₑₓₜ ≈ Πᵢₙₜ ±10%)",
            threshold: "Habitual: +20 to +30%; Present-moment: -15 to -20%",
            somaticBias: "1.3-1.6 (heightened interoceptive awareness)"
        ),
        PsychologicalState(
            id: 15,
            name: "Neutrality",
            description: "Homeostatic equilibrium, rare phenomenologically",
            predictionError: "Balanced, accurate priors",
            precision: "All channels: baseline ±0.3σ",
            threshold: "Resting set-point (individual-typical)",
            somaticBias: "1.0 (baseline)"
        ),
        PsychologicalState(
            id: 16,
            name: "Boredom",
            description: "Aversive meta-signal motivates exploration",
            predictionError: "Over-learned, near-zero PE (<0.5σ)",
            precision: "Global suppression: -2 to -3σ (low expected value)",
            threshold: "Elevated: +20 to +35% (resource conservation)",
            somaticBias: "0.8-1.0"
        ),
        PsychologicalState(
            id: 17,
            name: "Daydreaming",
            description: "DMN dominance, spontaneous ignition",
            predictionError: "Endogenously generated predictions dominate",
            precision: "External: <0.4σ; Internal/memory: +2 to +3σ",
            threshold: "Internal: -15 to -25%",
            somaticBias: "0.8-1.0 (reduced external grounding)"
        ),
        PsychologicalState(
            id: 18,
            name: "Distraction",
            description: "Reservoir coherence degraded, rapid switching",
            predictionError: "Fragmented, competing accurate predictions",
            precision: "Multiple competing streams (each +2 to +3σ)",
            threshold: "Crossed repeatedly by different inputs",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 19,
            name: "Fatigue",
            description: "Metabolic constraint protection mechanism",
            predictionError: "Slowed PE accumulation, shortened integration window",
            precision: "Global reduction: -2 to -4σ",
            threshold: "Elevated: +20 to +40% (adenosine/glucose depletion)",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 20,
            name: "Anxiety",
            description: "False alarm generator, self-reinforcing cycle",
            predictionError: "Threat-biased expectations",
            precision: "Threat: +3 to +6σ",
            threshold: "-25 to -40%",
            somaticBias: "1.5-2.5 (interoceptive hypervigilance)"
        ),
        PsychologicalState(
            id: 21,
            name: "Stress",
            description: "NE-mediated saturation, eventual burnout",
            predictionError: "Persistently violated, non-selective arousal",
            precision: "Non-selective global elevation: +2 to +4σ",
            threshold: "Unstable: ±15-25% fluctuation",
            somaticBias: "1.3-1.8 (sympathetic activation)"
        ),
        PsychologicalState(
            id: 22,
            name: "Depression",
            description: "Computational trap, asymmetric filtering",
            predictionError: "Pessimistic, rigid negative priors",
            precision: "Reward: -3 to -5σ; Negative: +2 to +3σ",
            threshold: "Positive: +30 to +50%; Negative: -10 to -20%",
            somaticBias: "0.7-0.9 (reduced embodiment/anhedonia)"
        ),
        PsychologicalState(
            id: 23,
            name: "Anger",
            description: "NE surge, rapid behavioral mobilization",
            predictionError: "Goal obstruction, injustice detection",
            precision: "Injustice/obstruction: +3 to +5σ",
            threshold: "-20 to -35%",
            somaticBias: "1.8-2.5 (muscle tension, CV arousal)"
        ),
        PsychologicalState(
            id: 24,
            name: "Fear",
            description: "Amygdala-driven, extreme urgency configuration",
            predictionError: "Imminent threat, immediate reactive mode",
            precision: "Threat: +4 to +7σ",
            threshold: "-40 to -60%",
            somaticBias: "2.5-4.0 (somatic signals dominate)"
        ),
        PsychologicalState(
            id: 25,
            name: "Guilt",
            description: "Recurrent ignition, self-correction function",
            predictionError: "Self-model violation, moral error replay",
            precision: "Self-monitoring: +3 to +5σ; Internal β elevated",
            threshold: "-20 to -30%",
            somaticBias: "1.8-2.5 (moral wrongness felt)"
        ),
        PsychologicalState(
            id: 26,
            name: "Shame",
            description: "Global ignition, self-devaluation, MPF-TPJ network",
            predictionError: "Social self-model violated, imagined observers",
            precision: "Social-threat: +4 to +6σ (imagined evaluation)",
            threshold: "-25 to -40%",
            somaticBias: "2.0-3.0 (withdrawal posture, blushing)"
        ),
        PsychologicalState(
            id: 27,
            name: "Loneliness",
            description: "Paradoxical rejection sensitivity, self-fulfilling",
            predictionError: "Social predictions unmet, persistent absence",
            precision: "Social-absence: +2 to +4σ",
            threshold: "-15 to -25%",
            somaticBias: "1.2-1.5 (isolation somatic discomfort)"
        ),
        PsychologicalState(
            id: 28,
            name: "Frustration",
            description: "Unstable threshold, escalation/abandonment negotiation",
            predictionError: "Repeated goal-blocking, maintained effort",
            precision: "Goal-relevant: +2 to +4σ (maintained despite failure)",
            threshold: "Oscillating: ±20-30%",
            somaticBias: "1.2-1.6 (arousal building)"
        ),
        PsychologicalState(
            id: 29,
            name: "Confusion",
            description: "Model selection failure, high-entropy state",
            predictionError: "Competing models, ambiguous evidence",
            precision: "Diffused across alternatives (no dominant >3σ)",
            threshold: "Normal, but no signal crosses cleanly",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 30,
            name: "Disgust",
            description: "Anterior insula-driven, visceral dominance",
            predictionError: "Contamination/pathogen detection confirmed",
            precision: "Contamination: +3 to +5σ",
            threshold: "-20 to -30%",
            somaticBias: "2.0-3.0 (nausea, gag reflex)"
        ),
        PsychologicalState(
            id: 31,
            name: "Envy",
            description: "Desire + resentment, self-model threatened",
            predictionError: "Social comparison mismatch, status threat",
            precision: "Social-comparison: +2 to +4σ",
            threshold: "-15 to -25%",
            somaticBias: "1.1-1.4"
        ),
        PsychologicalState(
            id: 32,
            name: "Jealousy",
            description: "Mate-guarding function, hypervigilance for betrayal",
            predictionError: "Attachment security threatened, rival detected",
            precision: "Rival-related: +3 to +5σ",
            threshold: "-20 to -35%",
            somaticBias: "1.5-2.0 (somatic anxiety)"
        ),
        PsychologicalState(
            id: 33,
            name: "Regret",
            description: "Learning signal, recurrent 'what if' ignition",
            predictionError: "Counterfactual error (past ≠ optimal)",
            precision: "Self-blame: +3 to +5σ",
            threshold: "-15 to -25%",
            somaticBias: "1.2-1.5"
        ),
        PsychologicalState(
            id: 34,
            name: "Pessimism",
            description: "Prior distribution bias, anticipatory not current",
            predictionError: "Negative outcome priors (>60%)",
            precision: "Positive PE: -2 to -3σ (suppressed)",
            threshold: "Positive content: +20 to +35% (filtered)",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 35,
            name: "Overwhelm",
            description: "Reservoir saturation, computational collapse",
            predictionError: "Excessive concurrent demands",
            precision: "Multiple high-Π streams (total >10-15 concurrent)",
            threshold: "Chaotically exceeded, fragmented ignition",
            somaticBias: "1.5-2.0 (sympathetic feedback)"
        ),
        PsychologicalState(
            id: 36,
            name: "Dissociation",
            description: "Prefrontal-insula uncoupling, protective detachment",
            predictionError: "Prediction-body coupling severed",
            precision: "Interoceptive: approaches zero",
            threshold: "Embodied content: +40 to +70%",
            somaticBias: "<0.3 (dramatic suppression)"
        ),
        PsychologicalState(
            id: 37,
            name: "Trance",
            description: "Self-sustained ignition, reduced sensory gating",
            predictionError: "Top-down predictions dominate (>3× posterior)",
            precision: "External: <0.3σ; Endogenous rhythmic: elevated",
            threshold: "Endogenous rhythmic: -20 to -35%",
            somaticBias: "0.7-1.0 (internal focus)"
        ),
        PsychologicalState(
            id: 38,
            name: "Hallucination",
            description: "Reality monitoring failure, source confusion",
            predictionError: "Internal predictions misattributed as sensory",
            precision: "Internal erroneously assigned: +3 to +6σ",
            threshold: "Crossed by purely internal signals",
            somaticBias: "Variable (depends on type)"
        ),
        PsychologicalState(
            id: 39,
            name: "Déjà Vu",
            description: "Temporal-binding error, 2-10s duration",
            predictionError: "Temporal misalignment, false familiarity",
            precision: "Momentary match with decaying trace",
            threshold: "Briefly crossed prematurely",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 40,
            name: "Hypnagogia",
            description: "Extended memory window, sleep transition",
            predictionError: "Sensory-decoupled, fragments blend",
            precision: "External declining, internal maintained/elevated",
            threshold: "Dream content: -20 to -40%",
            somaticBias: "0.8-1.2 (variable)"
        ),
        PsychologicalState(
            id: 41,
            name: "Empathy",
            description: "Insula-mediated somatic mapping, shared feeling",
            predictionError: "Other's emotional state simulated in self",
            precision: "Other-emotion: +3 to +5σ",
            threshold: "-20 to -30%",
            somaticBias: "1.5-2.5 (somatic simulation)"
        ),
        PsychologicalState(
            id: 42,
            name: "Sympathy",
            description: "Sustainable care without overwhelm",
            predictionError: "Other's distress recognized, concern generated",
            precision: "Other-distress: +2 to +3σ",
            threshold: "Personal distress: +15 to +25% (protected)",
            somaticBias: "1.0-1.2 (limited somatic mirroring)"
        ),
        PsychologicalState(
            id: 43,
            name: "Belonging",
            description: "Reduced social vigilance, oxytocin-sustained",
            predictionError: "Social inclusion predictions confirmed",
            precision: "Inclusion signals: +2 to +4σ",
            threshold: "-15 to -25%",
            somaticBias: "1.2-1.5 (safety/warmth felt)"
        ),
        PsychologicalState(
            id: 44,
            name: "Rejection",
            description: "dACC activation, pain system overlap",
            predictionError: "Social exclusion, large social PE",
            precision: "Social-threat: +3 to +5σ",
            threshold: "-20 to -35%",
            somaticBias: "1.3-1.7 (social pain)"
        ),
        PsychologicalState(
            id: 45,
            name: "Trust",
            description: "Computational commitment, oxytocin-mediated",
            predictionError: "Positive social priors, vulnerability accepted",
            precision: "Betrayal: -2 to -3σ (reduced vigilance)",
            threshold: "Threat/suspicion: +20 to +30% (filtered)",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 46,
            name: "Focus",
            description: "Tuned filter, LC-NE signal-to-noise optimization",
            predictionError: "Singular, task-aligned",
            precision: "Task: +3 to +5σ; Distractor: <0.5σ",
            threshold: "Task: -10 to -15%; Distractor: +10 to +15%",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 47,
            name: "Creativity",
            description: "Near-critical dynamics, DMN-ECN coupling",
            predictionError: "Loosened constraints, remote associations",
            precision: "Remote/weak associations: +2 to +4σ",
            threshold: "-10 to -20%",
            somaticBias: "0.9-1.1"
        ),
        PsychologicalState(
            id: 48,
            name: "Decision Fatigue",
            description: "Glucose depletion, prefrontal exhaustion",
            predictionError: "Model comparison impaired",
            precision: "Equal across options (dysregulated)",
            threshold: "Elevated: +25 to +40% (resource conservation)",
            somaticBias: "1.0-1.2"
        ),
        PsychologicalState(
            id: 49,
            name: "Cognitive Dissonance",
            description: "ACC conflict signal, aversive instability",
            predictionError: "Incompatible high-precision models",
            precision: "Competing models (each >3σ, mutually inconsistent)",
            threshold: "Unstable: ±20-30% oscillation",
            somaticBias: "1.2-1.6 (discomfort arousal)"
        ),
        PsychologicalState(
            id: 50,
            name: "Hyperfocus",
            description: "Time distortion, complete absorption, post-crash",
            predictionError: "Locked on single target, automatic",
            precision: "Task: +5 to +8σ (extreme); Other: <0.2σ",
            threshold: "Task: -30 to -50%; Other: elevated",
            somaticBias: "0.8-1.0 (metacognition suppressed)"
        ),
        PsychologicalState(
            id: 51,
            name: "Hunger",
            description: "Ghrelin-mediated, attentional hijacking",
            predictionError: "Homeostatic deficit (caloric)",
            precision: "Interoceptive: +2 to +4σ",
            threshold: "Non-food: +15 to +30%; Food: -20%",
            somaticBias: "1.3-1.8 (gastric/metabolic signals)"
        ),
        PsychologicalState(
            id: 52,
            name: "Thirst",
            description: "Angiotensin signaling, cognitive impairment",
            predictionError: "Homeostatic deficit (hydration)",
            precision: "Interoceptive: +2 to +3σ",
            threshold: "Non-water: +15 to +25%; Water: -15 to -20%",
            somaticBias: "1.2-1.5 (osmotic signals)"
        )
    ]
}

struct PsychologicalState: Identifiable {
    let id: Int
    let name: String
    let description: String
    let predictionError: String
    let precision: String
    let threshold: String
    let somaticBias: String
}
