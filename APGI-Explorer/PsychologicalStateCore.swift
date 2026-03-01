public struct PsychologicalState: Identifiable, Codable {
    public let id: Int
    let name: String
    let description: String
    let parameters: APGIParameters
    let metadata: StateMetadata

    struct APGIParameters: Codable {
        let predictionError: PredictionErrorSpec
        let precision: PrecisionProfile
        let threshold: ThresholdRange
        let somaticBias: BiasRange
    }

    struct PredictionErrorSpec: Codable {
        let accuracy: ParameterRange
        let context: ErrorContext
        let description: String

        enum ErrorContext: String, Codable, CaseIterable {
            case taskAligned = "task-aligned"
            case social
            case threat
            case novelty
            case homeostatic
            case benignViolation = "benign violation"
            case counterfactual
            case temporal
            case `internal`
            case external

            var description: String {
                self.rawValue
            }
        }

        var formattedAccuracy: String {
            "\(self.accuracy.formattedRange) \(self.context.description)"
        }
    }

    struct StateMetadata: Codable {
        let duration: DurationRange
        let metabolicCost: MetabolicCost
        let neurologicalBasis: [String]
        let adaptiveValue: AdaptiveValue

        enum DurationRange: String, Codable, CaseIterable {
            case momentary = "momentary (<1s)"
            case brief = "brief (1-10s)"
            case short = "short (10s-1min)"
            case medium = "medium (1-10min)"
            case extended = "extended (10min-1hr)"
            case sustained = "sustained (>1hr)"
            case tonic = "tonic (ongoing)"

            var description: String {
                self.rawValue
            }
        }

        enum MetabolicCost: String, Codable, CaseIterable {
            case minimal
            case low
            case moderate
            case high
            case extreme
            case protective

            var description: String {
                self.rawValue
            }
        }

        enum AdaptiveValue: String, Codable, CaseIterable {
            case highlyAdaptive = "highly adaptive"
            case adaptive
            case contextDependent = "context-dependent"
            case maladaptive
            case protective
            case neutral
            case homeostatic

            var description: String {
                self.rawValue
            }
        }
    }
}
