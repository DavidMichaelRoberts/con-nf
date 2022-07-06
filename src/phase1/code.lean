import phase0.litter
import phase1.basic

open equiv equiv.perm with_bot

noncomputable theory

universe u

namespace con_nf
variables [params.{u}] (α : Λ) [phase_1a α] {β : Λ} {hβ : β ≤ α}

/-- A type-`β` code is a type index `γ < β` together with a set of tangles of type `γ`.
So far, we can only construct type `β` codes for `β ≤ α`. Notably, we can construct `α`-codes. -/
@[ext] structure code (β : Λ) (hβ : β ≤ α) :=
(extension : type_index)
(extension_lt : extension < β)
(elts : set (tangle α extension $ extension_lt.trans_le $ coe_le_coe.2 hβ))

lemma code.mk_eq_mk (β : Λ) (hβ : β ≤ α) (γ : type_index) (hγ : γ < β)
  (e f : set (tangle α γ $ hγ.trans_le $ coe_le_coe.2 hβ)) :
  (⟨γ, hγ, e⟩ : code α β hβ) = ⟨γ, hγ, f⟩ ↔ e = f :=
by { split; intro h; cases h; refl }

/-- Nonempty codes -/
abbreviation nonempty_code (β : Λ) (hβ : β ≤ α) : Type* := {c : code α β hβ // c.elts.nonempty}

variables {α}

/-- A code is empty if it has no element.-/
protected def code.is_empty (c : code α β hβ) : Prop := c.elts = ∅

@[simp] lemma code.is_empty_mk {γ hγ s} : (⟨γ, hγ, s⟩ : code α β hβ).is_empty ↔ s = ∅ := iff.rfl

variables (α)

/-- Suppose that the set of tangles embeds into the set of codes. -/
class phase_1a_embedding :=
(tangle_embedding : Π (β < α), tangle _ β (coe_lt_coe.mpr ‹_›) ↪ code α β (le_of_lt ‹_›))

open phase_1a_embedding
variable [phase_1a_embedding.{u} α]

def code.is_tangle {β < α} (c : code α β $ le_of_lt ‹_›) : Prop :=
∃ t : tangle α β (coe_lt_coe.2 ‹_›), c = tangle_embedding β ‹_› t

end con_nf