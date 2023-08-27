import ConNF.Foa.Basic.Flexible
import ConNF.Foa.Action.NearLitterAction

open Cardinal Quiver Set Sum WithBot

open scoped Cardinal Classical Pointwise

universe u

namespace ConNF

variable [Params.{u}]

/-!
# Structural actions
-/

/-- A `β`-structural action is a product that assigns a near-litter action to each `β`-extended
index. -/
def StructAction (β : TypeIndex) :=
  ExtendedIndex β → NearLitterAction

namespace StructAction

def Lawful {β : TypeIndex} (φ : StructAction β) : Prop :=
  ∀ B, (φ B).Lawful

/-- This structural action maps flexible litters to flexible litters. -/
def MapFlexible {α : Λ} [BasePositions] [Phase2Assumptions α] {β : Iio α} (φ : StructAction β) :
    Prop :=
  ∀ (L : Litter) (B hL), Flexible α L B → Flexible α (((φ B).litterMap L).get hL).1 B

section Precise

def Precise {β : TypeIndex} (φ : StructAction β) : Prop :=
  ∀ B, (φ B).Precise

variable {α : Λ} [BasePositions] [Phase2Assumptions α] {β : Iio α} (φ : StructAction β)

noncomputable def complete (hφ : φ.Lawful) : StructApprox β := fun B => (φ B).complete (hφ B) B

theorem complete_apply (hφ : φ.Lawful) (B : ExtendedIndex β) :
    φ.complete hφ B = (φ B).complete (hφ B) B :=
  rfl

theorem smul_atom_eq {hφ : φ.Lawful} {π : StructPerm β} (hπ : (φ.complete hφ).ExactlyApproximates π)
    {a : Atom} {B : ExtendedIndex β} (ha : ((φ B).atomMap a).Dom) :
    StructPerm.derivative B π • a = ((φ B).atomMap a).get ha := by
  have := (φ B).smul_atom_eq (hπ B) ha
  rw [StructPerm.ofBot_smul] at this
  exact this

theorem smul_toNearLitter_eq_of_precise {hφ : φ.Lawful} (hφp : φ.Precise) {π : StructPerm β}
    (hπ : (φ.complete hφ).ExactlyApproximates π) {L : Litter} {B : ExtendedIndex β}
    (hL : ((φ B).litterMap L).Dom)
    (hπL : StructPerm.derivative B π • L = (((φ B).litterMap L).get hL).1) :
    StructPerm.derivative B π • L.toNearLitter = ((φ B).litterMap L).get hL := by
  have := (φ B).smul_toNearLitter_eq_of_preciseAt (hπ B) hL (hφp B hL) ?_
  · rw [StructPerm.ofBot_smul] at this
    exact this
  · rw [StructPerm.ofBot_smul]
    exact hπL

theorem smul_nearLitter_eq_of_precise {hφ : φ.Lawful} (hφp : φ.Precise) {π : StructPerm β}
    (hπ : (φ.complete hφ).ExactlyApproximates π) {N : NearLitter} {B : ExtendedIndex β}
    (hN : ((φ B).litterMap N.1).Dom)
    (hπL : StructPerm.derivative B π • N.1 = (((φ B).litterMap N.1).get hN).1) :
    ((StructPerm.derivative B π • N : NearLitter) : Set Atom) =
      (((φ B).litterMap N.1).get hN : Set Atom) ∆
        (StructPerm.derivative B π • litterSet N.1 ∆ N) := by
  have := (φ B).smul_nearLitter_eq_of_preciseAt (hπ B) hN (hφp B hN) ?_
  · rw [StructPerm.ofBot_smul] at this
    exact this
  · rw [StructPerm.ofBot_smul]
    exact hπL

end Precise

variable {α : Λ} [BasePositions] [Phase2Assumptions α] {β : Iio α}

/-- A structural action *supports* a tangle if it defines an image for everything
in the reduction of its designated support. -/
structure Supports (φ : StructAction β) (t : Tangle β) : Prop where
  atom_mem : ∀ a B, (inl a, B) ∈ reducedSupport α t → ((φ B).atomMap a).Dom
  litter_mem :
    ∀ (L : Litter) (B), (inr L.toNearLitter, B) ∈ reducedSupport α t → ((φ B).litterMap L).Dom

instance {β : TypeIndex} : PartialOrder (StructAction β)
    where
  le φ ψ := ∀ B, φ B ≤ ψ B
  le_refl φ B := le_rfl
  le_trans φ ψ χ h₁ h₂ B := (h₁ B).trans (h₂ B)
  le_antisymm φ ψ h₁ h₂ := funext fun B => le_antisymm (h₁ B) (h₂ B)

theorem Lawful.le {β : TypeIndex} {φ ψ : StructAction β} (h : φ.Lawful) (hψ : ψ ≤ φ) : ψ.Lawful :=
  fun B => (h B).le (hψ B)

def comp {β γ : TypeIndex} (φ : StructAction β) (A : Path β γ) : StructAction γ := fun B =>
  { atomMap := (φ (A.comp B)).atomMap
    litterMap := (φ (A.comp B)).litterMap
    atomMap_dom_small := by
      refine' Small.image_subset id Function.injective_id (φ (A.comp B)).atomMap_dom_small _
      simp only [id_eq, image_id']
      rfl
    litterMap_dom_small := by
      refine' Small.image_subset id Function.injective_id (φ (A.comp B)).litterMap_dom_small _
      simp only [id.def, image_id']
      rfl }

@[simp]
theorem comp_apply {β γ : TypeIndex} {φ : StructAction β} {A : Path β γ} {B : ExtendedIndex γ} :
    φ.comp A B = φ (A.comp B) := by ext : 1 <;> rfl

theorem comp_comp {β γ δ : TypeIndex} {φ : StructAction β} {A : Path β γ} {B : Path γ δ} :
    (φ.comp A).comp B = φ.comp (A.comp B) := by
  funext A
  ext : 1 <;>
    simp only [comp_apply, Path.comp_assoc]

theorem le_comp {β γ : TypeIndex} {φ ψ : StructAction β} (h : φ ≤ ψ) (A : Path β γ) :
    φ.comp A ≤ ψ.comp A := fun B => h (A.comp B)

theorem Lawful.comp {β γ : TypeIndex} {φ : StructAction β} (h : φ.Lawful) (A : Path β γ) :
    Lawful (φ.comp A) := fun B =>
  { atomMap_injective := (h (A.comp B)).atomMap_injective
    litterMap_injective := (h (A.comp B)).litterMap_injective
    atom_mem := (h (A.comp B)).atom_mem }

end StructAction

end ConNF