import ConNF.Setup.TypeIndex

/-!
# Paths of type indices

In this file, we define the notion of a *path*, and the derivative and coderivative operations.

## Main declarations

* `ConNF.Path`: A path of type indices.
* `ConNF.Path.recSderiv`, `ConNF.Path.recSderivLe`, `ConNF.Path.recSderivGlobal`:
    Downwards induction principles for paths.
* `ConNF.Path.recScoderiv`: An upwards induction principle for paths.
-/

universe u

open WithBot

namespace ConNF

variable [Params.{u}] {α β γ δ : TypeIndex}

/-- A path of type indices starting at `α` and ending at `β` is a finite sequence of type indices
`α > ... > β`. -/
inductive Path (α : TypeIndex) : TypeIndex → Type u
  | nil : Path α α
  | cons {β γ : TypeIndex} : Path α β → γ < β → Path α γ

@[inherit_doc] infix:70 " ↝ "  => Path

def Path.single {α β : TypeIndex} (h : β < α) : α ↝ β :=
  .cons .nil h

/-- Typeclass for the `↘` notation. -/
class SingleDerivative (X : Type _) (Y : outParam <| Type _)
    (β : outParam TypeIndex) (γ : TypeIndex) where
  sderiv : X → γ < β → Y

/-- Typeclass for the `⇘` notation. -/
class Derivative (X : Type _) (Y : outParam <| Type _)
    (β : outParam TypeIndex) (γ : TypeIndex) extends SingleDerivative X Y β γ where
  deriv : X → β ↝ γ → Y
  sderiv x h := deriv x (.single h)
  deriv_single : ∀ x : X, ∀ h : γ < β, deriv x (.single h) = sderiv x h := by intros; rfl

/-- Typeclass for the `↘.` notation. -/
class BotSingleDerivative (X : Type _) (Y : outParam <| Type _) where
  botSderiv : X → Y

/-- Typeclass for the `⇘.` notation. -/
class BotDerivative (X : Type _) (Y : outParam <| Type _) (β : outParam TypeIndex) where
  botDeriv : X → β ↝ ⊥ → Y

/-- Typeclass for the `↗` notation. -/
class SingleCoderivative (X : Type _) (Y : outParam <| Type _)
    (β : TypeIndex) (γ : outParam TypeIndex) where
  scoderiv : X → γ < β → Y

/-- Typeclass for the `⇗` notation. -/
class Coderivative (X : Type _) (Y : outParam <| Type _)
    (β : TypeIndex) (γ : outParam TypeIndex) extends SingleCoderivative X Y β γ where
  coderiv : X → β ↝ γ → Y
  scoderiv x h := coderiv x (.single h)
  coderiv_single : ∀ x : X, ∀ h : γ < β, coderiv x (.single h) = scoderiv x h := by intros; rfl

infixl:75 " ↘ " => SingleDerivative.sderiv
infixl:75 " ⇘ " => Derivative.deriv
postfix:75 " ↘." => BotSingleDerivative.botDeriv
infixl:75 " ⇘. " => BotDerivative.botDeriv
infixl:75 " ↗ " => SingleCoderivative.scoderiv
infixl:75 " ⇗ " => Coderivative.coderiv

@[simp]
theorem deriv_single {X Y : Type _} [Derivative X Y β γ] (x : X) (h : γ < β) :
    x ⇘ .single h = x ↘ h :=
  Derivative.deriv_single x h

@[simp]
theorem coderiv_single {X Y : Type _} [Coderivative X Y β γ] (x : X) (h : γ < β) :
    x ⇗ .single h = x ↗ h :=
  Coderivative.coderiv_single x h

/-!
## Downwards recursion along paths
-/

instance : SingleDerivative (α ↝ β) (α ↝ γ) β γ where
  sderiv := .cons

/-- The downwards recursion principle for paths. -/
@[elab_as_elim, induction_eliminator, cases_eliminator]
def Path.recSderiv {motive : ∀ β, α ↝ β → Sort _}
    (nil : motive α .nil)
    (sderiv : ∀ β γ (A : α ↝ β) (h : γ < β), motive β A → motive γ (A ↘ h)) :
    {β : TypeIndex} → (A : α ↝ β) → motive β A
  | _, .nil => nil
  | _, .cons A h => sderiv _ _ A h (recSderiv nil sderiv A)

@[simp]
theorem Path.recSderiv_nil {motive : ∀ β, α ↝ β → Sort _}
    (nil : motive α .nil)
    (sderiv : ∀ β γ (A : α ↝ β) (h : γ < β), motive β A → motive γ (A ↘ h)) :
    recSderiv (motive := motive) nil sderiv .nil = nil :=
  rfl

@[simp]
theorem Path.recSderiv_sderiv {motive : ∀ β, α ↝ β → Sort _}
    (nil : motive α .nil)
    (sderiv : ∀ β γ (A : α ↝ β) (h : γ < β), motive β A → motive γ (A ↘ h))
    {β γ : TypeIndex} (A : α ↝ β) (h : γ < β) :
    recSderiv (motive := motive) nil sderiv (A ↘ h) = sderiv β γ A h (recSderiv nil sderiv A) :=
  rfl

theorem Path.le (A : α ↝ β) : β ≤ α := by
  induction A with
  | nil => exact le_rfl
  | sderiv β γ _A h h' => exact h.le.trans h'

/-- The downwards recursion principle for paths, specialised to the case where the motive at `β`
only depends on the fact that `β ≤ α`. -/
def Path.recSderivLe {motive : ∀ β ≤ α, Sort _}
    (nil : motive α le_rfl)
    (sderiv : ∀ β γ, ∀ (A : α ↝ β) (h : γ < β), motive β A.le → motive γ (h.le.trans A.le)) :
    {β : TypeIndex} → (A : α ↝ β) → motive β A.le :=
  Path.recSderiv (motive := λ β A ↦ motive β A.le) nil sderiv

@[simp]
theorem Path.recSderivLe_nil {motive : ∀ β ≤ α, Sort _}
    (nil : motive α le_rfl)
    (sderiv : ∀ β γ (A : α ↝ β) (h : γ < β), motive β A.le → motive γ (h.le.trans A.le)) :
    recSderivLe (motive := motive) nil sderiv .nil = nil :=
  rfl

@[simp]
theorem Path.recSderivLe_sderiv {motive : ∀ β ≤ α, Sort _}
    (nil : motive α le_rfl)
    (sderiv : ∀ β γ (A : α ↝ β) (h : γ < β), motive β A.le → motive γ (h.le.trans A.le))
    {β γ : TypeIndex} (A : α ↝ β) (h : γ < β) :
    recSderivLe (motive := motive) nil sderiv (A ↘ h) = sderiv β γ A h (recSderiv nil sderiv A) :=
  rfl

/-- The downwards recursion principle for paths, specialised to the case where the motive is not
dependent on the relation of `β` to `α`. -/
@[elab_as_elim]
def Path.recSderivGlobal {motive : TypeIndex → Sort _}
    (nil : motive α)
    (sderiv : ∀ β γ, α ↝ β → γ < β → motive β → motive γ) :
    {β : TypeIndex} → α ↝ β → motive β :=
  Path.recSderiv (motive := λ β _ ↦ motive β) nil sderiv

@[simp]
theorem Path.recSderivGlobal_nil {motive : TypeIndex → Sort _}
    (nil : motive α)
    (sderiv : ∀ β γ, α ↝ β → γ < β → motive β → motive γ) :
    recSderivGlobal (motive := motive) nil sderiv .nil = nil :=
  rfl

@[simp]
theorem Path.recSderivGlobal_sderiv {motive : TypeIndex → Sort _}
    (nil : motive α)
    (sderiv : ∀ β γ, α ↝ β → γ < β → motive β → motive γ)
    {β γ : TypeIndex} (A : α ↝ β) (h : γ < β) :
    recSderivGlobal (motive := motive) nil sderiv (A ↘ h) =
      sderiv β γ A h (recSderiv nil sderiv A) :=
  rfl

instance : Derivative (α ↝ β) (α ↝ γ) β γ where
  deriv A := Path.recSderivGlobal A (λ _ _ _ h B ↦ B ↘ h)

instance : Coderivative (β ↝ γ) (α ↝ γ) α β where
  coderiv A B := B ⇘ A

@[simp]
theorem Path.deriv_nil (A : α ↝ β) :
    A ⇘ .nil = A :=
  rfl

@[simp]
theorem Path.deriv_sderiv (A : α ↝ β) (B : β ↝ γ) (h : δ < γ) :
    A ⇘ (B ↘ h) = A ⇘ B ↘ h :=
  rfl

@[simp]
theorem Path.deriv_assoc (A : α ↝ β) (B : β ↝ γ) (C : γ ↝ δ) :
    A ⇘ (B ⇘ C) = A ⇘ B ⇘ C := by
  induction C with
  | nil => rfl
  | sderiv ε ζ C h ih => simp only [deriv_sderiv, ih]

theorem Path.coderiv_eq_deriv (A : α ↝ β) (B : β ↝ γ) :
    B ⇗ A = A ⇘ B :=
  rfl

theorem Path.coderiv_deriv (A : β ↝ γ) (h₁ : β < α) (h₂ : δ < γ) :
    A ↗ h₁ ↘ h₂ = A ↘ h₂ ↗ h₁ :=
  rfl

/-!
## Upwards recursion along paths
-/

/--
The same as `Path`, but the components of this path point "upwards" instead of "downwards".
This type is only used for proving `revScoderiv`, and should be considered an implementation detail.
-/
inductive RevPath (α : TypeIndex) : TypeIndex → Type u
  | nil : RevPath α α
  | cons {β γ : TypeIndex} : RevPath α β → β < γ → RevPath α γ

/-- A computable statement of the recursion principle for `RevPath`. This needs to be written due
to a current limitation in the Lean 4 kernel: it cannot generate code for the `.rec` functions. -/
def RevPath.rec' {motive : (β : TypeIndex) → RevPath α β → Sort _}
    (nil : motive α RevPath.nil)
    (cons : {β γ : TypeIndex} → (A : RevPath α β) → (h : β < γ) →
      motive β A → motive γ (A.cons h)) :
    {β : TypeIndex} → (A : RevPath α β) → motive β A
  | _, .nil => nil
  | _, .cons A h => cons A h (RevPath.rec' nil cons A)

def RevPath.snoc (h : γ < β) : {α : TypeIndex} → RevPath β α → RevPath γ α
  | _, .nil => .cons .nil h
  | _, .cons A h' => (RevPath.snoc h A).cons h'

def Path.rev : α ↝ β → RevPath β α :=
  Path.recSderiv .nil (λ _ _ _ h ↦ RevPath.snoc h)

@[simp]
theorem Path.rev_nil :
    (.nil : α ↝ α).rev = .nil :=
  rfl

@[simp]
theorem Path.rev_sderiv (A : α ↝ β) (h : γ < β) :
    (A ↘ h).rev = A.rev.snoc h :=
  rfl

def RevPath.rev : {α : TypeIndex} → RevPath β α → α ↝ β
  | _, .nil => .nil
  | _, .cons A h => RevPath.rev A ↗ h

theorem Path.sderiv_rev (A : α ↝ β) (h : γ < β) :
    (A ↘ h).rev = A.rev.snoc h :=
  rfl

theorem Path.scoderiv_rev (A : β ↝ γ) (h : β < α) :
    (A ↗ h).rev = A.rev.cons h := by
  induction A with
  | nil => rfl
  | sderiv δ ε A h ih => rw [rev_sderiv, ← coderiv_deriv, rev_sderiv, ih, RevPath.snoc]

theorem RevPath.snoc_rev (A : RevPath β α) (h : γ < β) :
    (A.snoc h).rev = A.rev ↘ h := by
  induction A with
  | nil => rfl
  | cons A h ih => rw [snoc, rev, ih, rev, Path.coderiv_deriv]

theorem Path.rev_rev (A : α ↝ β) : A.rev.rev = A := by
  induction A with
  | nil => rfl
  | sderiv γ δ A h ih => rw [Path.sderiv_rev, RevPath.snoc_rev, ih]

def Path.recScoderiv' {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h))
    {β : TypeIndex} (A : RevPath γ β) : motive β A.rev :=
  RevPath.rec' (motive := λ β A ↦ motive β A.rev) nil (λ A ↦ scoderiv _ _ A.rev) A

@[simp]
theorem Path.recScoderiv'_nil {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h)) :
    recScoderiv' (motive := motive) nil scoderiv .nil = nil :=
  rfl

@[simp]
theorem Path.recScoderiv'_cons {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h))
    (A : RevPath γ β) (h : β < α) :
    recScoderiv' (motive := motive) nil scoderiv (A.cons h) =
      scoderiv α β A.rev h (recScoderiv' nil scoderiv A) :=
  rfl

/-- The upwards recursion principle for paths. The `scoderiv` computation rule
`recScoderiv_scoderiv` is not a definitional equality. -/
@[elab_as_elim]
def Path.recScoderiv {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h))
    {β : TypeIndex} (A : β ↝ γ) : motive β A :=
  cast (by rw [A.rev_rev]) (recScoderiv' nil scoderiv A.rev)

@[simp]
theorem Path.recScoderiv_nil {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h)) :
    recScoderiv (motive := motive) nil scoderiv .nil = nil :=
  rfl

@[simp]
theorem Path.recScoderiv_scoderiv {motive : ∀ β, β ↝ γ → Sort _}
    (nil : motive γ .nil)
    (scoderiv : ∀ α β (A : β ↝ γ) (h : β < α), motive β A → motive α (A ↗ h))
    {α β : TypeIndex} (A : β ↝ γ) (h : β < α) :
    recScoderiv (motive := motive) nil scoderiv (A ↗ h) =
      scoderiv α β A h (recScoderiv nil scoderiv A) := by
  unfold recScoderiv
  rw [cast_eq_iff_heq, scoderiv_rev, recScoderiv'_cons]
  congr 1
  · exact A.rev_rev
  · exact HEq.symm (cast_heq _ _)

end ConNF
