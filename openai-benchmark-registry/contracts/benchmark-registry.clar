;; OpenAI Benchmark Registry
;; Decentralized leaderboard for AI model performance tracking

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-already-exists (err u302))
(define-constant err-invalid-score (err u303))
(define-constant err-unauthorized (err u304))

;; Data Variables
(define-data-var benchmark-count uint u0)
(define-data-var submission-count uint u0)
(define-data-var comment-count uint u0)
(define-data-var category-count uint u0)
(define-data-var platform-fee uint u100) ;; 1% fee in basis points
(define-data-var contract-paused bool false)

;; Data Maps
(define-map benchmarks uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    max-score: uint,
    created-by: principal,
    created-at: uint
  }
)

(define-map submissions uint
  {
    benchmark-id: uint,
    model-name: (string-ascii 50),
    submitter: principal,
    score: uint,
    result-hash: (buff 32),
    verified: bool,
    submitted-at: uint
  }
)

(define-map model-verifiers principal bool)

(define-map benchmark-categories uint
  {
    category-name: (string-ascii 50),
    description: (string-ascii 150)
  }
)

(define-map benchmark-to-category uint uint)

(define-map submitter-reputation principal
  {
    total-submissions: uint,
    verified-submissions: uint,
    total-score: uint,
    reputation-points: uint
  }
)

(define-map submission-comments uint
  {
    submission-id: uint,
    commenter: principal,
    comment: (string-ascii 500),
    commented-at: uint
  }
)

;; Read-only functions
(define-read-only (get-benchmark (benchmark-id uint))
  (map-get? benchmarks benchmark-id)
)

(define-read-only (get-submission (submission-id uint))
  (map-get? submissions submission-id)
)

(define-read-only (is-verifier (address principal))
  (default-to false (map-get? model-verifiers address))
)

(define-read-only (get-benchmark-count)
  (ok (var-get benchmark-count))
)

(define-read-only (get-submission-count)
  (ok (var-get submission-count))
)

(define-read-only (get-category (category-id uint))
  (map-get? benchmark-categories category-id)
)

(define-read-only (get-benchmark-category (benchmark-id uint))
  (map-get? benchmark-to-category benchmark-id)
)

(define-read-only (get-submitter-reputation (submitter principal))
  (default-to 
    { total-submissions: u0, verified-submissions: u0, total-score: u0, reputation-points: u0 }
    (map-get? submitter-reputation submitter)
  )
)

(define-read-only (get-comment (comment-id uint))
  (map-get? submission-comments comment-id)
)

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee))
)

(define-read-only (calculate-reputation-score (total-submissions uint) (verified-submissions uint) (total-score uint))
  (ok (+ (* verified-submissions u10) (/ total-score u100)))
)

(define-read-only (get-top-score-for-benchmark (benchmark-id uint))
  ;; This would need to iterate through submissions in practice
  ;; For now, returns a placeholder structure
  (ok { highest-score: u0, model-name: "", submitter: contract-owner })
)

(define-read-only (is-paused)
  (ok (var-get contract-paused))
)

;; Helper function to check if contract is active
(define-private (check-contract-active)
  (not (var-get contract-paused))
)