import phase2.constrains

open set sum

universe u

namespace con_nf
variables [params.{u}] (α : Λ) [position_data.{}] [phase_2_assumptions α] {β : type_index}

/-- A litter is *inflexible* if it is the image of some f-map. -/
@[mk_iff] inductive inflexible : litter → extended_index β → Prop
| mk_coe ⦃γ : Iic α⦄ ⦃δ : Iio α⦄ ⦃ε : Iio α⦄ (hδ : (δ : Λ) < γ) (hε : (ε : Λ) < γ) (hδε : δ ≠ ε)
    (A : quiver.path (β : type_index) γ) (t : tangle δ) :
    inflexible
      (f_map (with_bot.coe_ne_coe.mpr $ coe_ne' hδε) t)
      ((A.cons (coe_lt hε)).cons (with_bot.bot_lt_coe _))
| mk_bot ⦃γ : Iic α⦄ ⦃ε : Iio α⦄ (hε : (ε : Λ) < γ)
    (A : quiver.path (β : type_index) γ) (a : atom) :
    inflexible
      (f_map (show (⊥ : type_index) ≠ (ε : Λ), from with_bot.bot_ne_coe) a)
      ((A.cons (coe_lt hε)).cons (with_bot.bot_lt_coe _))

/-- A litter is *flexible* if it is not the image of any f-map. -/
def flexible (L : litter) (A : extended_index β) : Prop := ¬inflexible α L A

variable {α}

lemma inflexible.comp {γ : type_index} {L : litter} {A : extended_index γ}
  (h : inflexible α L A) (B : quiver.path β γ) : inflexible α L (B.comp A) :=
begin
  induction h,
  refine inflexible.mk_coe _ _ _ _ _,
  assumption,
  exact inflexible.mk_bot _ _ _,
end

@[simp] lemma not_flexible_iff {L : litter} {A : extended_index β} :
  ¬flexible α L A ↔ inflexible α L A := not_not

lemma flexible_of_comp_flexible {γ : type_index} {L : litter} {A : extended_index γ}
  {B : quiver.path β γ} (h : flexible α L (B.comp A)) : flexible α L A :=
λ h', h (h'.comp B)

end con_nf