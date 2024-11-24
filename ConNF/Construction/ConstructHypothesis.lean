import ConNF.Construction.ConstructMotive

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal WithBot

namespace ConNF

variable [Params.{u}] {α : Λ} (M : (β : Λ) → (β : TypeIndex) < α → Motive β)
  (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h))

def constructAllPermSderiv {β : Λ} (h : (β : TypeIndex) < α)
    (ρ : (constructMotive α M H).data.AllPerm) : (M β h).data.AllPerm :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨h⟩
  ρ.sderiv β

def constructAllPermBotSderiv (ρ : (constructMotive α M H).data.AllPerm) : botModelData.AllPerm :=
  letI : Level := ⟨α⟩
  letI := ltData M
  ρ.sderiv ⊥

def constructSingleton {β : Λ} (h : (β : TypeIndex) < α)
    (x : (M β h).data.TSet) : (constructMotive α M H).data.TSet :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨h⟩
  Option.some (newSingleton x)

theorem constructMotive_allPermSderiv_forget {β : Λ} (h : (β : TypeIndex) < α)
    (ρ : (constructMotive α M H).data.AllPerm) :
    (M β h).data.allPermForget (constructAllPermSderiv M H h ρ) =
    (constructMotive α M H).data.allPermForget ρ ↘ h :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨h⟩
  (NewPerm.forget_sderiv ρ β).symm

theorem constructMotive_allPermBotSderiv_forget (ρ : (constructMotive α M H).data.AllPerm) :
    botModelData.allPermForget (constructAllPermBotSderiv M H ρ) =
    (constructMotive α M H).data.allPermForget ρ ↘ bot_lt_coe _ :=
  letI : Level := ⟨α⟩
  letI := ltData M
  (NewPerm.forget_sderiv ρ ⊥).symm

theorem constructMotive_pos_atom_lt_pos :
    letI := (constructMotive α M H).data; letI := (constructMotive α M H).pos
    ∀ (t : Tangle α) (A : α ↝ ⊥) (a : Atom), a ∈ (t.support ⇘. A)ᴬ → pos a < pos t :=
  letI : Level := ⟨α⟩
  letI := ltData M
  λ t A a ↦ pos_atom_lt_newPosition _ t a A

theorem constructMotive_pos_nearLitter_lt_pos :
    letI := (constructMotive α M H).data; letI := (constructMotive α M H).pos
    ∀ (t : Tangle α) (A : α ↝ ⊥) (M : NearLitter), M ∈ (t.support ⇘. A)ᴺ → pos M < pos t :=
  letI : Level := ⟨α⟩
  letI := ltData M
  λ t A N ↦ pos_nearLitter_lt_newPosition _ t N A

theorem constructMotive_smul_fuzz {β γ : Λ} (hβ : (β : TypeIndex) < α)
    (hγ : (γ : TypeIndex) < α) (hβγ : (β : TypeIndex) ≠ γ) :
    letI := (M β hβ).data; letI := (M β hβ).pos
    ∀ (ρ : (constructMotive α M H).data.AllPerm) (t : Tangle β),
      (constructMotive α M H).data.allPermForget ρ ↘ hγ ↘. • fuzz hβγ t =
      fuzz hβγ (constructAllPermSderiv M H hβ ρ • t) :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨hβ⟩
  letI : LtLevel γ := ⟨hγ⟩
  λ ρ ↦ ρ.smul_fuzz hβγ

theorem constructMotive_smul_fuzz_bot {γ : Λ} (hγ : (γ : TypeIndex) < α) :
    letI := botModelData; letI := botPosition
    ∀ (ρ : (constructMotive α M H).data.AllPerm) (t : Tangle ⊥),
    (constructMotive α M H).data.allPermForget ρ ↘ hγ ↘. • fuzz (bot_ne_coe (a := γ)) t =
      fuzz (bot_ne_coe (a := γ)) (constructAllPermBotSderiv M H ρ • t) :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel γ := ⟨hγ⟩
  λ ρ ↦ ρ.smul_fuzz bot_ne_coe

theorem constructMotive_allPerm_of_smul_fuzz :
    ∀ (ρs : {β : Λ} → (hβ : (β : TypeIndex) < α) → (M β hβ).data.AllPerm)
    (π : letI := botModelData; AllPerm ⊥),
    (∀ {β γ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < α),
      letI := (M β hβ).data; letI := (M β hβ).pos
      ∀ (hδε : (β : TypeIndex) ≠ γ) (t : Tangle β),
      (ρs hγ)ᵁ ↘. • fuzz hδε t = fuzz hδε (ρs hβ • t)) →
    (∀ {γ : Λ} (hγ : (γ : TypeIndex) < α) (t : letI := botModelData; Tangle ⊥),
      letI := botModelData; letI := botPosition
      (ρs hγ)ᵁ ↘. • fuzz (bot_ne_coe (a := γ)) t = fuzz (bot_ne_coe (a := γ)) (π • t)) →
    ∃ ρ : (constructMotive α M H).data.AllPerm,
      (∀ (β : Λ) (hβ : (β : TypeIndex) < α), constructAllPermSderiv M H hβ ρ = ρs hβ) ∧
      constructAllPermBotSderiv M H ρ = π := by
  letI : Level := ⟨α⟩
  letI := ltData M
  intro ρs π h₁ h₂
  refine ⟨⟨λ β iβ ↦ β.recBotCoe (λ _ ↦ π) (λ β iβ ↦ ρs iβ.elim) iβ, ?_⟩, ?_, ?_⟩
  · intro β
    induction β using recBotCoe with
    | bot =>
      intro γ _ _ hβγ t
      exact h₂ LtLevel.elim t
    | coe β =>
      intro γ _ _
      exact h₁ LtLevel.elim LtLevel.elim
  · intro β hβ
    rfl
  · rfl

theorem constructMotive_tSet_ext (β : Λ) (hβ : (β : TypeIndex) < α)
    (x y : (constructMotive α M H).data.TSet) :
    (∀ z : (M β hβ).data.TSet, z ∈[hβ] x ↔ z ∈[hβ] y) → x = y :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨hβ⟩
  newModelData_ext β x y

theorem constructMotive_typedMem_singleton_iff {β : Λ} (hβ : (β : TypeIndex) < α)
    (x y : (M β hβ).data.TSet) :
    y ∈[hβ] constructSingleton M H hβ x ↔ y = x :=
  letI : Level := ⟨α⟩
  letI := ltData M
  letI : LtLevel β := ⟨hβ⟩
  mem_newSingleton_iff x y

def constructHypothesis (α : Λ) (M : (β : Λ) → (β : TypeIndex) < α → Motive β)
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h)) :
    Hypothesis (constructMotive α M H) M :=
  {
    allPermSderiv := constructAllPermSderiv M H
    allPermBotSderiv := constructAllPermBotSderiv M H
    singleton := constructSingleton M H
    allPermSderiv_forget := constructMotive_allPermSderiv_forget M H
    allPermBotSderiv_forget := constructMotive_allPermBotSderiv_forget M H
    pos_atom_lt_pos := constructMotive_pos_atom_lt_pos M H
    pos_nearLitter_lt_pos := constructMotive_pos_nearLitter_lt_pos M H
    smul_fuzz := constructMotive_smul_fuzz M H
    smul_fuzz_bot := constructMotive_smul_fuzz_bot M H
    allPerm_of_smul_fuzz := constructMotive_allPerm_of_smul_fuzz M H
    tSet_ext := constructMotive_tSet_ext M H
    typedMem_singleton_iff := constructMotive_typedMem_singleton_iff M H
  }

end ConNF
