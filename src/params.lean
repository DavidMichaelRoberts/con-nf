import set_theory.cardinal.cofinality

/-!
# Parameters of the construction

This file is based on sections 3.1 and 3.2 of the paper.
-/

/-!
We do not assume that our definitions, instances, lemmas and theorems are 'computable';
that is, can be provably evaluated in finite time by a computer.
For our purposes, restricting to only computable functions is unnecessary.
-/
noncomputable theory

open cardinal
open_locale cardinal classical

universe u

namespace con_nf

/--
The parameters of the constructions. We collect them all in one class for simplicity.
Note that the ordinal `λ` in the paper is instead referred to here as `Λ`, since the symbol `λ` is
used for lambda abstractions.

Ordinals and cardinals are represented here as arbitrary types (not sets) with certain properties.
For instance, `Λ` is an arbitrary type that has an ordering `Λr`, which is assumed to be a
well-ordering (the `Λwf` term is a proof of this fact). If `Λr a b` holds, then we can say `a < b`.

The prefix `#` denotes the cardinality of a type.

Where possible, we use `<` and `≤` instead of `>` and `≥`. Human readers can easily convert between
the two, but it is not as immediately transparent for Lean. For simplicity, we keep with the
convention of using only `<` and `≤`.

When working with these parameters, it is useful to `open params` in order to address the parameters
simply by name, instead of having to type `params.Λ`, for instance.
-/
class params :=
(Λ : Type u) (Λr : Λ → Λ → Prop) [Λwf : is_well_order Λ Λr]
(Λ_ord : ordinal.type Λr = (#Λ).ord)
(Λ_limit : (#Λ).is_limit)
(κ : Type u) (κ_regular : (#κ).is_regular)
(Λ_lt_κ : #Λ < #κ)
(μ : Type u) (μr : μ → μ → Prop) [μwf : is_well_order μ μr]
(μ_ord : ordinal.type μr = (#μ).ord)
(μ_strong_limit : (#μ).is_strong_limit)
(κ_lt_μ : #κ < #μ)
(κ_le_μ_cof : #κ ≤ (#μ).ord.cof)
(δ : Λ)
(hδ : (ordinal.typein Λr δ).is_limit)

/-- There exists a set of valid parameters for the model. -/
example : params := sorry

open params

variables [params.{u}]

/-- To allow Lean's type checker to see that the ordering `Λr` is a well-ordering without having to
explicitly write `Λwf` everywhere, we declare it as an instance. -/
instance : is_well_order Λ Λr := Λwf
/-- We can deduce from the well-ordering `Λwf` that `Λ` is linearly ordered. -/
instance : linear_order Λ := linear_order_of_STO' Λr
/-- We deduce that `Λ` has a well-founded relation. -/
instance : has_well_founded Λ := is_well_order.to_has_well_founded

lemma κ_le_μ : #κ ≤ #μ := κ_lt_μ.le

noncomputable instance : inhabited Λ :=
@classical.inhabited_of_nonempty _ $ cardinal.mk_ne_zero_iff.1 Λ_limit.ne_zero

noncomputable instance : inhabited κ :=
@classical.inhabited_of_nonempty _ $ cardinal.mk_ne_zero_iff.1 κ_regular.pos.ne'

noncomputable instance : inhabited μ  :=
@classical.inhabited_of_nonempty _ $ cardinal.mk_ne_zero_iff.1 μ_strong_limit.ne_zero

/-- The litters. This is the type indexing the partition of `base_type`. -/
@[derive inhabited, irreducible] def litter := (Λ × Λ) × μ

@[simp] lemma mk_litter : #litter = #μ :=
by simp_rw [litter, mk_prod, lift_id, mul_assoc, mul_eq_right
  (κ_regular.aleph_0_le.trans κ_lt_μ.le) (Λ_lt_κ.le.trans κ_lt_μ.le) Λ_limit.ne_zero]

/-- The base type of the construction, `τ₋₁` in the document. Instead of declaring it as an
arbitrary type of cardinality `μ` and partitioning it into suitable sets of litters afterwards, we
define it as `litter × κ`, which has the correct cardinality and comes with a natural
partition.

This type is occasionally referred to as a type of atoms. These are not 'atoms' in the ZFU, TTTU or
NFU sense; they are simply the elements of the model which are in type `τ₋₁`. -/
@[derive inhabited] def base_type : Type* := litter × κ

/-- The cardinality of `τ₋₁` is the cardinality of `μ`.
We will prove that all types constructed in our model have cardinality equal to `μ`. -/
@[simp] lemma mk_base_type : #base_type = #μ :=
by simp_rw [base_type, mk_prod, lift_id, mk_litter,
  mul_eq_left (κ_regular.aleph_0_le.trans κ_le_μ) κ_le_μ κ_regular.pos.ne']

end con_nf
