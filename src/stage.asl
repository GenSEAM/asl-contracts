(module asl-contracts/stage
  :d "AgentScript Pipeline Stage Contract Specification for deterministic multi-agent execution."
  :x [PipelineStage StageStatus StageContract
      make-stage-contract stage-transition stage-set-output stage-set-error
      is-stage-terminal? is-stage-successful? validate-stage-contract]
  :i [])

(dfe PipelineStage
  (:c stage-script [] "Script generation and topic breakdown stage")
  (:c stage-audio [] "Voiceover synthesis and audio alignment stage")
  (:c stage-visuals [] "Asset sourcing, image generation and captioning stage")
  (:c stage-render [] "Video composition and rendering stage")
  (:c stage-publish [] "Distribution and publishing stage"))

(dfe StageStatus
  (:c status-pending [] "Stage is queued awaiting preconditions")
  (:c status-running [] "Stage is currently executing")
  (:c status-completed [] "Stage completed successfully")
  (:c status-failed [] "Stage execution failed with an error"))

(dfs StageContract
  (:f id Str "Unique execution identifier")
  (:f stage PipelineStage "Pipeline stage type")
  (:f status StageStatus "Current lifecycle status")
  (:f inputs (Map Str Str) "Input parameters and artifacts")
  (:f outputs (Map Str Str) "Produced artifacts and metrics")
  (:f error-msg Str "Error message if stage failed"))

(df make-stage-contract [(id Str) (stage PipelineStage)] -> StageContract
  :d "Constructs an initial stage contract in pending status with empty inputs and outputs."
  (StageContract
    :id id
    :stage stage
    :status (status-pending)
    :inputs (map-empty)
    :outputs (map-empty)
    :error-msg ""))

(df stage-transition [(contract StageContract) (new-status StageStatus)] -> StageContract
  :d "Transitions a stage contract into a new lifecycle status."
  (StageContract
    :id (.-id contract)
    :stage (.-stage contract)
    :status new-status
    :inputs (.-inputs contract)
    :outputs (.-outputs contract)
    :error-msg (.-error-msg contract)))

(df stage-set-output [(contract StageContract) (key Str) (val Str)] -> StageContract
  :d "Sets an output key-value pair on the stage contract."
  (StageContract
    :id (.-id contract)
    :stage (.-stage contract)
    :status (.-status contract)
    :inputs (.-inputs contract)
    :outputs (map-set (.-outputs contract) key val)
    :error-msg (.-error-msg contract)))

(df stage-set-error [(contract StageContract) (err Str)] -> StageContract
  :d "Marks a stage contract as failed with a specified error message."
  (StageContract
    :id (.-id contract)
    :stage (.-stage contract)
    :status (status-failed)
    :inputs (.-inputs contract)
    :outputs (.-outputs contract)
    :error-msg err))

(df is-stage-terminal? [(status StageStatus)] -> Bool
  :d "Returns true if the stage status represents a terminal state (completed or failed)."
  (mt status
    ((status-completed) true)
    ((status-failed) true)
    ((status-pending) false)
    ((status-running) false)))

(df is-stage-successful? [(contract StageContract)] -> Bool
  :d "Returns true if the stage completed cleanly without error."
  (mt (.-status contract)
    ((status-completed) (string-empty? (.-error-msg contract)))
    ((status-pending) false)
    ((status-running) false)
    ((status-failed) false)))

(df validate-stage-contract [(contract StageContract)] -> Bool
  :d "Validates structural integrity and invariant compliance of a stage contract."
  (and (not (string-empty? (.-id contract)))
       (mt (.-status contract)
         ((status-failed) (not (string-empty? (.-error-msg contract))))
         ((status-completed) (string-empty? (.-error-msg contract)))
         ((status-pending) true)
         ((status-running) true))))
