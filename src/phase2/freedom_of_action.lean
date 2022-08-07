import mathlib.transfer
import phase2.basic
import order.copy

/-!
# The freedom of action theorem

In this file, we will state and prove the freedom of action theorem.

We state the freedom of action condition at a particular proper type index `α`. Note that many of
the definitions are in a slightly different form from the blueprint and paper. This is likely for
one of two reasons:

* The freedom of action theorem has been substantially changed since the blueprint and paper were
    created. The blueprint is in the process of being updated, but it may not precisely reflect the
    current implementation.
* We define our paths between type indices in the opposite category `Paths(Λ, <)ᵒᵖ = Paths(Λ, >)`
    instead of the category `Paths(Λ, <)` as is seen in the blueprint. This means that paths are
    thought of as going "downwards" from `α` to `⊥` instead of upwards. Path composition is
    therefore reversed.

For most of these proofs, we assume the phase 2 assumptions at `α`. However, since we often want to
talk about allowable permutations and specifications at lower levels, we often have an ambient
parameter `B : le_index α`, which can be thought of as a path from `α` to some lower index `B`.

Often, when the blueprint or paper talks about an `α`-something, we will instead define it as a
`B`-something for increased generality. This is most useful when stating and proving the restriction
lemma and the condition on non-flexible litters.

-----

## Definitions

### Specifications

The freedom of action theorem concerns itself with completing *specifications* of allowable
permutations into an actual allowable partial permutation that satisfies the specification. In
particular, we define a specification as a set that specifies the images of certain atoms and
near-litters under certain derivatives of a permutation. For example, a specification for an
`B`-allowable permutation might specify that `π_A(a) = b` for `A` a `B`-extended index, and `a` and
`b` atoms.

We implement this in Lean by defining a specification as a set of binary conditions, where each
binary condition specifies either an atom to be supplied to `π` and the atom it is to be mapped to,
or a near-litter to be supplied and the near-litter it is to be mapped to, together with the
`B`-extended index along which we take the derivative.

We say that an allowable permutation `π` *satisfies* a given specification if all of the binary
conditions in the specification are realised by the specification; that is, if a binary condition
specifies `π_A(x) = y` then we must in fact have `π_A(x) = y` for this particular `π`.

### Allowability

We say that a specification is *allowable* (`allowable`) if it satisfies a collection of
relatively permissive conditions. Essentially, we need to ensure that there are no obvious local
contradictions in the specification. For example, the one-to-one condition requires that if we
specify `π_A(a) = b`, we cannot also specify `π_A(a) = c` for some `c ≠ b`, and we cannot specify
`π_A(d) = b` for `d ≠ a` either.

More details on these conditions are discussed in depth later.

If a specification is allowable, we call it an *allowable partial permutation*
(`allowable_partial_perm`).

-----

## The theorem itself

We say that *freedom of action* holds along a path `B` if any partial allowable permutation `σ`
admits an allowable permutation `π` that satisfies it. The freedom of action theorem, our goal in
this file, states that if freedom of action holds along all proper paths `B`, and we are in the
synthesised context produced by our constructions in phase 1 at `α`, then freedom of action holds
at `α` (or more properly, at the nil path `α ⟶ α`).

To prove the freedom of action theorem, we follow the following steps.

1. We construct a preorder on the type of allowable partial permutations that satisfies some
    technical conditions (`perm_le`). Now, suppose we have a particular allowable partial
    permutation `σ`. We apply Zorn's lemma to this to generate another allowable partial permutation
    `τ` which is maximal under `≤` (`perm_le`), such that `σ ≤ τ`.
2. We prove that any allowable partial permutation `τ` which is maximal under `≤` is total and
    co-total, in the sense that the specification defines where every atom and near-litter go, along
    any derivative path.
3. We then prove that a total and co-total allowable partial permutation can be synthesised into an
    allowable permutation `π` given that we are in the synthesised context at `α`. This is precisely
    the allowable permutation that we need to complete the proof.

### Step 1: Zorn's lemma

What we call `σ ≤ τ`, the blueprint calls `σ ⊑ τ`, saying that `τ` "carefully extends" `σ`.
`σ ≤ τ` means that `σ ⊆ τ` as specifications, and:

* if `τ` has any new `A`-flexible litter, then it has all (in both domain and range);
* within each litter, if `τ.domain` has any new atom, then it must have all atoms in that litter
    (and hence must also have the litter by allowability), and dually for the range.

To prove that Zorn's lemma can be applied, we must show that for any chain `c` of allowable
partial permutations, the union of the specifications in the chain is allowable, and carefully
extends every element of the chain.

The non-trivial part of this proof is the "small or all" conditions for atoms and flexible litters.
Due to the particular construction of the preorder `≤`, if we add any atom (resp. flexible litter),
we must add all of them.

### Step 2: Totality

By symmetry, it suffices to only consider totality. We construct the well-founded relation `≺`
(read "constrains") on support conditions. Note that here, a support condition represents the
expression `π_A(x)` without specifying what `x` maps to under `π`. Suppose `π_A(x)` is a support
condition, and `S` is the set of conditions that constrain it; then informally we might say that
if binary conditions associated with each element of `S` lie in `σ` (we say that `S` is a subset of
the domain of `σ`) then we can uniquely determine where `x` is "supposed to" map to under `π`.
More precisely, if `S` is a subset of the domain of `σ`, we can extend `σ` to an allowable partial
permutation `τ ≥ σ` where `π_A(x)` is specified.

We provide one proof for each of the four cases of what `x` may be:

1. an atom;
2. a near-litter;
3. a *flexible* litter;
4. a *non-flexible* litter.

Informally, a flexible litter is one which is not the image of any f-map.

Non-flexible litters are the image of some f-map, and so the unpacked coherence condition specifies
what must happen to that litter, since any allowable permutation must commute with this f-map.
Conversely, flexible litters are not constrained by anything. We therefore need to treat them quite
differently when constructing the extended specification `τ`.

Then, because `≺` is well-founded, any element can be added to an allowable partial permutation
since inductively everything that transitively constrains it can also be added. So any `σ` that
is maximal must be total.

### Step 3: Synthesis into an allowable permutation

This is not yet complete.
-/

noncomputable theory

open cardinal function quiver set sum with_bot
open_locale cardinal pointwise

universe u

namespace con_nf
variables [params.{u}]

open struct_perm

section
variables {α β γ : type_index}

/-- A *binary condition* is like a support condition but uses either two atoms or two near-litters
instead of one. A binary condition `⟨⟨x, y⟩, A⟩` represents the constraint `π_A(x) = y` on an
allowable permutation. -/
abbreviation binary_condition (α : type_index) : Type u :=
((atom × atom) ⊕ (near_litter × near_litter)) × extended_index α

namespace binary_condition

/-- The binary condition representing the inverse permutation. If `π_A(x) = y`, then `π_A⁻¹(y) = x`.
-/
instance (α : type_index) : has_involutive_inv (binary_condition α) :=
{ inv := λ c, ⟨c.1.map prod.swap prod.swap, c.2⟩,
  inv_inv := by rintro ⟨⟨a₁, a₂⟩ | ⟨N₁, N₂⟩, i⟩; refl }

@[simp] lemma inv_mk (x : (atom × atom) ⊕ (near_litter × near_litter)) (i : extended_index α) :
  (x, i)⁻¹ = (x.map prod.swap prod.swap, i) := rfl

/-- Converts a binary condition `⟨⟨x, y⟩, A⟩` into the support condition `⟨x, A⟩`. -/
def domain : binary_condition α → support_condition α := prod.map (sum.map prod.fst prod.fst) id

/-- Converts a binary condition `⟨⟨x, y⟩, A⟩` into the support condition `⟨y, A⟩`. -/
def range : binary_condition α → support_condition α := prod.map (sum.map prod.snd prod.snd) id

@[simp] lemma domain_mk (x : (atom × atom) ⊕ (near_litter × near_litter)) (A : extended_index α) :
  domain (x, A) = (x.map prod.fst prod.fst, A) := rfl

@[simp] lemma range_mk (x : (atom × atom) ⊕ (near_litter × near_litter)) (A : extended_index α) :
  range (x, A) = (x.map prod.snd prod.snd, A) := rfl

@[simp] lemma domain_inv (c : binary_condition α) : c⁻¹.domain = c.range :=
by obtain ⟨⟨_, _⟩ | ⟨_, _⟩, _⟩ := c; refl

@[simp] lemma range_inv (c : binary_condition α) : c⁻¹.range = c.domain :=
by obtain ⟨⟨_, _⟩ | ⟨_, _⟩, _⟩ := c; refl

end binary_condition

/-- There are `μ` binary conditions. -/
lemma mk_binary_condition (α : type_index) : #(binary_condition α) = #μ :=
begin
  have h := μ_strong_limit.is_limit.aleph_0_le,
  rw [← cardinal.mul_def, ← cardinal.add_def, ← cardinal.mul_def, ← cardinal.mul_def, mk_atom,
      mk_near_litter, cardinal.mul_eq_self h, cardinal.add_eq_self h],
  exact cardinal.mul_eq_left h (le_trans (mk_extended_index α) (le_of_lt (lt_trans Λ_lt_κ κ_lt_μ)))
      (mk_extended_index_ne_zero α),
end

/-- A *unary specification* is a set of support conditions. This can be thought of as either the
domain or range of a `spec`. -/
abbreviation unary_spec (α : type_index) : Type u := set (support_condition α)

/-- A *specification* of an allowable permutation is a set of binary conditions on the allowable
permutation.

We make this a custom structure (rather than simply `set (binary_condition α)`) to make
`σ⁻¹.domain = σ.range` and `σ⁻¹.range = σ.domain` definitionally equal. This would already be the
case if Lean had definitional eta reduction for structures. -/
structure spec (α : type_index) : Type u :=
(carrier : set (binary_condition α))
(domain range : unary_spec α)
(image_domain' : binary_condition.domain '' carrier = domain)
(image_range' : binary_condition.range '' carrier = range)

namespace spec
variables {σ τ : spec α} {c d : binary_condition α}

attribute [protected] range

instance : set_like (spec α) (binary_condition α) :=
{ coe := carrier,
  coe_injective' := λ s t h,
    by { cases s, cases t, dsimp at h, subst h, congr'; exact ‹_ = _›.symm.trans ‹_› } }

@[ext] lemma ext : (∀ c, c ∈ σ ↔ c ∈ τ) → σ = τ := set_like.ext

@[simps] def equiv_set : spec α ≃ set (binary_condition α) :=
{ to_fun := coe,
  inv_fun := λ s, { carrier := s,
                    domain := binary_condition.domain '' s,
                    range := binary_condition.range '' s,
                    image_domain' := rfl,
                    image_range' := rfl },
  left_inv := λ _, set_like.coe_injective rfl,
  right_inv := λ _, rfl }

@[simp] lemma image_domain (σ : spec α) :
  binary_condition.domain '' (σ : set (binary_condition α)) = σ.domain := σ.image_domain'

@[simp] lemma image_range (σ : spec α) :
  binary_condition.range '' (σ : set (binary_condition α)) = σ.range := σ.image_range'

instance : complete_distrib_lattice (spec α) :=
equiv_set.complete_distrib_lattice.copy
/- le  -/ _ rfl
/- top -/ _ rfl
/- bot -/ ⟨∅, ∅, ∅, image_empty _, image_empty _⟩ (set_like.coe_injective rfl)
/- sup -/ (λ x y, ⟨x ∪ y, x.domain ∪ y.domain, x.range ∪ y.range,
            by simp_rw [←image_domain, image_union], by simp_rw [←image_range, image_union]⟩)
              (funext $ λ _, funext $ λ _, set_like.coe_injective rfl)
/- inf -/ _ rfl
/- Sup -/ (λ s, ⟨⋃ x ∈ s, ↑x, ⋃ x ∈ s, spec.domain x, ⋃ x ∈ s, spec.range x,
            by simp_rw [image_Union, image_domain], by simp_rw [image_Union, image_range]⟩)
              (funext $ λ _, set_like.coe_injective rfl)
/- Inf -/ _ rfl

@[simp] lemma coe_bot : ((⊥ : spec α) : set $ binary_condition α) = ∅ := rfl
@[simp] lemma coe_top : ((⊤ : spec α) : set $ binary_condition α) = univ := rfl
@[simp] lemma coe_sup (σ τ : spec α) : (↑(σ ⊔ τ) : set $ binary_condition α) = σ ∪ τ := rfl
@[simp] lemma coe_inf (σ τ : spec α) : (↑(σ ⊓ τ) : set $ binary_condition α) = σ ∩ τ := rfl
@[simp] lemma coe_Sup (s : set $ spec α) : (↑(Sup s) : set $ binary_condition α) = ⋃ x ∈ s, ↑x :=
rfl

@[simp] lemma coe_mk (carrier : set (binary_condition α))
  (domain range : unary_spec α)
  (image_domain' : binary_condition.domain '' carrier = domain)
  (image_range' : binary_condition.range '' carrier = range) :
  ((⟨carrier, domain, range, image_domain', image_range'⟩ : spec α) : set (binary_condition α))
    = carrier := rfl
@[simp] lemma mem_mk (carrier : set (binary_condition α))
  (domain range : unary_spec α)
  (image_domain' : binary_condition.domain '' carrier = domain)
  (image_range' : binary_condition.range '' carrier = range)
  (c : binary_condition α) :
  c ∈ (⟨carrier, domain, range, image_domain', image_range'⟩ : spec α) ↔ c ∈ carrier := iff.rfl

@[simp] lemma mem_sup : c ∈ σ ⊔ τ ↔ c ∈ σ ∨ c ∈ τ := iff.rfl
@[simp] lemma mem_inf : c ∈ σ ⊓ τ ↔ c ∈ σ ∧ c ∈ τ := iff.rfl
@[simp] lemma mem_Sup {s : set $ spec α} : c ∈ Sup s ↔ ∃ σ ∈ s, c ∈ σ := mem_Union₂

@[simp] lemma mem_domain {a : support_condition α} {σ : spec α} :
  a ∈ σ.domain ↔ ∃ cond : binary_condition α, cond ∈ σ ∧ cond.domain = a :=
by simp_rw [←image_domain, mem_image, set_like.mem_coe]

@[simp] lemma mem_range {a : support_condition α} {σ : spec α} :
  a ∈ σ.range ↔ ∃ cond : binary_condition α, cond ∈ σ ∧ cond.range = a :=
by simp_rw [←image_range, mem_image, set_like.mem_coe]

lemma mem_domain_of_mem {c : binary_condition α} {σ : spec α} :
  c ∈ σ → binary_condition.domain c ∈ σ.domain :=
by { intro h, rw mem_domain, exact ⟨_, h, rfl⟩ }

lemma mem_range_of_mem {c : binary_condition α} {σ : spec α} :
  c ∈ σ → binary_condition.range c ∈ σ.range :=
by { intro h, rw mem_range, exact ⟨_, h, rfl⟩ }

lemma inl_mem_domain {σ : spec α} {a : atom × atom} {A : extended_index α} :
  (inl a, A) ∈ σ → (inl a.1, A) ∈ σ.domain :=
by { intro h, rw mem_domain, exact ⟨_, h, rfl⟩ }

lemma inr_mem_domain {σ : spec α} {N : near_litter × near_litter} {A : extended_index α} :
  (inr N, A) ∈ σ → (inr N.1, A) ∈ σ.domain :=
by { intro h, rw mem_domain, exact ⟨_, h, rfl⟩ }

lemma inl_mem_range {σ : spec α} {a : atom × atom} {A : extended_index α} :
  (inl a, A) ∈ σ → (inl a.2, A) ∈ σ.range :=
by { intro h, rw mem_range, exact ⟨_, h, rfl⟩ }

lemma inr_mem_range {σ : spec α} {N : near_litter × near_litter} {A : extended_index α} :
  (inr N, A) ∈ σ → (inr N.2, A) ∈ σ.range :=
by { intro h, rw mem_range, exact ⟨_, h, rfl⟩ }

@[simp] lemma domain_bot : (⊥ : spec α).domain = ∅ := rfl
@[simp] lemma range_bot : (⊥ : spec α).range = ∅ := rfl

@[simp] lemma domain_sup (σ τ : spec α) : (σ ⊔ τ).domain = σ.domain ∪ τ.domain := rfl
@[simp] lemma range_sup (σ τ : spec α) : (σ ⊔ τ).range = σ.range ∪ τ.range := rfl

lemma domain_Sup (S : set (spec α)) : (Sup S).domain = ⋃ s ∈ S, domain s := rfl
lemma range_Sup (S : set (spec α)) : (Sup S).range = ⋃ s ∈ S, spec.range s := rfl

instance : has_singleton (binary_condition α) (spec α) :=
⟨λ c, ⟨{c}, {c.domain}, {c.range}, image_singleton, image_singleton⟩⟩

@[simp] lemma mem_singleton : c ∈ ({d} : spec α) ↔ c = d := iff.rfl
@[simp] lemma coe_singleton : (({c} : spec α) : set $ binary_condition α) = {c} := rfl
@[simp] lemma domain_singleton : ({c} : spec α).domain = {c.domain} := rfl
@[simp] lemma range_singleton : ({c} : spec α).range = {c.range} := rfl

instance : has_inv (spec α) :=
⟨λ σ, { carrier := σ⁻¹,
  domain := σ.range,
  range := σ.domain,
  image_domain' := by rw [←image_range, ←image_inv, image_comm binary_condition.domain_inv,
    image_image],
  image_range' := by rw [←image_domain, ←image_inv, image_comm binary_condition.range_inv,
    image_image] }⟩

@[simp] lemma inv_mk (carrier domain range image_domain image_range) :
  (⟨carrier, domain, range, image_domain, image_range⟩ : spec α)⁻¹ =
    ⟨carrier⁻¹, range, domain,
      by rw [←image_range, ←image_inv, image_comm binary_condition.domain_inv, image_image],
      by rw [←image_domain, ←image_inv, image_comm binary_condition.range_inv, image_image]⟩ := rfl

instance : has_involutive_inv (spec α) :=
{ inv := has_inv.inv,
  inv_inv := by { rintro ⟨_, _, _, _, _⟩, simp } }

@[simp] lemma mem_inv : c ∈ σ⁻¹ ↔ c⁻¹ ∈ σ := iff.rfl
@[simp] lemma coe_inv (σ : spec α) : (↑(σ⁻¹) : set $ binary_condition α) = σ⁻¹ := rfl
@[simp] lemma domain_inv (σ : spec α) : σ⁻¹.domain = σ.range := rfl
@[simp] lemma range_inv (σ : spec α) : σ⁻¹.range = σ.domain := rfl

@[simp] lemma inl_mem_inv (σ : spec α) (a : atom × atom) (A : extended_index α) :
  (inl a, A) ∈ σ⁻¹ ↔ (inl a.swap, A) ∈ σ :=
mem_inv

@[simp] lemma inr_mem_inv (σ : spec α) (N : near_litter × near_litter) (A : extended_index α) :
  (inr N, A) ∈ σ⁻¹ ↔ (inr N.swap, A) ∈ σ :=
mem_inv

lemma Sup_inv (S : set (spec α)) : (Sup S)⁻¹ = Sup (has_inv.inv '' S) :=
sorry

end spec

namespace struct_perm
variables {π : struct_perm α} {σ ρ : spec α}

/-- A structural permutation *satisfies* a condition `⟨⟨x, y⟩, A⟩` if `π_A(x) = y`. -/
def satisfies_cond (π : struct_perm α) (c : binary_condition α) :=
c.fst.elim
  (λ atoms, derivative c.snd π • atoms.fst = atoms.snd)
  (λ Ns, derivative c.snd π • Ns.fst = Ns.snd)

@[simp] lemma satisfies_cond_atoms (a b : atom) (A : extended_index α) :
  π.satisfies_cond ⟨inl ⟨a, b⟩, A⟩ ↔ derivative A π • a = b :=
iff.rfl

@[simp] lemma satisfies_cond_near_litters (M N : near_litter) (A : extended_index α) :
  π.satisfies_cond ⟨inr ⟨M, N⟩, A⟩ ↔ derivative A π • M = N :=
iff.rfl

/-- A structural permutation *satisfies* a specification if for all conditions `⟨⟨x, y⟩, A⟩` in the
specification, we have `π_A(x) = y`. -/
def satisfies (π : struct_perm α) (σ : spec α) : Prop := ∀ ⦃c⦄, c ∈ σ → π.satisfies_cond c

lemma satisfies.mono (h : σ ≤ ρ) (hρ : π.satisfies ρ) : π.satisfies σ := λ c hc, hρ $ h hc

/-- There is an injection from the type of structural permutations to the type of specifications,
in such a way that any structural permutation satisfies its specification. We construct this
specification by simply drawing the graph of the permutation on atoms and near-litters. -/
def to_spec (π : struct_perm α) : spec α :=
spec.equiv_set.symm $
  range (λ x : atom × extended_index α, ⟨inl ⟨x.fst, derivative x.snd π • x.fst⟩, x.snd⟩) ∪
  range (λ x : near_litter × extended_index α, ⟨inr ⟨x.fst, derivative x.snd π • x.fst⟩, x.snd⟩)

/-- Any structural permutation satisfies its own specification. -/
lemma satisfies_to_spec (π : struct_perm α) : π.satisfies π.to_spec :=
begin
  rintro ⟨⟨x, y⟩ | ⟨x, y⟩, A⟩ (hxy | hxy);
  simpa only [mem_range, prod.mk.inj_iff, prod.exists, exists_eq_right, exists_eq_left,
    sum.elim_inl, sum.elim_inr, false_and, exists_false] using hxy,
end

/-- The map from structural permutations to their specifications is injective. -/
lemma to_spec_injective :∀ (α : type_index), injective (@to_spec _ α)
| ⊥ := λ σ τ h, ext_bot _ _ $ λ a, begin
    simp only [to_spec, embedding_like.apply_eq_iff_eq, ext_iff] at h,
    simpa only [prod.mk.inj_iff, exists_eq_right, derivative_nil, exists_eq_left, exists_false,
      or_false, eq_self_iff_true, true_iff, prod.exists, mem_union_eq, mem_range, iff_true]
        using h ⟨inl ⟨a, τ • a⟩ , path.nil⟩,
  end
| (α : Λ) := λ σ τ h, of_coe.injective $ funext $ λ β, funext $ λ hβ, to_spec_injective β $
    set_like.ext $ begin
    rintro ⟨x_fst, x_snd⟩,
    sorry
    -- simp only [to_spec, embedding_like.apply_eq_iff_eq, ext_iff] at ⊢ h,
    -- specialize h ⟨x_fst, (@path.cons type_index con_nf.quiver ↑α ↑α β path.nil hβ).comp x_snd⟩,
    -- simp only [spec.equiv_set, prod.mk.inj_iff, exists_eq_right, prod.exists, mem_union_eq, mem_range, equiv.coe_fn_symm_mk, ←derivative_derivative, derivative_cons_nil] at h ⊢,
    -- cases x_fst,
    -- exact h,
    -- rw ext_iff at h ⊢,
    -- simp only [prod.exists, mem_union_eq, mem_set_of_eq] at h ⊢,
    -- rintro ⟨x_fst, x_snd⟩,
    -- specialize h ⟨x_fst, (@path.cons type_index con_nf.quiver ↑α ↑α β path.nil hβ).comp x_snd⟩,
    -- simp_rw derivative_derivative,
    -- simpa only [derivative_cons_nil, prod.mk.inj_iff, exists_false, exists_eq_right, false_or]
    --   using h,
  end
using_well_founded { dec_tac := `[assumption] }

end struct_perm

/-- We can extend any support condition to one of a higher proper type index `α` by providing a path
connecting the old extended index up to `α`. -/
def support_condition.extend_path (c : support_condition β) (A : path (α : type_index) β) :
  support_condition α := ⟨c.fst, A.comp c.snd⟩

namespace binary_condition

/-- We can extend any binary condition to one of a higher proper type index `α` by providing a path
connecting the old extended index up to `α`. -/
def extend_path (c : binary_condition β) (A : path α β) : binary_condition α :=
⟨c.fst, A.comp c.snd⟩

@[simp] lemma extend_path_inv (c : binary_condition β) (A : path α β) :
  c⁻¹.extend_path A = (c.extend_path A)⁻¹ := rfl

end binary_condition

namespace unary_spec

/-- We can lower a unary specification to a lower proper type index with respect to a path
`A : α ⟶ β` by only keeping support conditions whose paths begin with `A`. -/
def lower (σ : unary_spec α) (A : path α β) : unary_spec β := {c | c.extend_path A ∈ σ}

/-- Lowering along the empty path does nothing. -/
@[simp] lemma lower_nil (σ : unary_spec α) : σ.lower path.nil = σ :=
by simp only
  [unary_spec.lower, support_condition.extend_path, path.nil_comp, prod.mk.eta, set_of_mem_eq]

/-- The lowering map is functorial. -/
@[simp] lemma lower_lower (σ : unary_spec α) (A : path α β) (B : path β γ) :
  (σ.lower A).lower B = σ.lower (A.comp B) :=
by simp only [unary_spec.lower, support_condition.extend_path, mem_set_of_eq, path.comp_assoc]

@[simp] lemma lower_union (σ τ : unary_spec α) (A : path α β) :
  (σ ∪ τ).lower A = σ.lower A ∪ τ.lower A :=
by ext ⟨x | x, y⟩; simp only [unary_spec.lower, mem_union_eq, mem_set_of_eq]

@[simp] lemma lower_sUnion (c : set (unary_spec α)) (A : path α β) :
  lower (⋃₀ c) A = ⋃ s ∈ c, lower s A :=
by { ext, simp only [lower, mem_Union, mem_set_of_eq, mem_sUnion] }

@[simp] lemma lower_Union {ι : Sort*} {f : ι → unary_spec α} (A : path α β) :
  lower (⋃ i, f i) A = ⋃ i, lower (f i) A :=
by { ext, simp only [lower, mem_Union, mem_set_of_eq] }

end unary_spec

namespace spec
variables {A : path α β} {σ : spec α} {c : binary_condition β}

/-- We can lower a specification to a lower proper type index with respect to a path
`A : α ⟶ β` by only keeping binary conditions whose paths begin with `A`. -/
def lower (A : path α β) (σ : spec α) : spec β := equiv_set.symm {c | c.extend_path A ∈ σ}

@[simp] lemma coe_lower (A : path α β) (σ : spec α) :
  (σ.lower A : set (binary_condition β)) = {c | c.extend_path A ∈ σ} := rfl

@[simp] lemma mem_lower : c ∈ σ.lower A ↔ c.extend_path A ∈ σ := iff.rfl

/-- Lowering along the empty path does nothing. -/
@[simp] lemma lower_nil (σ : spec α) : σ.lower path.nil = σ :=
set_like.ext $ λ _, by simp only [binary_condition.extend_path, path.nil_comp, prod.mk.eta,
  mem_lower]

/-- The lowering map is functorial. -/
@[simp] lemma lower_lower (A : path α β) (B : path β γ) (σ : spec α) :
  (σ.lower A).lower B = σ.lower (A.comp B) :=
set_like.ext $ λ _, by simp only [binary_condition.extend_path, path.comp_assoc, mem_lower]

@[simp] lemma lower_sup (σ τ : spec α) (A : path α β) : (σ ⊔ τ).lower A = σ.lower A ⊔ τ.lower A :=
set_like.ext $ λ _, by simp only [mem_lower, mem_sup]

@[simp] lemma lower_inv (σ : spec α) (A : path α β) : σ⁻¹.lower A = (σ.lower A)⁻¹ :=
set_like.ext $ λ _, by simp

end spec

/-- Lowering a specification corresponds exactly to forming the derivative of the corresponding
structural permutation. -/
lemma struct_perm.spec_lower_eq_derivative (π : struct_perm α) (A : path α β) :
  π.to_spec.lower A = (struct_perm.derivative A π).to_spec :=
begin
  ext,
  simp only [spec.mem_lower, struct_perm.to_spec, mem_union_eq, mem_range, prod.exists,
    mem_set_of_eq],
  cases c,
  simp only [binary_condition.extend_path, prod.mk.inj_iff, exists_eq_right],
  sorry
  -- rw derivative_derivative,
end

namespace spec
variables {A : path α β} {σ : spec α}

/-- A specification is total if it specifies where every element in its domain goes. -/
def total (σ : spec α) : Prop := ∀ c, c ∈ σ.domain

/-- A specification is co-total if it specifies where every element in its codomain came from. -/
def co_total (σ : spec α) : Prop := ∀ c, c ∈ σ.range

@[simp] lemma total_inv : σ⁻¹.total ↔ σ.co_total := by simp only [total, co_total, domain_inv]
@[simp] lemma co_total_inv : σ⁻¹.co_total ↔ σ.total := by simp only [total, co_total, range_inv]

alias total_inv ↔ total.of_inv co_total.inv
alias co_total_inv ↔ co_total.of_inv total.inv

protected lemma total.lower (hσ : σ.total) : (σ.lower A).total :=
begin
  rintro c,
  obtain ⟨y, hyσ, hy⟩ := mem_domain.1 (hσ $ c.extend_path A),
  set z : binary_condition β := ⟨y.fst, c.snd⟩,
  refine mem_domain.2 ⟨z, _, prod.ext_iff.2 ⟨(prod.ext_iff.1 hy).1, rfl⟩⟩,
  suffices : y = z.extend_path A, -- probably can cut this
  { rwa this at hyσ },
  ext,
  { refl },
  unfold binary_condition.extend_path,
  dsimp only,
  exact congr_arg prod.snd hy,
end

protected lemma co_total.lower (hσ : σ.co_total) : (σ.lower A).co_total :=
begin
  rintro c,
  obtain ⟨y, hyσ, hy⟩ := mem_range.1 (hσ $ c.extend_path A),
  set z : binary_condition β := ⟨y.fst, c.snd⟩,
  refine mem_range.2 ⟨z, _, prod.ext_iff.2 ⟨(prod.ext_iff.1 hy).1, rfl⟩⟩,
  suffices : y = z.extend_path A, -- probably can cut this
  { rwa this at hyσ },
  ext,
  { refl },
  unfold binary_condition.extend_path,
  dsimp only,
  exact congr_arg prod.snd hy,
end

end spec
end

variables (α : Λ) [phase_2_core_assumptions α] [phase_2_positioned_assumptions α]
  [phase_2_assumptions α] (B : le_index α)

/--
Support conditions can be said to *constrain* each other in a number of ways. This is discussed
in the "freedom of action discussion".

1. `⟨L, A⟩ ≺ ⟨a, A⟩` when `a ∈ L` and `L` is a litter. We can say that an atom is constrained by the
    litter it belongs to.
2. `⟨N°, A⟩ ≺ ⟨N, A⟩` when `N` is a near-litter not equal to its corresponding litter `N°`.
3. `⟨a, A⟩ ≺ ⟨N, A⟩` for all `a ∈ N ∆ N°`.
4. `⟨y, B : (γ < β) : A⟩ ≺ ⟨L, A⟩` for all paths `A : α ⟶ β` and `γ, δ < β` with `γ ≠ δ`,
    and `L = f_{γ,δ}^A(x)` for some `x ∈ τ_{γ:A}`, where `⟨y, B⟩` lies in the designated support
    `S_x` of `x`.
-/
@[mk_iff] inductive constrains : support_condition B → support_condition B → Prop
| mem_litter (L : litter) (a ∈ litter_set L) (A : extended_index B) :
    constrains ⟨inr L.to_near_litter, A⟩ ⟨inl a, A⟩
| near_litter (N : near_litter) (hN : litter_set N.fst ≠ N.snd) (A : extended_index B) :
    constrains ⟨inr N.fst.to_near_litter, A⟩ ⟨inr N, A⟩
| symm_diff (N : near_litter) (a ∈ litter_set N.fst ∆ N.snd) (A : extended_index B) :
    constrains ⟨inl a, A⟩ ⟨inr N, A⟩
| f_map ⦃β : Λ⦄ ⦃γ : type_index⦄ ⦃δ : Λ⦄ (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ)
    (A : path (B : type_index) β)
    (t : tangle_path (lt_index.mk' hγ (B.path.comp A) : le_index α))
    (c ∈ (designated_support_path t).carrier) :
    constrains
      ⟨c.fst, path.comp (A.cons hγ) c.snd⟩
      ⟨inr (f_map_path hγ hδ t).to_near_litter,
        (A.cons (coe_lt_coe.mpr hδ)).cons (bot_lt_coe _)⟩

/-! We declare new notation for the "constrains" relation on support conditions. -/
infix ` ≺ `:50 := constrains _ _

/-- The `≺` relation is well-founded. By the conditions on orderings, if we have `⟨x, A⟩ ≺ ⟨y, B⟩`,
then `x < y` in `µ`, under the `to_tangle_path` or `typed_singleton_path` maps. -/
lemma constrains_wf : well_founded (constrains α B) := sorry

instance : has_well_founded (support_condition B) := ⟨constrains α B, constrains_wf α B⟩

variables {α B}

/-- A litter and extended index is *flexible* if it is not of the form `f_{γ,δ}^A(x)` for some
`x ∈ τ_{γ:A}` with conditions defined as above. Hence, it is not constrained by anything. -/
def flexible (L : litter) (A : extended_index B) : Prop :=
∀ ⦃β : Λ⦄ ⦃γ : type_index⦄ ⦃δ : Λ⦄
  (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ) (C : path (B : type_index) β)
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp C)) : le_index α)),
    L ≠ f_map_path hγ hδ t ∨ A ≠ (C.cons $ coe_lt_coe.mpr hδ).cons (bot_lt_coe _)

@[simp] lemma mk_flexible_litters (A : extended_index B) : #{L : litter // flexible L A} = #μ :=
begin
  by_cases (B : type_index) = ⊥,
  { have H : ∀ (L : litter), flexible L A,
    { intro L,
      unfold flexible,
      intros β γ δ hγ hδ hγδ C,
      have hγB := lt_of_lt_of_le hγ (le_of_path C),
      exfalso,
      rw h at hγB,
      exact not_lt_bot hγB },
    rw ← mk_litter,
    rw cardinal.eq,
    exact ⟨⟨subtype.val, (λ L, ⟨L, H L⟩), (λ S, subtype.eta _ _), (λ L, rfl)⟩⟩ },
  refine le_antisymm _ _,
  { rw ← mk_litter,
    exact cardinal.mk_subtype_le _ },
  { rw cardinal.le_def,
    rw ← ne.def at h,
    rw with_bot.ne_bot_iff_exists at h,
    obtain ⟨B', hB'⟩ := h,
    refine ⟨⟨λ x, ⟨⟨⟨⊥, B'⟩, x⟩, λ β γ δ hγ hδ hγδ C t, _⟩, _⟩⟩,
    { left,
      intro h,
      sorry,
      -- have := f_map_fst ⊥ (proper_lt_index.mk' hδ (B.path.comp C)).index t,
      -- unfold f_map_path at h,
      --rw ← h at this,
    },
    { sorry } }
end
local attribute [irreducible] litter

/-- A litter and extended index is flexible only if it is not constrained by anything. -/
lemma unconstrained_of_flexible (L : litter) (A : extended_index B) (h : flexible L A) :
∀ c, ¬ c ≺ ⟨inr L.to_near_litter, A⟩ :=
begin
  intros c hc,
  rw constrains_iff at hc,
  obtain ⟨L, a, ha, A', hc, hA'⟩ | ⟨N, hN, A', hc, hA'⟩ |
    ⟨N, a, ha, A', hc, hA'⟩ | ⟨β, δ, γ, hγ, hδ, hγδ, A', t, ht, c', hc, h'⟩ := hc,
  { cases hA' },
  { obtain ⟨hLN, hAA'⟩ := prod.mk.inj_iff.1 hA',
    simp only at hLN,
    rw ← hLN at hN,
    apply hN, refl },
  { obtain ⟨hLN, hAA'⟩ := prod.mk.inj_iff.1 hA',
    suffices : litter_set N.1 = N.2,
    { have that := symm_diff_self (litter_set N.1),
      nth_rewrite 1 this at that,
      rw that at ha, exact ha },
    simp only at hLN,
    rw ← hLN, refl },
    unfold extended_index at A,
  specialize h hγ hδ hγδ _ t,
  obtain ⟨hLN, hAA'⟩ := prod.mk.inj_iff.1 h',
  simp only at hLN,
  cases h,
  { exact h (congr_arg sigma.fst hLN) },
  { exact h hAA' }
end

namespace unary_spec
variables (B)

/-- A unary specification is *support-closed* if whenever `⟨f_{γ,δ}^A(x), A⟩ ∈ σ`, `S_{γ:A}`
supports `x`. -/
def support_closed (σ : unary_spec B) : Prop :=
∀ ⦃β : Λ⦄ ⦃γ : type_index⦄ ⦃δ : Λ⦄ (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ)
    (A : path (B : type_index) β)
    (t : tangle_path (lt_index.mk' hγ (B.path.comp A) : le_index α)),
  (⟨inr (f_map_path hγ hδ t).to_near_litter, (A.cons $ coe_lt_coe.mpr hδ).cons $ bot_lt_coe _⟩
      : support_condition B) ∈ σ →
      supports (allowable_path (lt_index.mk' hγ (B.path.comp A) : le_index α))
        (σ.lower (A.cons hγ)) t

end unary_spec

namespace spec
variables {β : type_index}

/-!
We now set out the allowability conditions for specifications of permutations.
These are collected in the structure `allowable`, which may be treated as a proposition.
We say a specification is allowable if `allowable` holds.
-/

/--
A specification is *one-to-one* on a particular path `A` if
* `⟨a, b₁⟩, ⟨a, b₂⟩ ∈ σ` implies `b₁ = b₂`,
* `⟨a₁, b⟩, ⟨a₂, b⟩ ∈ σ` implies `a₁ = a₂`,
where `a, b` may be either atoms or near-litters.
-/
@[mk_iff] structure one_to_one_forward_path (σ : spec β) (A : extended_index β) : Prop :=
(atom        : ∀ b, {a | (⟨inl ⟨a, b⟩, A⟩ : binary_condition β) ∈ σ}.subsingleton)
(near_litter : ∀ N, {M | (⟨inr ⟨M, N⟩, A⟩ : binary_condition β) ∈ σ}.subsingleton)

/-- A specification is one-to-one if it is one-to-one on all paths. -/
def one_to_one_forward (σ : spec β) : Prop := ∀ A, σ.one_to_one_forward_path A

/-- If we lower a one-to-one specification along a path, it is still one-to-one.
This is one part of `total-1-1-restriction` in the blueprint. -/
lemma lower_one_to_one {β : type_index} (σ : spec B) (A : path (B : type_index) β) :
  σ.one_to_one_forward → (σ.lower A).one_to_one_forward :=
begin
  refine (λ ho he, ⟨_, _⟩); intros hz ha hb hc hd;  dsimp at hb hd,
  { exact (ho $ A.comp he).atom hz (by assumption) (by assumption) },
  { exact (ho $ A.comp he).near_litter hz (by assumption) (by assumption) }
end

/-- A specification is the graph of a structural permutation if it is one-to-one and total.
This is one direction of implication of `total-1-1-gives-perm` on the blueprint - the other
direction may not be needed. We may also require `hσ₃ : σ.co_total` or
`hσ₄ : σ⁻¹.one_to_one_forward` - but hopefully this isn't needed. -/
lemma graph_struct_perm (σ : spec B) (hσ₁ : σ.one_to_one_forward) (hσ₂ : σ.total) :
  ∃ (π : struct_perm B), π.to_spec = σ := sorry

/-- The allowability condition on atoms.
In an absent litter, we must specify only `< κ`-many atoms.
In a present litter, we can specify either `< κ`-many atoms and they are mapped to the right place,
or all of the atoms in the litter, and their range is exactly the image of the litter.
Note that the `small` constructor does not depend on whether the litter is present or absent. -/
@[mk_iff] inductive atom_cond (σ : spec β) (L : litter) (A : extended_index β) : Prop
| all
    (L' : near_litter) (hL : (⟨inr ⟨L.to_near_litter, L'⟩, A⟩ : binary_condition β) ∈ σ)
    (atom_map : litter_set L → atom) :
  (∀ a ∈ litter_set L, (⟨inl ⟨a, atom_map ⟨a, ‹_›⟩⟩, A⟩ : binary_condition β) ∈ σ) →
  L'.snd.val = range atom_map → atom_cond
| small_out
    (hL : (inr L.to_near_litter, A) ∉ σ.domain) :
  small {a ∈ litter_set L | (⟨inl a, A⟩ : support_condition β) ∈ σ.domain} → atom_cond
| small_in
    (L' : near_litter) (hL : (inr (L.to_near_litter, L'), A) ∈ σ) :
  small {a ∈ litter_set L | (⟨inl a, A⟩ : support_condition β) ∈ σ.domain} →
  (∀ ⦃a b : atom⦄ (hin : (inl (a, b), A) ∈ σ), a ∈ litter_set L ↔ b ∈ L'.snd.val) → atom_cond

/-- The allowability condition on near-litters.
If a near-litter is present, so are its litter and all atoms in the symmetric difference, and it is
mapped to the right place. -/
def near_litter_cond (σ : spec β) (N₁ N₂ : near_litter) (A : extended_index β) : Prop :=
(⟨inr ⟨N₁, N₂⟩, A⟩ : binary_condition β) ∈ σ →
  ∃ M, (⟨inr ⟨N₁.fst.to_near_litter, M⟩, A⟩ : binary_condition β) ∈ σ ∧
  ∃ (symm_diff : litter_set N₁.fst ∆ N₁.snd → atom),
    (∀ a : litter_set N₁.fst ∆ N₁.snd, (⟨inl ⟨a, symm_diff a⟩, A⟩ : binary_condition β) ∈ σ) ∧
  N₂.snd.val = M.snd.val ∆ range symm_diff

variables (B) {σ : spec B} {A : extended_index B}

/-- This is the allowability condition for flexible litters of a given extended index.
Either all flexible litters are in both the domain and range (`all`), or there are `μ`-many not in
the domain and `μ`-many not in the range. -/
@[mk_iff] inductive flexible_cond (σ : spec B) (A : extended_index B) : Prop
| co_large :
  #μ = #{L | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.domain} →
  #μ = #{L | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.range} →
  flexible_cond
| all :
  (∀ L, flexible L A → (inr L.to_near_litter, A) ∈ σ.domain) →
  (∀ L, flexible L A → (inr L.to_near_litter, A) ∈ σ.range) →
  flexible_cond

-- TODO: This instance feels unnecessary and really shouldn't be needed.
-- Is there a better way of writing `non_flexible_cond` so that the instance is inferred?
instance (β : Λ) (γ : type_index) (hγ : γ < β) (A : path (B : type_index) β) :
mul_action (allowable_path (le_index.cons ⟨β, B.path.comp A⟩ hγ))
  (tangle_path (lt_index.mk' hγ (B.path.comp A) : le_index α)) :=
core_tangle_data.allowable_action

/-- The allowability condition on non-flexible litters.
Whenever `σ` contains some condition `⟨⟨f_{γ,δ}^A(g), N⟩, [-1,δ,A]⟩`, then every allowable
permutation extending `σ` has `N = f_{γ,δ}^A(ρ • g)`. -/
def non_flexible_cond (σ : spec B) : Prop :=
∀ ⦃β : Λ⦄ ⦃γ : type_index⦄ ⦃δ : Λ⦄ (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ) (N : near_litter)
  (A : path (B : type_index) β)
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp A)) : le_index α)),
  (⟨inr ⟨(f_map_path hγ hδ t).to_near_litter,
    N⟩, (A.cons $ coe_lt_coe.mpr hδ).cons $ bot_lt_coe _⟩ : binary_condition B) ∈ σ →
  ∀ (ρ : allowable_path B), ρ.to_struct_perm.satisfies σ →
  N = (f_map_path hγ hδ $ (ρ.derivative_comp B A).derivative hγ • t).to_near_litter

/-- A specification is *allowable* in the forward direction if it satisfies the following
conditions. -/
structure forward_allowable (σ : spec B) : Prop :=
(one_to_one : σ.one_to_one_forward)
(atom_cond : ∀ L A, σ.atom_cond L A)
(near_litter_cond : ∀ N₁ N₂ A, σ.near_litter_cond N₁ N₂ A)
(non_flexible_cond : σ.non_flexible_cond B)
(support_closed : σ.domain.support_closed B)

/-- A specification is *allowable* if it is allowable in the forward and backward directions. -/
protected structure allowable (σ : spec B) : Prop :=
(forward : σ.forward_allowable B)
(backward : σ⁻¹.forward_allowable B)
(flexible_cond : ∀ A, σ.flexible_cond B A)

@[simp] lemma Union_eq_true {α : Type*} {p : Prop} {s : set α} (h : p) :
  (⋃ (h : p), s) = s :=
by { classical, rw Union_eq_if, rwa if_pos, }

@[simp] lemma Union_eq_false {α : Type*} {p : Prop} {s : set α} (h : ¬p) :
  (⋃ (h : p), s) = ∅ :=
by { classical, rw Union_eq_if, rwa if_neg, }

variables {B}

lemma flexible_cond.inv : σ.flexible_cond B A → σ⁻¹.flexible_cond B A
| (flexible_cond.co_large h₀ h₁) := flexible_cond.co_large (by rwa domain_inv) (by rwa range_inv)
| (flexible_cond.all h₀ h₁) := flexible_cond.all (by rwa domain_inv) (by rwa range_inv)

@[simp] lemma flexible_cond_inv : σ⁻¹.flexible_cond B A ↔ σ.flexible_cond B A :=
⟨λ h, by simpa only [inv_inv] using h.inv, flexible_cond.inv⟩

/-- The inverse of an allowable specification is allowable. -/
lemma allowable.inv (hσ : σ.allowable B) : σ⁻¹.allowable B :=
{ forward := hσ.backward,
  backward := by { rw inv_inv, exact hσ.forward },
  flexible_cond := λ A, (hσ.flexible_cond A).inv }

@[simp] lemma allowable_inv : σ⁻¹.allowable B ↔ σ.allowable B :=
⟨λ h, by simpa only [inv_inv] using h.inv, allowable.inv⟩

end spec

open spec

variables (B)

/-- An *allowable partial permutation* is a specification that is allowable as defined above. -/
def allowable_partial_perm := {σ : spec B // σ.allowable B}

variables {B}

namespace allowable_partial_perm

instance has_inv : has_inv (allowable_partial_perm B) := ⟨λ σ, ⟨σ.val⁻¹, σ.2.inv⟩⟩

@[simp] lemma val_inv (π : allowable_partial_perm B) : π⁻¹.val= π.val⁻¹ := rfl

instance : has_involutive_inv (allowable_partial_perm B) :=
subtype.val_injective.has_involutive_inv _ val_inv

end allowable_partial_perm

/-! We prove the restriction lemma: if `σ` is a partial allowable permutation, then so is `σ`
restricted to a lower path `A`. The proof should be mostly straightforward. The non-trivial bit is
the "co-large or all" on flexible litters: in a proper restriction, `μ`-many non-flexible litters
get freed up and become flexible, so if it was “all”, it becomes "co-large". -/

section lower
variables {σ : spec B} {β : Λ} (A : path (B : type_index) β) (hβ : (β : type_index) < B)

lemma lower_one_to_one_forward (hσ : σ.allowable B) : (σ.lower A).one_to_one_forward :=
spec.lower_one_to_one _ _ hσ.forward.one_to_one

lemma lower_atom_cond (hσ : σ.allowable B) (L C) : (σ.lower A).atom_cond L C :=
begin
  obtain ⟨N, atom_map, h1, h2, h3⟩ | ⟨hL, hsmall⟩ | ⟨N, hL, hsmall, hmaps⟩ :=
    hσ.forward.atom_cond L (A.comp C),
  { exact spec.atom_cond.all N atom_map h1 h2 h3 },
  refine spec.atom_cond.small_out _ _,
  { convert hL using 1,
    refine iff.to_eq _,
    simp_rw mem_domain,
    split; rintro ⟨⟨_ | ⟨x, y⟩, C⟩, hbin,  ⟨⟩⟩,
    { exact ⟨_, hbin, rfl⟩ },
    { exact ⟨(inr (L.to_near_litter, y), C), hbin, rfl⟩ } },
  swap,
  refine spec.atom_cond.small_in N hL _ hmaps,
  all_goals { simpa using hsmall },
end

lemma lower_near_litter_cond (hσ : σ.allowable B) (N₁ N₂ C) :
  (σ.lower A).near_litter_cond N₁ N₂ C :=
hσ.forward.near_litter_cond _ _ _

lemma flexible.of_comp (C : extended_index (⟨β, B.path.comp A⟩ : le_index α)) {L : litter} :
  flexible L (A.comp C) → flexible L C :=
begin
  intro hf,
  unfold flexible at hf ⊢,
  simp at hf ⊢,
  intros hb hd hg hgb hdb hdg hp htp,
  have h1 := hf hgb hdb hdg,
  --have h2 := h1 hp,
  sorry,
end

/-- Descending down a proper path `A`, `μ`-many litters become flexible. -/
--make C a parameter?
lemma lower_flexible_co_large (hβ : (B : type_index) ≠ β) :
  #{L : litter // ∃ (C : extended_index (⟨β, B.path.comp A⟩ : le_index α)),
    flexible L C ∧ ¬ flexible L (A.comp C)} = #μ :=
begin
  refine le_antisymm _ _,
  { rw ← mk_litter, exact cardinal.mk_subtype_le _ },
  sorry
end

lemma lower_flexible_cond (hσ : σ.allowable B) (C : extended_index β) :
  (σ.lower A).flexible_cond (le_index.mk β (B.path.comp A)) C :=
begin
  by_cases hβ : (B : type_index) = β,
  { obtain ⟨B_index, B⟩ := B,
    dsimp at *,
    subst hβ,
    rw [path_eq_nil A, spec.lower_nil σ],
    rw path.comp_nil,
    exact hσ.flexible_cond C },

  -- The existing proof has been modified and simplified into the following structure.

  obtain ⟨hdom, hrge⟩ | ⟨hdom, hrge⟩ := hσ.flexible_cond (A.comp C),
  { refine spec.flexible_cond.co_large _ _,
    { refine le_antisymm _ _,
      { rw hdom, refine cardinal.mk_subtype_mono _,
        -- This should be an approachable goal, solvable with `flexible.of_comp`.
        sorry },
      { rw ← mk_litter, exact cardinal.mk_subtype_le _ } },
    { -- Same thing here.
      sorry },
  },
  { refine spec.flexible_cond.co_large _ _,
    -- Why are these goals true?
    -- We shouldn't try to solve these without a firm understanding of the mathematical proof.
    -- It's possible the definition is not quite correct.
    sorry, sorry },

  /- { refine spec.flexible_cond.all _ _,
    { intros L hf,
      have hdom' := hdom L _,
      { unfold spec.lower,
        unfold binary_condition.extend_path,
        unfold spec.domain at hdom' ⊢,
        dsimp at hdom' ⊢,
        obtain ⟨x, hx_1, hx_2⟩ := hdom',
        refine ⟨⟨x.fst, C⟩,_,_⟩,
        { obtain ⟨atoms | Ns, he'⟩ := x,
          { unfold binary_condition.domain at hx_2,
            simp at hx_2,
            exfalso,
            exact hx_2  },
          { unfold binary_condition.domain at hx_2,
            simp at hx_2 ⊢,
            obtain ⟨hx_2,hx_3⟩ := hx_2,
            rw hx_3 at hx_1,
            exact hx_1 } },
        { unfold binary_condition.domain at hx_2 ⊢,
          simp at hx_2 ⊢,
          exact and.elim_left hx_2 } },
      {
        sorry
        -- exact flexible.of_comp _ _ _ L hf,
      } },
    { intros L hf,
      have hrge' := hrge L _,
      { unfold spec.lower,
        unfold binary_condition.extend_path,
        unfold spec.range at hrge' ⊢,
        dsimp at hrge' ⊢,
        obtain ⟨x, hx_1, hx_2⟩ := hrge',
        refine ⟨⟨x.fst, C⟩,_,_⟩,
        { obtain ⟨atoms | Ns, he'⟩ := x,
          { unfold binary_condition.range at hx_2,
            simp at hx_2,
            exfalso,
            exact hx_2 },
          { unfold binary_condition.range at hx_2,
            simp at hx_2 ⊢,
            obtain ⟨hx_2,hx_3⟩ := hx_2,
            rw hx_3 at hx_1,
            exact hx_1 } },
        { unfold binary_condition.range at hx_2 ⊢,
          simp at hx_2 ⊢,
          obtain ⟨hx_2,hx_3⟩ := hx_2,
          exact hx_2 } },
      {
        sorry
        -- exact flexible.of_comp _ _ _ L hf,
      } } }, -/
end

lemma lower_non_flexible_cond (hσ : σ.allowable B) :
  (σ.lower A).non_flexible_cond (le_index.mk β (B.path.comp A)) :=
begin
  unfold spec.non_flexible_cond,
  intros hb hg hd hgb hdb hgd hNl hp ht h1 hallp h2,

  unfold struct_perm.satisfies at h2,
  unfold struct_perm.satisfies_cond at h2,
  have h := h2 h1,
  simp at h,
  rw ← h,
  --repeat unpacked_coherence lemma,
  sorry,
end

lemma lower_domain_closed (hσ : σ.allowable B) :
  (σ.lower A).domain.support_closed (le_index.mk β (B.path.comp A)) :=
begin
  intros hb hg hd hgb hdb hgd p t h1 π hsup,
  sorry
end

namespace spec

protected lemma allowable.lower (hσ : σ.allowable B) ⦃β : Λ⦄ (A : path (B : type_index) β)
  (hβ : (β : type_index) < B) :
  (σ.lower A).allowable (le_index.mk β (B.path.comp A)) :=
{ forward :=
  { one_to_one := lower_one_to_one_forward A hσ,
    atom_cond := lower_atom_cond A hσ,
    near_litter_cond := lower_near_litter_cond A hσ,
    non_flexible_cond := lower_non_flexible_cond A hσ,
    support_closed := lower_domain_closed A hσ },
  backward :=
  { one_to_one := by { rw ←lower_inv, exact lower_one_to_one_forward A hσ.inv },
    atom_cond := by { rw ←lower_inv, exact lower_atom_cond A hσ.inv },
    near_litter_cond := by { rw ←lower_inv, exact lower_near_litter_cond A hσ.inv },
    non_flexible_cond := by { rw ←lower_inv, exact lower_non_flexible_cond A hσ.inv },
    support_closed := by { rw ←lower_inv, exact lower_domain_closed A hσ.inv } },
  flexible_cond := lower_flexible_cond A hσ }

end spec
end lower

open spec

variables (B)

/-- We say that *freedom of action* holds along a path `B` if any partial allowable permutation `σ`
admits an allowable permutation `π` extending it. -/
def freedom_of_action : Prop :=
∀ σ : allowable_partial_perm B, ∃ π : allowable_path B, π.to_struct_perm.satisfies σ.val

variables {B}

/-- If an allowable partial permutation `σ` supports some `α`-tangle `t`, any permutations extending
`σ` must map `t` to the same value.
TODO: Factor out the lemma: if two allowable partial perms agree on the support of t, they send
it to the same place.
TODO: Can this be proven only assuming the permutations are structural? -/
lemma eq_of_supports (σ : allowable_partial_perm B) (t : tangle_path B)
  (ht : supports (allowable_path B) σ.val.domain t) (π₁ π₂ : allowable_path B)
  (hπ₁ : π₁.to_struct_perm.satisfies σ.val) (hπ₂ : π₂.to_struct_perm.satisfies σ.val) :
  π₁ • t = π₂ • t := sorry

/-- The action lemma. If freedom of action holds, and `σ` is any allowable partial permutation
that supports some `α`-tangle `t`, then there exists a unique `α`-tangle `σ(t)` such that every
allowable permutation `π` extending `σ` maps `t` to `σ(t)`.

Proof: Freedom of action gives some extension `π`, and hence some candidate value; the support
condition implies that any two extensions agree. Use the above lemma for the second part. -/
lemma exists_tangle_of_supports (σ : allowable_partial_perm B) (t : tangle_path B)
  (foa : freedom_of_action B) (ht : supports (allowable_path B) σ.val.domain t) :
  ∃ s, ∀ π : allowable_path B, π.to_struct_perm.satisfies σ.val → π • t = s :=
⟨(foa σ).some • t, λ π₁ hπ₁, eq_of_supports σ t ht π₁ (foa σ).some hπ₁ (foa σ).some_spec⟩

namespace allowable_partial_perm
variables {B}

/--
We now define a preorder on partial allowable permutations.
`σ ≤ ρ` (written `σ ⊑ ρ` in the blueprint) means:

* `σ` is a subset of `ρ`;
* if `ρ` has any new `A`-flexible litter, then it has all (in both domain and range);
* within each litter, if `ρ.domain` has any new atom, then it must have all
    atoms in that litter (and hence must also have the litter), and dually for the range.

Note that the second condition is exactly the condition in `spec.flexible_cond.all`.
-/
structure perm_le (σ ρ : allowable_partial_perm B) : Prop :=
(le : σ.val ≤ ρ.val)
(all_flex_domain (L : litter) (N : near_litter) (A : extended_index B) (hL : flexible L A)
  (hσ : (⟨inr ⟨L.to_near_litter, N⟩, A⟩ : binary_condition B) ∉ σ.val)
  (hρ : (⟨inr ⟨L.to_near_litter, N⟩, A⟩ : binary_condition B) ∈ ρ.val) :
  (∀ L', flexible L' A →
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ ρ.val.domain ∧
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ ρ.val.range))
(all_flex_range (L : litter) (N : near_litter) (A : extended_index B) (hL : flexible L A)
  (hσ : (⟨inr ⟨N, L.to_near_litter⟩, A⟩ : binary_condition B) ∉ σ.val)
  (hρ : (⟨inr ⟨N, L.to_near_litter⟩, A⟩ : binary_condition B) ∈ ρ.val) :
  (∀ L', flexible L' A →
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ ρ.val.domain ∧
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ ρ.val.range))
(all_atoms_domain (a b : atom) (L : litter) (ha : a ∈ litter_set L) (A : extended_index B)
  (hσ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∉ σ.val)
  (hρ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∈ ρ.val) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨c, d⟩, A⟩ : binary_condition B) ∈ ρ.val)
(all_atoms_range (a b : atom) (L : litter) (ha : b ∈ litter_set L) (A : extended_index B)
  (hσ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∉ σ.val)
  (hρ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∈ ρ.val) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨d, c⟩, A⟩ : binary_condition B) ∈ ρ.val)

instance has_le : has_le (allowable_partial_perm B) := ⟨perm_le⟩

/-! We now prove that the claimed preorder really is a preorder. -/

lemma extends_refl (σ : allowable_partial_perm B) : σ ≤ σ :=
⟨subset.rfl,
 λ _ _ _ _ h1 h2, by cases h1 h2,
 λ _ _ _ _ h1 h2, by cases h1 h2,
 λ _ _ _ _ _ h1 h2, by cases h1 h2,
 λ _ _ _ _ _ h1 h2, by cases h1 h2⟩

lemma extends_trans (ρ σ τ : allowable_partial_perm B) (h₁ : ρ ≤ σ) (h₂ : σ ≤ τ) : ρ ≤ τ :=
begin
  obtain ⟨hsub, hflx_domain, hflx_range, hatom_domain, hatom_range⟩ := h₁,
  obtain ⟨hsub', hflx_domain', hflx_range', hatom_domain', hatom_range'⟩ := h₂,
  refine ⟨hsub.trans hsub', λ L N A hLA hnin hin, _, λ L N A hLA hnin hin, _,
    λ a b L hab A hnin hin, _, λ a b L hab A hnin hin, _⟩,
  { by_cases (inr (L.to_near_litter, N), A) ∈ σ.val,
    { sorry
      -- exact λ l hla,
      --   ⟨image_subset binary_condition.domain hsub' (hflx_domain L N A hLA hnin h l hla).1,
      --   image_subset binary_condition.range hsub' (hflx_domain L N A hLA hnin h l hla).2⟩
      },
    { exact hflx_domain' L N A hLA h hin } },
  { by_cases (inr (N, L.to_near_litter), A) ∈ σ.val,
    { sorry
      -- exact λ l hla,
      --   ⟨image_subset binary_condition.domain hsub' (hflx_range L N A hLA hnin h l hla).1,
      --   image_subset binary_condition.range hsub' (hflx_range L N A hLA hnin h l hla).2⟩
      },
    { exact hflx_range' L N A hLA h hin } },
  { by_cases (inl (a, b), A) ∈ σ.val,
    { intros c hc,
      obtain ⟨d, hd⟩ := hatom_domain a b L hab A hnin h c hc,
      refine ⟨d, hsub' hd⟩ },
    { exact hatom_domain' a b L hab A h hin } },
  { by_cases (inl (a, b), A) ∈ σ.val,
    { intros c hc,
      obtain ⟨d, hd⟩ := hatom_range a b L hab A hnin h c hc,
      refine ⟨d, hsub' hd⟩ },
    { exact hatom_range' a b L hab A h hin } }
end

instance : preorder (allowable_partial_perm B) :=
{ le := perm_le,
  le_refl := extends_refl,
  le_trans := extends_trans }

/-- A condition required later. -/
lemma inv_mono : monotone (@has_inv.inv (allowable_partial_perm B) _) :=
begin
  rintro σ τ ⟨h1, h2, h3, h4, h5⟩,
  refine ⟨λ x h, h1 h,
          λ L N hLA hnin hin L' A' hLA', _,
          λ L N hLA hnin hin L' A' hLA', _,
          λ a b, h5 b a, λ a b, h4 b a⟩; rw [val_inv, spec.domain_inv, spec.range_inv],
  exacts [(h3 L N hLA hnin hin L' A' hLA').symm, (h2 L N hLA hnin hin L' A' hLA').symm],
end

@[simp] lemma inv_le_inv (σ τ : allowable_partial_perm B) : σ⁻¹ ≤ τ⁻¹ ↔ σ ≤ τ :=
⟨λ h, by simpa only [inv_inv] using inv_mono h, λ h, inv_mono h⟩

section zorn_setup

/-! To set up for Zorn's lemma, we need to show that the union of all allowable partial permutations
in a chain is an upper bound for the chain. In particular, we first show that it is allowable, and
then we show it extends all elements in the chain.

Non-trivial bit: the "small or all" conditions — these are enforced by the "if adding any, add all"
parts of the definition of ≤. -/

variables {c : set (allowable_partial_perm B)}

lemma is_subset_chain_of_is_chain : is_chain (≤) c → is_chain (≤) (subtype.val '' c) :=
is_chain.image _ _ _ $ λ _ _, perm_le.le

lemma one_to_one_Union (hc : is_chain (≤) c) : spec.one_to_one_forward (Sup $ subtype.val '' c) :=
begin
  refine λ A, ⟨_, _⟩,
  all_goals
  { simp_rw mem_Sup,
    rintro b x ⟨σx, Hx, hx⟩ y ⟨σy, Hy, hy⟩,
    have hc' := is_subset_chain_of_is_chain hc Hx Hy,
    by_cases (σx = σy),
    rw ← h at hy,
    obtain ⟨⟨σx,hσx⟩, Hx₁, rfl⟩ := Hx,
    swap,
    specialize hc' h,
    cases hc',
    have hx' := hc' hx,
    obtain ⟨⟨σy,hσy⟩, Hy₁, rfl⟩ := Hy,
    swap,
    have hy' := hc' hy,
    obtain ⟨⟨σx,hσx⟩, Hx₁, rfl⟩ := Hx },
  -- Note: there must be a better way of doing this below.
  exact (hσx.forward.one_to_one A).atom b hx hy',
  exact (hσy.forward.one_to_one A).atom b hx' hy,
  exact (hσx.forward.one_to_one A).atom b hx hy,
  exact (hσx.forward.one_to_one A).near_litter b hx hy',
  exact (hσy.forward.one_to_one A).near_litter b hx' hy,
  exact (hσx.forward.one_to_one A).near_litter b hx hy,
end

lemma atom_cond_Union (hc : is_chain (≤) c) (L A) : spec.atom_cond (Sup (subtype.val '' c)) L A :=
begin
  obtain rfl | ⟨⟨σ, hσ₁⟩, hσ₂⟩ := c.eq_empty_or_nonempty,
  { refine spec.atom_cond.small_out _ _,
    { simp only [image_empty, Sup_empty, not_mem_empty, spec.domain_bot, not_false_iff] },
    { simp only [image_empty, Sup_empty, not_mem_empty, spec.domain_bot, sep_false,
        small_empty] } },
  by_cases h' : ∃ (ρ : allowable_partial_perm B) (hρ : ρ ∈ c) (τ : allowable_partial_perm B)
      (hτ : τ ∈ c) a b (ha : a ∈ litter_set L),
      (inl (a, b), A) ∉ ρ.val ∧ (inl (a, b), A) ∈ τ.val ∧ ρ ≤ τ,
  { obtain ⟨ρ, hρ, τ, hτ, a, b, ha, Hρ, Hτ, hρτ⟩ := h',
    obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, h₁, h₂, h₃⟩ := τ.prop.forward.atom_cond L A,
    { refine spec.atom_cond.all N _ atom_map _ h₃,
      { exact mem_Sup.2 ⟨_, mem_image_of_mem _ hτ, h₁⟩ },
      { exact λ a' ha',mem_Sup.2 ⟨_, mem_image_of_mem _ hτ, h₂ _ ha'⟩ } },
    all_goals
    { cases h₂.lt.ne _,
      rw ← mk_litter_set L, convert rfl,
      ext a',
      refine (and_iff_left_of_imp $ λ ha', _).symm,
      cases hρτ.all_atoms_domain a b L ha A Hρ Hτ a' ha' with d hd,
      exact mem_domain.2 ⟨_, hd, rfl⟩ } },
  push_neg at h',
  have H' : ∀ (ρ : allowable_partial_perm B), ρ ∈ c → ∀ (τ : allowable_partial_perm B),
              τ ∈ c → ∀ (a b : atom), a ∈ litter_set L →
              (inl (a, b), A) ∈ ρ.val → (inl (a, b), A) ∈ τ.val,
  { refine λ ρ hρ τ hτ a b ha Hρ, of_not_not (λ Hτ, _),
    cases h' τ hτ ρ hρ a b ha Hτ Hρ ((hc hτ hρ _).elim id $ λ h, _),
    { rintro rfl,
      exact Hτ Hρ },
    { cases Hτ (h.1 Hρ) } },
  have : {a ∈ litter_set L | (inl a, A) ∈ (Sup (subtype.val '' c)).domain}
          = {a ∈ litter_set L | (inl a, A) ∈ σ.domain},
  { ext a,
    simp_rw [mem_sep_iff, mem_domain, mem_Sup],
    refine and_congr_right (λ ha, ⟨_, _⟩),
    { rintro ⟨⟨⟨a', b⟩ | _, C⟩, ⟨_, ⟨ρ, hρ, rfl⟩, hb⟩, hab⟩; cases hab,
      refine ⟨_, H' ρ hρ _ hσ₂ a b ha hb, rfl⟩ },
    { exact λ ⟨b, hbσ, hba⟩, ⟨b, ⟨σ, ⟨_, hσ₂, rfl⟩, hbσ⟩, hba⟩ } },
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ := hσ₁.forward.atom_cond L A,
  { exact spec.atom_cond.all N (mem_Sup.2 ⟨_, mem_image_of_mem _ hσ₂, h₁⟩) atom_map
        (λ a' ha', mem_Sup.2 ⟨_, mem_image_of_mem _ hσ₂, h₂ _ ha'⟩) h₃ },
  { by_cases (inr L.to_near_litter, A) ∈ (Sup (subtype.val '' c)).domain,
    { rw mem_domain at h,
      obtain ⟨⟨_ | ⟨N₁, N₂⟩, C⟩, hc₁, ⟨⟩⟩ := h,
      refine spec.atom_cond.small_in N₂ hc₁ (by rwa this) _,
      simp_rw mem_Sup at ⊢ hc₁,
      rintro a' b ⟨_, ⟨⟨τ, hτ⟩, hτc, rfl⟩, hτa'⟩,
      obtain ⟨_, ⟨⟨ρ, hρ⟩, hρc, rfl⟩, hρN₂⟩ := hc₁,
      obtain ⟨N', h₁', atom_map', h₂', h₃'⟩ | ⟨h₁', h₂'⟩ | ⟨N', hN', h₁', h₂'⟩ :=
        hρ.forward.atom_cond L A,
      { rw [(hρ.backward.one_to_one A).near_litter _ hρN₂ h₁', h₃'],
        refine ⟨λ ha', ⟨⟨a', ha'⟩,
            (hτ.backward.one_to_one A).atom _ (H' _ hρc _ hτc _ _ ha' (h₂' a' ha')) hτa'⟩, _⟩,
        rintro ⟨⟨b', hb'⟩, rfl⟩,
        have := (hτ.forward.one_to_one A).atom _ (H' _ hρc _ hτc _ _ hb' (h₂' b' hb')) hτa',
        rwa this at hb' },
      { cases h₁' (mem_domain.2 ⟨_, hρN₂, rfl⟩) },
      { rw [(hρ.backward.one_to_one A).near_litter _ hρN₂ hN'],
        refine ⟨λ ha', (h₂' $ H' _ hτc _ hρc _ _ ha' hτa').1 ha', λ hb, _⟩,
        sorry } },
    { exact spec.atom_cond.small_out h (by rwa this) } },
  { refine spec.atom_cond.small_in N _ _ _,
    { exact mem_Sup.2 ⟨_, mem_image_of_mem _ hσ₂, hN⟩ },
    { rwa this },
    simp_rw mem_Sup,
    rintro a' b ⟨_, ⟨⟨τ, hτ⟩, hτc, rfl⟩, hτa'⟩,
    refine ⟨λ ha', (h₂ $ H' _ hτc _ hσ₂ a' b ha' hτa').1 ha', _⟩,
    sorry }
end

lemma near_litter_cond_Union (hc : is_chain (≤) c) (N₁ N₂ A) :
  (Sup (subtype.val '' c)).near_litter_cond N₁ N₂ A :=
begin
  rintro h,
  rw mem_Sup at h,
  obtain ⟨ρ, ⟨σ, hσ, rfl⟩, hρ⟩ := h,
  obtain ⟨M, hM, f, h1, h2⟩ := σ.prop.forward.near_litter_cond N₁ N₂ A hρ,
  exact ⟨M, mem_Sup.2 ⟨σ, mem_image_of_mem _ hσ, hM⟩, f, λ a, mem_Sup.2
    ⟨σ, mem_image_of_mem _ hσ, h1 a⟩, h2⟩,
end

lemma flexible_cond_Union (hc : is_chain (≤) c) (C : extended_index B) :
  (Sup (subtype.val '' c)).flexible_cond B C :=
begin
  obtain rfl | ⟨⟨σ, hσ₁⟩, hσ₂⟩ := c.eq_empty_or_nonempty,
  { refine spec.flexible_cond.co_large _ _;
    simp only [image_empty, Sup_empty, spec.domain_bot, spec.range_bot, mem_empty_eq,
      not_false_iff, and_true, coe_set_of, mk_flexible_litters] },
  by_cases h : ∃ (ρ : allowable_partial_perm B) (hρ : ρ ∈ c) (τ : allowable_partial_perm B)
    (hτ : τ ∈ c) L (hL : flexible L C),
    (((inr L.to_near_litter, C) ∉ ρ.val.domain ∧
      (inr L.to_near_litter, C) ∈ τ.val.domain) ∨
      ((inr L.to_near_litter, C) ∉ ρ.val.range ∧
      (inr L.to_near_litter, C) ∈ τ.val.range)) ∧ ρ ≤ τ,
  { obtain ⟨ρ, hρ, τ, hτ, L, hL, ⟨h, hρτ⟩⟩ := h,
    have H : ∀ L', flexible L' C →
        (⟨inr L'.to_near_litter, C⟩ : support_condition B) ∈ τ.val.domain ∧
        (⟨inr L'.to_near_litter, C⟩ : support_condition B) ∈ τ.val.range,
    { simp_rw [mem_domain, spec.mem_range] at h,
      obtain ⟨Hρ, ⟨⟨_ | ⟨N₁, N₂⟩, _⟩, hb₁, hb₂⟩⟩ | ⟨Hρ, ⟨⟨_ | ⟨N₁, N₂⟩, _⟩, hb₁, hb₂⟩⟩ := h;
      cases hb₂,
      { exact hρτ.all_flex_domain L N₂ C hL (λ Hρ', Hρ ⟨_, Hρ', rfl⟩) hb₁ },
      { exact hρτ.all_flex_range L N₁ C hL (λ Hρ', Hρ ⟨_, Hρ', rfl⟩) hb₁ } },
    refine spec.flexible_cond.all _ _;
    intros L' hL';
    obtain ⟨H₁, H₂⟩ := H L' hL';
    simp only [spec.domain_Sup, spec.range_Sup];
    exact mem_Union₂_of_mem (mem_image_of_mem _ hτ) ‹_› },
  push_neg at h,
  have := hσ₁.flexible_cond C,
  have H : ∀ (ρ : allowable_partial_perm B), ρ ∈ c → ∀ (τ : allowable_partial_perm B), τ ∈ c →
            ∀ (L : litter), flexible L C →
            ((inr L.to_near_litter, C) ∈ ρ.val.domain →
            (inr L.to_near_litter, C) ∈ τ.val.domain) ∧
            ((inr L.to_near_litter, C) ∈ ρ.val.range →
            (inr L.to_near_litter, C) ∈ τ.val.range),
  { intros ρ hρ τ hτ L hL,
    split;
    refine λ Hρ, of_not_not (λ Hτ, _),
    specialize h τ hτ ρ hρ L hL (or.inl ⟨Hτ, Hρ⟩), swap,
    specialize h τ hτ ρ hρ L hL (or.inr ⟨Hτ, Hρ⟩),
    all_goals
    { refine h ((hc hτ hρ _).elim id $ λ h₁, _),
      { rintro rfl,
        exact h le_rfl },
      { simp only [mem_domain, spec.mem_range] at Hρ Hτ,
        simp only [←image_domain, ←image_range] at Hρ Hτ,
        obtain ⟨b, hb₁, hb₂⟩ := Hρ,
        rw ←hb₂ at Hτ,
        cases Hτ (mem_image_of_mem _ $ h₁.1 hb₁) } } },
  obtain ⟨hdom, hrge⟩ | ⟨hdom, hrge⟩ := hσ₁.flexible_cond C,
  { refine spec.flexible_cond.co_large _ _,
    convert hdom using 3, swap, convert hrge using 3,
    all_goals
    { ext,
      rw [mem_set_of, mem_set_of, and.congr_right_iff],
      refine λ hx, ⟨λ hxc hxσ, hxc ⟨_, ⟨σ, Union_eq_true ⟨_, hσ₂, rfl⟩⟩, hxσ⟩, _⟩,
      rintro hxσ ⟨_, ⟨_, rfl⟩, ρ, ⟨⟨ρ, hρ₁, rfl⟩, rfl⟩, hρ₂⟩ },
    exact hxσ ((H ρ hρ₁ ⟨σ, hσ₁⟩ hσ₂ x hx).2 hρ₂),
    exact hxσ ((H ρ hρ₁ ⟨σ, hσ₁⟩ hσ₂ x hx).1 hρ₂), },
  { refine spec.flexible_cond.all (λ L hL, _) (λ L hL, _),
    { refine ⟨σ.domain, ⟨σ, Union_eq_true ⟨_, hσ₂, rfl⟩⟩, hdom L hL⟩, },
    { refine ⟨σ.range, ⟨σ, Union_eq_true ⟨_, hσ₂, rfl⟩⟩, hrge L hL⟩, } }
end

lemma non_flexible_cond_Union (hc : is_chain (≤) c) :
  (Sup $ subtype.val '' c).non_flexible_cond B :=
begin
  rintro β γ δ hγ hδ hγδ N A t hσ π hπ,
  rw mem_Sup at hσ,
  obtain ⟨_, ⟨σ, hσ₁, rfl⟩, hσ₂⟩ := hσ,
  exact σ.property.forward.non_flexible_cond hγ hδ hγδ N A t hσ₂ π (hπ.mono $ le_Sup ⟨σ, hσ₁, rfl⟩),
end

lemma domain_closed_Union (hc : is_chain (≤) c) :
  (Sup $ subtype.val '' c).domain.support_closed B :=
begin
  intros β γ δ hγ hδ hγδ A t h,
  simp_rw [spec.domain_Sup, mem_Union] at h,
  simp_rw [spec.domain_Sup, unary_spec.lower_Union],
  obtain ⟨_, ⟨σ, hσ₁, rfl⟩, hσ₂⟩ := h,
  refine (σ.prop.forward.support_closed hγ hδ hγδ A t hσ₂).mono _,
  convert @subset_bUnion_of_mem (unary_spec B) _ (spec.domain ∘ subtype.val '' c)
      (λ i, i.lower $ A.cons hγ) (spec.domain σ) _ using 1,
  { simp only [mem_image, Union_exists, bUnion_and', Union_Union_eq_right] },
  { exact ⟨σ, hσ₁, rfl⟩ }
end

variables (hc : is_chain (≤) c)

/-- The union of a chain of allowable partial permutations is allowable. -/
lemma allowable_Union : (Sup $ subtype.val '' c).allowable B :=
have c_inv_chain : is_chain (≤) (has_inv.inv '' c) := hc.image _ _ _ inv_mono,
have Union_rw : (Sup (subtype.val '' c))⁻¹ = Sup (subtype.val ''
  ((λ σ : allowable_partial_perm B, ⟨σ.val⁻¹, σ.2.inv⟩) '' c)) := begin
    rw Sup_inv, congr' 1, ext σ,
    simp only [allowable_inv, subtype.val_eq_coe, image_inv, set.mem_inv, mem_image, subtype.exists,
      subtype.coe_mk, exists_and_distrib_right, exists_eq_right, exists_prop,
      exists_eq_right_right],
    split,
    { rintro ⟨hσ, hσc⟩, exact ⟨hσ, ⟨σ⁻¹, allowable_inv.mpr hσ⟩, hσc, inv_inv σ⟩, },
    { rintro ⟨hσ, ρ, hρc, rfl⟩, simp_rw [inv_inv, subtype.coe_eta],
      exact ⟨allowable_inv.mpr ρ.property, hρc⟩, }
  end,
{ forward :=
  { one_to_one := one_to_one_Union hc,
    atom_cond := atom_cond_Union hc,
    near_litter_cond := near_litter_cond_Union hc,
    non_flexible_cond := non_flexible_cond_Union hc,
    support_closed := domain_closed_Union hc },
  backward :=
  { one_to_one := by { rw Union_rw, exact one_to_one_Union c_inv_chain },
    atom_cond := by { rw Union_rw, exact atom_cond_Union c_inv_chain },
    near_litter_cond := by { rw Union_rw, exact near_litter_cond_Union c_inv_chain },
    non_flexible_cond := by { rw Union_rw, exact non_flexible_cond_Union c_inv_chain },
    support_closed := by { rw Union_rw, exact domain_closed_Union c_inv_chain } },
  flexible_cond := flexible_cond_Union hc }

lemma le_Union₂ (σ τ : allowable_partial_perm B) (hτ : τ ∈ c) :
  τ ≤ ⟨Sup (subtype.val '' c), allowable_Union hc⟩ :=
begin
  have hsub : ∀ (t : allowable_partial_perm B) (ht : t ∈ c), t.val ≤ Sup (subtype.val '' c),
  { intros t ht b hb,
    exact ⟨t.val, ⟨t.val, Union_eq_true ⟨t, ht, rfl⟩⟩, hb⟩, },
  refine ⟨hsub τ hτ,
    λ L N A hLA hnin hin, _,
    λ L N A hLA hnin hin, _,
    λ a b L h A hnin hin p hp, _,
    λ a b L h A hnin hin p hp, _⟩,
  all_goals
  { obtain ⟨_, ⟨_, rfl⟩, _, ⟨⟨ρ, hρc, rfl⟩, rfl⟩, hLρ⟩ := hin,
    have hneq : ρ ≠ τ,
    { rintro rfl, exact hnin hLρ, },
    obtain ⟨hsub, -, -, -⟩ | hleq := hc hρc hτ hneq,
    { cases hnin (hsub hLρ) } },
  { have := hleq.2 L N A hLA hnin hLρ,
    sorry /- exact λ l hla, ⟨
      image_subset binary_condition.domain (hsub ρ hρc) (this l hla).1,
      image_subset binary_condition.range (hsub ρ hρc) (this l hla).2⟩ -/ },
  { have := hleq.3 L N A hLA hnin hLρ,
    sorry /- exact λ l hla, ⟨
      image_subset binary_condition.domain (hsub ρ hρc) (this l hla).1,
      image_subset binary_condition.range (hsub ρ hρc) (this l hla).2⟩ -/ },
  { obtain ⟨q, hq⟩ := hleq.4 a b L h A hnin hLρ p hp,
    exact ⟨q, (hsub ρ hρc) hq⟩ },
  { obtain ⟨q, hq⟩ := hleq.5 a b L h A hnin hLρ p hp,
    exact ⟨q, (hsub ρ hρc) hq⟩ }
end

lemma le_Union₁ (hcne : c.nonempty) (σ : allowable_partial_perm B)
  (hc₁ : c ⊆ {ρ : allowable_partial_perm B | σ ≤ ρ}) :
  σ ≤ ⟨Sup (subtype.val '' c), allowable_Union hc⟩ :=
let ⟨τ, h⟩ := hcne in (set_of_app_iff.1 $ mem_def.1 $ hc₁ h).trans (le_Union₂ hc σ τ h)

end zorn_setup

/-- There is a maximal allowable partial permutation extending any given allowable partial
permutation. This result is due to Zorn's lemma. -/
lemma maximal_perm (σ : allowable_partial_perm B) :
  ∃ (m : allowable_partial_perm B) (H : m ∈ {ρ : allowable_partial_perm B | σ ≤ ρ}), σ ≤ m ∧
    ∀ (z : allowable_partial_perm B), z ∈ {ρ : allowable_partial_perm B | σ ≤ ρ} →
    m ≤ z → z ≤ m :=
zorn_nonempty_preorder₀ {ρ | σ ≤ ρ}
  (λ c hc₁ hc₂ τ hτ,
    ⟨⟨Sup (subtype.val '' c), allowable_Union hc₂⟩,
      le_Union₁ hc₂ ⟨τ, hτ⟩ σ hc₁,
      λ τ, le_Union₂ hc₂ σ τ⟩)
  σ (le_refl σ)

section values

/-- Gets the value that a given input atom `b` is mapped to
under any allowable `π` extending `σ`. -/
def atom_value (σ : allowable_partial_perm B) (A : extended_index B)
  (b : atom) (hb : (inl b, A) ∈ σ.val.domain) : atom :=
@sum.rec _ _ (λ (c : atom × atom ⊕ near_litter × near_litter),
  c.elim (λ atoms, inl atoms.fst) (λ Ns, inr Ns.fst) = inl b → atom)
  (λ lhs _, lhs.snd) (λ lhs h, by cases h)
  (mem_domain.mp hb).some.1
  (congr_arg prod.fst (mem_domain.mp hb).some_spec.2)

lemma atom_value_spec (σ : allowable_partial_perm B) (A : extended_index B) (b : atom)
  (hb : (inl b, A) ∈ σ.val.domain) :
  (inl (b, atom_value σ A b hb), A) ∈ σ.val :=
begin
  unfold atom_value,
  rw mem_domain at hb,
  generalize hc : hb.some = c,
  obtain ⟨hc₁, hc₂⟩ := hb.some_spec,
  simp_rw hc at hc₁ hc₂ ⊢,
  obtain ⟨⟨b₁, b₂⟩ | Ns, C⟩ := c,
  { obtain ⟨⟨⟨d₁, d₂⟩ | _, D⟩, hd₁, hd₂⟩ := hb; cases hd₂,
    rw ← hc₂ at hd₂, cases hd₂,
    convert hd₁,
    exact (σ.property.backward.one_to_one A).atom b hc₁ hd₁ },
  { cases hc₂ }
end

lemma atom_value_spec_range (σ : allowable_partial_perm B) (A : extended_index B) (b : atom)
  (hb : (inl b, A) ∈ σ.val.domain) :
  (inl (atom_value σ A b hb), A) ∈ σ.val.range :=
spec.mem_range.2 ⟨(inl (b, atom_value σ A b hb), A), atom_value_spec σ A b hb, rfl⟩

@[simp] lemma atom_value_eq_of_mem (σ : allowable_partial_perm B) (A : extended_index B)
  (a b : atom) (hab : (inl (a, b), A) ∈ σ.val) :
  atom_value σ A a (mem_domain.2 ⟨_, hab, rfl⟩) = b :=
(σ.property.backward.one_to_one A).atom a (atom_value_spec σ A a $ mem_domain.2 ⟨_, hab, rfl⟩) hab

def atom_value_inj (σ : allowable_partial_perm B) (A : extended_index B) :
  {b | (inl b, A) ∈ σ.val.domain} ↪ atom :=
⟨λ b, atom_value σ A b.val b.property, λ b₁ b₂ hb, begin
  have h₁ := atom_value_spec σ A b₁ b₁.property,
  have h₂ := atom_value_spec σ A b₂ b₂.property,
  dsimp at hb, rw ← hb at h₂,
  exact subtype.coe_inj.mp
    ((σ.property.forward.one_to_one A).atom (atom_value σ A b₁ b₁.property) h₁ h₂),
end⟩

lemma atom_value_mem_inv (σ : allowable_partial_perm B) (A : extended_index B) (b : atom)
  (hb : (inl b, A) ∈ σ.val.domain) :
  (inl (atom_value σ A b hb, b), A) ∈ σ⁻¹.val :=
atom_value_spec σ A b hb

lemma atom_value_mem_range (σ : allowable_partial_perm B) (A : extended_index B) (b : atom)
  (hb : (inl b, A) ∈ σ.val.domain) :
  (inl (atom_value σ A b hb), A) ∈ σ.val.range :=
begin
  rw spec.mem_range,
  exact ⟨_, atom_value_spec σ A b hb, rfl⟩,
end

/-- Composing the `atom_value` operation with the inverse permutation does nothing. -/
lemma atom_value_inv (σ : allowable_partial_perm B) (A : extended_index B) (b : atom)
  (hb : (inl b, A) ∈ σ.val.domain) :
  atom_value σ⁻¹ A (atom_value σ A b hb) (atom_value_mem_range σ A b hb) = b :=
begin
  have := atom_value_spec σ⁻¹ A (atom_value σ A b hb) (atom_value_mem_range σ A b hb),
  simp_rw [allowable_partial_perm.val_inv, spec.inl_mem_inv] at this,
  exact (σ.property.forward.one_to_one A).atom _ this (atom_value_spec σ A b hb),
end

/-- Gets the value that a given input near litter `N` is mapped to
under any allowable `π` extending `σ`. -/
def near_litter_value (σ : allowable_partial_perm B) (A : extended_index B)
  (N : near_litter) (hb : (inr N, A) ∈ σ.val.domain) : near_litter :=
@sum.rec _ _ (λ (c : atom × atom ⊕ near_litter × near_litter),
  c.elim (λ atoms, inl atoms.fst) (λ Ns, inr Ns.fst) = inr N → near_litter)
  (λ lhs h, by cases h) (λ lhs _, lhs.snd)
  (mem_domain.mp hb).some.1
  (congr_arg prod.fst (mem_domain.mp hb).some_spec.2)

lemma near_litter_value_spec (σ : allowable_partial_perm B) (A : extended_index B) (N : near_litter)
  (hN : (inr N, A) ∈ σ.val.domain) :
  (inr (N, near_litter_value σ A N hN), A) ∈ σ.val :=
begin
  unfold near_litter_value,
  rw mem_domain at hN,
  generalize hc : hN.some = c,
  obtain ⟨hc₁, hc₂⟩ := hN.some_spec,
  simp_rw hc at hc₁ hc₂ ⊢,
  obtain ⟨_ | ⟨N₁, N₂⟩, C⟩ := c,
  { cases hc₂ },
  obtain ⟨⟨_ | ⟨N₃, N₄⟩, D⟩, hd₁, hd₂⟩ := hN; cases hd₂,
  rw ← hc₂ at hd₂,
  cases hd₂,
  convert hd₁,
  exact (σ.property.backward.one_to_one A).near_litter N hc₁ hd₁,
end

lemma near_litter_value_spec_range (σ : allowable_partial_perm B) (A : extended_index B)
  (N : near_litter) (hN : (inr N, A) ∈ σ.val.domain) :
  (inr (near_litter_value σ A N hN), A) ∈ σ.val.range :=
spec.mem_range.2 ⟨(inr (N, near_litter_value σ A N hN), A), near_litter_value_spec σ A N hN, rfl⟩

def near_litter_value_inj (σ : allowable_partial_perm B) (A : extended_index B) :
  {N | (inr N, A) ∈ σ.val.domain} ↪ near_litter :=
⟨λ N, near_litter_value σ A N.val N.property, begin
  intros N₁ N₂ hN,
  have h₁ := near_litter_value_spec σ A N₁ N₁.property,
  have h₂ := near_litter_value_spec σ A N₂ N₂.property,
  dsimp at hN, rw ← hN at h₂,
  exact subtype.coe_inj.mp
    ((σ.property.forward.one_to_one A).near_litter (near_litter_value σ A N₁ N₁.property) h₁ h₂),
end⟩

/-- If the images of two litters under `σ` intersect, the litters must intersect, and therefore are
equal. This is a rather technical result depending on various allowability conditions. -/
lemma litter_eq_of_image_inter (σ : allowable_partial_perm B) (A : extended_index B)
  {L₁ L₂ : litter} {N₁ N₂ : near_litter}
  (hL₁ : (inr (L₁.to_near_litter, N₁), A) ∈ σ.val)
  (hL₂ : (inr (L₂.to_near_litter, N₂), A) ∈ σ.val)
  (a : atom)
  (haN₁ : a ∈ N₁.snd.val)
  (haN₂ : a ∈ N₂.snd.val) : L₁ = L₂ :=
begin
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ :=
    σ.property.forward.atom_cond L₁ A,
  { cases (σ.property.backward.one_to_one A).near_litter _ hL₁ h₁,
    rw h₃ at haN₁,
    obtain ⟨a₁, ha₁⟩ := haN₁,
    have map₁ := h₂ a₁ a₁.property,
    rw subtype.coe_eta at map₁,
    rw ha₁ at map₁,

    obtain ⟨N', h₁', atom_map', h₂', h₃'⟩ | ⟨h₁', h₂'⟩ | ⟨N', hN', h₁', h₂'⟩ :=
      σ.property.forward.atom_cond L₂ A,
    { cases (σ.property.backward.one_to_one A).near_litter _ hL₂ h₁',
      rw h₃' at haN₂,
      obtain ⟨a₂, ha₂⟩ := haN₂,
      have map₂ := h₂' a₂ a₂.property,
      rw subtype.coe_eta at map₂,
      rw ha₂ at map₂,
      obtain ⟨⟨a₁L, a₁⟩, ha₁'⟩ := a₁,
      obtain ⟨⟨a₂L, a₂⟩, ha₂'⟩ := a₂,
      cases (σ.property.forward.one_to_one A).atom a map₁ map₂, cases ha₁', cases ha₂', refl },
    { rw mem_domain at h₁', cases h₁' ⟨_, hL₂, rfl⟩ },
    { cases (σ.property.backward.one_to_one A).near_litter _ hL₂ hN',
      have := h₂' (h₂ a₁ a₁.property),
      rw subtype.coe_eta at this,
      rw ha₁ at this,
      obtain ⟨⟨a₁L, a₁⟩, ha₁'⟩ := a₁,
      cases this.mpr haN₂, cases ha₁', refl } },
  { rw mem_domain at h₁, cases h₁ ⟨_, hL₁, rfl⟩ },
  cases (σ.property.backward.one_to_one A).near_litter _ hL₁ hN,
  obtain ⟨N', h₁', atom_map', h₂', h₃'⟩ | ⟨h₁', h₂'⟩ | ⟨N', hN', h₁', h₂'⟩ :=
    σ.property.forward.atom_cond L₂ A,
  { cases (σ.property.backward.one_to_one A).near_litter _ hL₂ h₁',
    rw h₃' at haN₂,
    obtain ⟨a₂, ha₂⟩ := haN₂,
    have map₂ := h₂' a₂ a₂.property,
    rw subtype.coe_eta at map₂,
    rw ha₂ at map₂,
    have := h₂ (h₂' a₂ a₂.property),
    rw subtype.coe_eta at this,
    rw ha₂ at this,
    obtain ⟨⟨a₂L, a₂⟩, ha₂'⟩ := a₂,
    cases this.mpr haN₁, cases ha₂', refl },
  { rw mem_domain at h₁', cases h₁' ⟨_, hL₂, rfl⟩ },
  cases (σ.property.backward.one_to_one A).near_litter _ hL₂ hN',
  obtain ⟨M₁, hM₁, s₁, hs₁, gs₁⟩ := σ.property.backward.near_litter_cond _ _ A hL₁,
  obtain ⟨M₂, hM₂, s₂, hs₂, gs₂⟩ := σ.property.backward.near_litter_cond _ _ A hL₂,
  dsimp only at gs₁ gs₂,
  cases eq_empty_or_nonempty ((N₁.snd.val \ litter_set N₁.fst) ∩ N₂.snd) with hN₁ hN₁,
  { cases eq_empty_or_nonempty ((N₂.snd.val \ litter_set N₂.fst) ∩ N₁.snd) with hN₂ hN₂,
    { rw eq_empty_iff_forall_not_mem at hN₁ hN₂, specialize hN₁ a, specialize hN₂ a,
      rw [mem_inter_iff, and_comm, mem_diff] at hN₁ hN₂,
      push_neg at hN₁ hN₂, specialize hN₁ haN₂ haN₁, specialize hN₂ haN₁ haN₂,
      have := eq_of_mem_litter_set_of_mem_litter_set hN₁ hN₂,
      rw this at hM₁,
      have M₁_eq_M₂ := (σ.property.forward.one_to_one A).near_litter _ hM₁ hM₂,
      dsimp only at M₁_eq_M₂, subst M₁_eq_M₂,
      refine is_near_litter_litter_set_iff.1 _,
      unfold is_near_litter is_near,
      rw [gs₁, gs₂, symm_diff_left_comm, ← symm_diff_assoc, symm_diff_symm_diff_cancel_left],
      refine ((cardinal.mk_le_mk_of_subset $ symm_diff_le_sup (range s₁) $ range s₂).trans $
        cardinal.mk_union_le _ _).trans_lt _,
      exact cardinal.add_lt_of_lt κ_regular.aleph_0_le
        (cardinal.mk_range_le.trans_lt N₁.2.2) (cardinal.mk_range_le.trans_lt N₂.2.2) },
    { obtain ⟨aN₂, haN₂, haN₂'⟩ := hN₂,
      have := hs₂ ⟨aN₂, or.inr haN₂⟩,
      exact eq_of_mem_litter_set_of_mem_litter_set
        ((h₂ this).symm.mp haN₂') ((h₂' this).symm.mp haN₂.left) } },
  { obtain ⟨aN₁, haN₁, haN₁'⟩ := hN₁,
      have := hs₁ ⟨aN₁, or.inr haN₁⟩,
      exact eq_of_mem_litter_set_of_mem_litter_set
        ((h₂ this).symm.mp haN₁.left) ((h₂' this).symm.mp haN₁') }
end

lemma litter_image_disjoint (σ : allowable_partial_perm B) (A : extended_index B)
  {L₁ L₂ : litter} {N₁ N₂ : near_litter}
  (hN₁ : (inr (L₁.to_near_litter, N₁), A) ∈ σ.val)
  (hN₂ : (inr (L₂.to_near_litter, N₂), A) ∈ σ.val) :
  L₁ ≠ L₂ → disjoint N₁.snd.val N₂.snd.val :=
begin
  contrapose!,
  rw not_disjoint_iff,
  rintro ⟨a, ha₁, ha₂⟩,
  exact litter_eq_of_image_inter σ A hN₁ hN₂ a ha₁ ha₂,
end

-- An application of the near litter condition using litter_image_disjoint.
lemma near_litter_image_disjoint (σ : allowable_partial_perm B) (A : extended_index B)
  {N M N' M' : near_litter}
  (hN : (inr (N, N'), A) ∈ σ.val) (hM : (inr (M, M'), A) ∈ σ.val) :
  disjoint N.snd.val M.snd.val → disjoint N'.snd.val M'.snd.val :=
sorry

end values

/-! The next few lemmas are discussed in "FoA proof sketch completion". -/

-- TODO: Generalise and improve the naming of the following lemmas.

section exists_ge_atom

/-!
Suppose that we have an atom whose litter is specified in `σ`. We want to extend `σ` such that all
of the atoms in this litter are now specified. To do this, we construct an arbitrary bijection of
the unassigned atoms in the litter in the domain with the unassigned atoms in the litter's image.
-/

variables (σ : allowable_partial_perm B) (a : atom) (A : extended_index B) (N : near_litter)

lemma atom_value_inj_range (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  range (λ b : {b : atom | b ∈ litter_set a.fst ∧ (inl b, A) ∈ σ.val.domain},
    (atom_value_inj σ A) ⟨b.val, b.property.right⟩) =
  {b : atom | b ∈ N.snd.val ∧ (inl b, A) ∈ σ.val.range} :=
begin
  rw range_eq_iff,
  refine ⟨λ c, ⟨_, _⟩, λ c hc, _⟩,
  { dsimp only [atom_value_inj, subtype.coe_mk, embedding.coe_fn_mk],
    have := atom_value_spec σ A c c.property.right,
    obtain ⟨N', h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N', hN, h₁, h₂⟩ :=
      σ.property.forward.atom_cond a.fst A,
    { cases (σ.property.backward.one_to_one A).near_litter _ ha h₁,
      rw [h₃, set.mem_range],
      refine ⟨⟨c, c.2.1⟩, _⟩,
      rw (σ.property.backward.one_to_one A).atom _ (h₂ c c.2.1) this,
      refl },
    { rw mem_domain at h₁, cases h₁ ⟨_, ha, rfl⟩ },
    { cases (σ.property.backward.one_to_one A).near_litter _ ha hN,
      exact (h₂ this).mp c.property.left } },
  { exact atom_value_spec_range σ A c c.property.right, },
  obtain ⟨hc, hc'⟩ := hc,
  rw spec.mem_range at hc',
  obtain ⟨⟨⟨a₁, a₂⟩ | Ns, C⟩, hd₁, hd₂⟩ := hc'; cases hd₂,
  refine ⟨⟨a₁, _, inl_mem_domain hd₁⟩, (σ.property.backward.one_to_one A).atom a₁
    (atom_value_spec σ A a₁ (inl_mem_domain hd₁)) hd₁⟩,
  obtain ⟨M, hM, s, hs₁, hs₂⟩ := σ.property.backward.near_litter_cond _ _ _ ha,
  dsimp only at hs₂,
  by_cases c ∈ litter_set N.fst,
  { obtain ⟨N', h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N', hN, h₁, h₂⟩ :=
      σ.property.backward.atom_cond N.fst A,
    { cases (σ.property.forward.one_to_one A).near_litter _ h₁ hM,
      cases (σ.property.forward.one_to_one A).atom _ (h₂ c h) hd₁,
      rw [hs₂, h₃],
      refine or.inl ⟨⟨_, rfl⟩, _⟩,
      rintro ⟨d, hd⟩,
      have := hs₁ d,
      rw hd at this,
      cases (σ.property.backward.one_to_one A).atom _ this hd₁,
      obtain ⟨h₁, h₂⟩ | ⟨h₁, h₂⟩ := d.property,
      { exact h₂ hc },
      { exact h₂ h } },
    { rw mem_domain at h₁, cases h₁ ⟨_, hM, rfl⟩ },
    { cases (σ.property.forward.one_to_one A).near_litter _ hM hN,
      rw hs₂,
      refine or.inl ⟨(h₂ hd₁).mp h, _⟩,
      rintro ⟨d, hd⟩,
      have := hs₁ d,
      rw hd at this,
      cases (σ.property.backward.one_to_one A).atom _ this hd₁,
      obtain ⟨h₁, h₂⟩ | ⟨h₁, h₂⟩ := d.property,
      { exact h₂ hc },
      { exact h₂ h } } },
  have : a₁ = _ := (σ.property.forward.one_to_one A).atom _ hd₁ (hs₁ ⟨c, or.inr ⟨hc, h⟩⟩),
  subst this,
  rw hs₂,
  refine or.inr ⟨⟨_, rfl⟩, _⟩,
  obtain ⟨N', h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N', hN, h₁, h₂⟩ := σ.2.backward.atom_cond N.fst A,
  { cases (σ.property.forward.one_to_one A).near_litter _ h₁ hM,
    rw h₃,
    rintro ⟨d, hd⟩,
    have := h₂ d d.property,
    rw [subtype.coe_eta, hd] at this,
    cases (σ.property.backward.one_to_one A).atom _ hd₁ this,
    exact h d.property },
  { rw mem_domain at h₁, cases h₁ ⟨_, hM, rfl⟩ },
  { cases (σ.property.forward.one_to_one A).near_litter _ hM hN,
    rw ← h₂ hd₁,
    exact h }
end

/-- The domain and range of an allowable partial permutation, restricted to a given litter, are
equivalent. The equivalence produced by this function is induced by the allowable partial
permutation itself, so if this function maps an atom `a` to `b`, we have `π_A(a) = b` for all
allowable `π` satisfying `σ`. -/
def cond_domain_range_equiv (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  {b | b ∈ litter_set a.fst ∧ (inl b, A) ∈ σ.val.domain} ≃
  {b | b ∈ N.snd.val ∧ (inl b, A) ∈ σ.val.range} :=
begin
  convert equiv.of_injective (λ (b : {b | b ∈ litter_set a.fst ∧ (inl b, A) ∈ σ.val.domain}),
    atom_value_inj σ A ⟨b.val, b.property.right⟩) _ using 2,
  { symmetry, exact atom_value_inj_range σ a A N ha },
  { intros b₁ b₂ hb,
    simpa only [subtype.mk_eq_mk, subtype.val_inj] using
      @function.embedding.injective _ _ (atom_value_inj σ A)
        ⟨b₁.val, b₁.property.right⟩ ⟨b₂.val, b₂.property.right⟩ hb },
end

/-- If we are in the "small" case (although this holds in both cases), the amount of atoms in a
given litter whose positions we have not defined so far is the same as the amount of atoms in the
resulting near-litter which are not the image of anything under `σ`. This means we can construct an
arbitrary bijection of these remaining atoms, "filling out" the specification to define the
permutation of all atoms in the litter to the atoms in the resulting near-litter. -/
lemma equiv_not_mem_atom (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  #↥{a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain} =
    #↥{a' ∈ N.snd.val | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.range} :=
begin
  have h₁ : #↥{a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain} = #κ,
  { cases le_iff_eq_or_lt.mp (cardinal.mk_le_mk_of_subset (show
      {a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain}
        ⊆ litter_set a.fst, by simp only [sep_subset])),
    { rw [h, mk_litter_set] },
    { rw mk_litter_set at h,
      cases (cardinal.add_lt_of_lt κ_regular.aleph_0_le hsmall h).ne _,
      rw [cardinal.mk_sep, cardinal.mk_sep],
      convert cardinal.mk_sum_compl _ using 1,
      rw mk_litter_set } },
  have h₂' : #↥{a' ∈ N.snd.val | (⟨inl a', A⟩ : support_condition B) ∈ σ.val.range} < #κ,
  { convert hsmall using 1,
    rw cardinal.eq,
    exact ⟨(cond_domain_range_equiv σ a A N ha).symm⟩ },
  rw h₁,
  cases le_iff_eq_or_lt.mp (cardinal.mk_le_mk_of_subset (show
    {a' ∈ N.snd.val | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.range}
      ⊆ N.snd.val, by simp only [sep_subset])),
  { rw [h, N.snd.property.mk_eq_κ] },
  rw N.snd.property.mk_eq_κ at h,
  cases (cardinal.add_lt_of_lt κ_regular.aleph_0_le h₂' h).ne _,
  rw [cardinal.mk_sep, cardinal.mk_sep],
  convert cardinal.mk_sum_compl _ using 1,
  rw N.snd.property.mk_eq_κ,
end

private def atom_map (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  ↥{a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain} ≃
    ↥{a' ∈ N.snd.val | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.range} :=
(cardinal.eq.mp $ equiv_not_mem_atom σ a A N hsmall ha).some

/-- The binary condition associated with this atom. -/
private def atom_to_cond (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  {a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain} →
    binary_condition B :=
λ b, (inl ⟨b, atom_map σ a A N hsmall ha b⟩, A)

lemma atom_to_cond_spec (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (b) : ∃ c, atom_to_cond σ a A N hsmall ha b = (inl (b, c), A) ∧
    (c ∈ N.snd.val ∧ (inl c, A) ∉ σ.val.range) :=
⟨atom_map σ a A N hsmall ha b, rfl, (atom_map σ a A N hsmall ha b).property⟩

lemma atom_to_cond_eq (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  {b c d e f C D} (hb : atom_to_cond σ a A N hsmall ha b = (inl (d, e), C))
  (hc : atom_to_cond σ a A N hsmall ha c = (inl (d, f), D)) :
  e = f ∧ C = D :=
begin
  simp only [atom_to_cond, prod.mk.inj_iff] at hb hc,
  obtain ⟨⟨h1, h2⟩, h3⟩ := hb,
  obtain ⟨⟨h1', h2'⟩, h3'⟩ := hc,
  rw [subtype.coe_inj.1 (h1.trans h1'.symm), h2'] at h2,
  exact ⟨h2.symm, h3.symm.trans h3'⟩,
end

lemma atom_to_cond_eq' (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  {b c d e f C D} (hb : atom_to_cond σ a A N hsmall ha b = (inl (e, d), C))
  (hc : atom_to_cond σ a A N hsmall ha c = (inl (f, d), D)) :
  e = f ∧ C = D :=
begin
  simp only [atom_to_cond, prod.mk.inj_iff] at hb hc,
  obtain ⟨⟨h1, h2⟩, h3⟩ := hb,
  obtain ⟨⟨h1', h2'⟩, h3'⟩ := hc,
  rw [← h2', subtype.coe_inj, embedding_like.apply_eq_iff_eq] at h2,
  exact ⟨h1.symm.trans ((subtype.coe_inj.2 h2).trans h1'), h3.symm.trans h3'⟩,
end

lemma exists_atom_to_cond (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  {c : atom} (hc₁ : c ∈ N.snd.val) (hc₂ : (inl c, A) ∉ σ.val.range) :
  ∃ d, atom_to_cond σ a A N hsmall ha d = (inl (d, c), A) :=
begin
  obtain ⟨d, hd⟩ : (⟨c, hc₁, hc₂⟩ : ↥{a' ∈ N.snd.val | _}) ∈ range (atom_map σ a A N hsmall ha),
  { rw equiv.range_eq_univ, exact mem_univ _ },
  refine ⟨d, _⟩,
  unfold atom_to_cond,
  rw hd,
  refl,
end

def new_atom_conds
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) : spec B := {
  carrier := set.range (atom_to_cond σ a A N hsmall ha),
  domain := set.range
    (λ b : {a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain},
      (sum.inl b.val, A)),
  range := set.range
    (λ b : {a' ∈ litter_set a.fst | (⟨inl a', A⟩ : support_condition B) ∉ σ.val.domain},
      (sum.inl (atom_map σ a A N hsmall ha b), A)),
  image_domain' := sorry,
  image_range' := sorry,
}

@[simp] lemma inl_mem_new_atom_conds
  {hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain}}
  {ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val}
  (b c : atom) (C : extended_index B) :
  (sum.inl (b, c), C) ∈ new_atom_conds σ a A N hsmall ha ↔
    C = A ∧ ∃ (hb₁ : b ∈ litter_set a.fst) (hb₂ : (inl b, A) ∉ σ.val.domain),
      c = atom_map σ a A N hsmall ha ⟨b, hb₁, hb₂⟩ :=
begin
  split,
  { rintro ⟨h₁, h₂⟩, cases h₂, refine ⟨rfl, h₁.prop.1, h₁.prop.2, _⟩, rw subtype.eta, refl, },
  { rintro ⟨rfl, hb₁, hb₂, rfl⟩, exact ⟨⟨b, hb₁, hb₂⟩, rfl⟩, },
end

lemma atom_union_one_to_one_forward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  spec.one_to_one_forward (σ.val ⊔ new_atom_conds σ a A N hsmall ha) :=
begin
  refine λ C, ⟨λ b p hp q hq, _, λ N' M hM M' hM', _⟩,
  { simp only [subtype.val_eq_coe, mem_sep_eq, mem_set_of_eq,
               mem_sup, set.mem_range, set_coe.exists, inl_mem_new_atom_conds] at hp hq,
    obtain hp | ⟨rfl, hxa, hxσ, rfl⟩ := hp; obtain hq | ⟨C_eq_A, hya, hyσ, hy⟩ := hq,
    { exact (σ.prop.forward.one_to_one C).atom b hp hq },
    { obtain ⟨c, hcond, hc, hcnin⟩ := atom_to_cond_spec σ a A N hsmall ha ⟨q, hya, hyσ⟩,
      cases C_eq_A, cases hy, cases hcond,
      rw spec.mem_range at hcnin,
      cases hcnin ⟨_, hp, rfl⟩ },
    { obtain ⟨c, hcond, hc, hcnin⟩ := atom_to_cond_spec σ a C N hsmall ha ⟨p, hxa, hxσ⟩,
      cases hcond,
      rw spec.mem_range at hcnin,
      cases hcnin ⟨_, hq, rfl⟩ },
    { rw [subtype.coe_inj, embedding_like.apply_eq_iff_eq] at hy,
      cases hy, refl, } },
  simp only [subtype.val_eq_coe, mem_sep_eq, mem_set_of_eq, mem_union_eq, spec.mem_range,
    set_coe.exists] at hM hM',
  obtain hM | ⟨x, ⟨hxa, hxσ⟩, hx⟩ := hM,
  obtain hM' | ⟨y, ⟨hya, hyσ⟩, hy⟩ := hM',
  { exact (σ.prop.forward.one_to_one C).near_litter N' hM hM' },
end

lemma atom_union_one_to_one_backward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  spec.one_to_one_forward (σ.val ⊔ new_atom_conds σ a A N hsmall ha)⁻¹ :=
begin
  refine λ C, ⟨λ b p hp q hq, _, λ N' M hM M' hM', _⟩,
  { simp only [subtype.val_eq_coe, mem_sep_eq, mem_set_of_eq, mem_sup, spec.mem_range,
      set_coe.exists, spec.mem_inv, inl_mem_new_atom_conds] at hp hq,
    dsimp only [has_inv.inv, has_involutive_inv.inv, sum.map_inl, prod.swap] at hp hq,
    obtain hp | ⟨p', hp⟩ := hp; obtain hq | ⟨q', hq⟩ := hq,
    { exact (σ.prop.backward.one_to_one C).atom b hp hq },
    { cases hq, cases q'.prop.2 (inl_mem_domain hp), },
    { cases hp, cases p'.prop.2 (inl_mem_domain hq), },
    { have : p' = q',
      { cases hp, unfold atom_to_cond at hq,
        simp only [subtype.val_eq_coe, prod.mk.inj_iff, eq_self_iff_true, and_true] at hq,
        exact subtype.coe_inj.mp hq.left.symm, },
      subst this, rw hp at hq, cases hq, refl, } },
  obtain hM | ⟨x, ⟨hxa, hxσ⟩, hx⟩ := hM,
  obtain hM' | ⟨y, ⟨hya, hyσ⟩, hy⟩ := hM',
  exact (σ.prop.backward.one_to_one C).near_litter N' hM hM',
end

lemma atom_union_atom_cond_forward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  ∀ L C, spec.atom_cond (σ.val ⊔ new_atom_conds σ a A N hsmall ha) L C :=
begin
  intros L C,
  obtain ⟨L', hL, atom_map, hin, himg⟩ | ⟨hL, hLsmall⟩ | ⟨L', hL, hLsmall, hmaps⟩ := σ.prop.forward.atom_cond L C,
  { exact spec.atom_cond.all L' (or.inl hL) atom_map (λ a ha, or.inl (hin a ha)) himg },
  { by_cases a.fst ≠ L ∨ A ≠ C,
    { refine spec.atom_cond.small_out _ _,
      { rw mem_domain,
        rintro ⟨⟨_ | ⟨N, M⟩, D⟩, hin | hin, hdom⟩; cases hdom,
        { exact hL (inr_mem_domain hin) },
        { unfold new_atom_conds atom_to_cond at hin,
          cases hin with _ hin, cases hin } },
      unfold small,
      have : {a_1 ∈ litter_set L | (inl a_1, C) ∈
        (σ.val ⊔ σ.new_atom_conds a A N hsmall ha).domain} =
        {a_1 ∈ litter_set L | (inl a_1, C) ∈ σ.val.domain} ∪ {a_1 ∈ litter_set L | (inl a_1, C) ∈
          binary_condition.domain '' range (atom_to_cond σ a A N hsmall ha)},
      sorry { ext,
        simp only [subtype.val_eq_coe, mem_sep_eq, mem_union_eq, mem_image, set.mem_range,
          set_coe.exists, mem_domain],
        split,
        { rintro ⟨hL, h | h⟩,
          { exact or.inl ⟨hL, h⟩ },
          { exact or.inr ⟨hL, h⟩ } },
        { rintro (⟨hL, h⟩ | ⟨hL, h⟩),
          { exact ⟨hL, or.inl h⟩ },
          { exact ⟨hL, or.inr h⟩ } } },
      rw this,
      convert (cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt κ_regular.aleph_0_le
        hLsmall $ (cardinal.mk_emptyc _).trans_lt κ_regular.pos),
      simp only [binary_condition.domain, subtype.val_eq_coe, mem_sep_eq, mem_image, set.mem_range,
        set_coe.exists, prod.mk.inj_iff],
      cases h,
      { refine eq_empty_of_forall_not_mem _,
        rintro x ⟨hx, ⟨⟨x', y⟩ | _, b⟩, ⟨_, ⟨ha, _⟩, hb⟩, ⟨⟩⟩,
        simp only [atom_to_cond, sum.elim_inl, subtype.coe_mk, prod.mk.inj_iff] at hb,
        obtain ⟨⟨rfl, -⟩, -⟩ := hb,
        exact pairwise_disjoint_litter_set a.fst L h ⟨ha, hx⟩ },
      { refine eq_empty_of_forall_not_mem _,
        rintro x ⟨hL, ⟨b1, b2⟩, ⟨_, _, h1⟩, h2⟩,
        exact h ((congr_arg prod.snd h1).trans $ congr_arg prod.snd h2) } },
    { obtain ⟨rfl, rfl⟩ := and_iff_not_or_not.2 h,
      cases hL (inr_mem_domain ha), } },
  { by_cases a.fst ≠ L ∨ A ≠ C,
    { refine spec.atom_cond.small_in L' (or.inl hL) _ _,
      { unfold small,
        have : {a_1 ∈ litter_set L | (inl a_1, C) ∈
          (σ.val ⊔ σ.new_atom_conds a A N hsmall ha).domain} = {a_1 ∈ litter_set L | (inl a_1, C) ∈
              σ.val.domain} ∪ {a_1 ∈ litter_set L | (inl a_1, C) ∈
                binary_condition.domain '' range (atom_to_cond σ a A N hsmall ha)},
        sorry { ext,
          simp only [subtype.val_eq_coe, mem_sep_eq, mem_union_eq, mem_image, mem_range,
            set_coe.exists],
          split,
          { rintro ⟨hL, h | h⟩,
            { exact or.inl ⟨hL, h⟩ },
            { exact or.inr ⟨hL, h⟩ } },
          { rintro (⟨hL, h⟩ | ⟨hL, h⟩),
            { exact ⟨hL, or.inl h⟩ },
            { exact ⟨hL, or.inr h⟩ } } },
        rw this,
        convert (cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt κ_regular.aleph_0_le
          hLsmall $ (cardinal.mk_emptyc _).trans_lt κ_regular.pos),
        simp only [binary_condition.domain, subtype.val_eq_coe, mem_sep_eq, mem_image,
          set.mem_range, set_coe.exists, prod.mk.inj_iff],
        cases h,
        { refine eq_empty_of_forall_not_mem _,
          rintro x ⟨hx, ⟨⟨x', y⟩ | _, b⟩, ⟨_, ⟨ha, _⟩, hb⟩, ⟨⟩⟩,
          { simp only [atom_to_cond, sum.elim_inl, subtype.coe_mk, prod.mk.inj_iff] at hb,
            obtain ⟨⟨rfl, -⟩, -⟩ := hb,
            exact pairwise_disjoint_litter_set a.fst L h ⟨ha, hx⟩ } },
        { refine eq_empty_of_forall_not_mem _,
          rintro x ⟨hL, ⟨b1, b2⟩, ⟨_, _, h1⟩, h2⟩,
        exact h ((congr_arg prod.snd h1).trans $ congr_arg prod.snd h2) } },
      { refine λ c d hcdu, or.rec (@hmaps c d) _ hcdu,
        rintro ⟨c, hcond⟩,
        cases hcond,
        simp only [ne.def, eq_self_iff_true, not_true, or_false] at h,
        refine ⟨λ hc, by cases pairwise_disjoint_litter_set _ _ h ⟨c.prop.1, hc⟩, _⟩,
        intro hL',
        cases litter_image_disjoint σ A ha hL h ⟨(atom_map σ a A N hsmall ha c).prop.1, hL'⟩ } },
    { classical,
      obtain ⟨rfl, rfl⟩ := and_iff_not_or_not.2 h,
      obtain rfl := (σ.prop.backward.one_to_one A).near_litter _ ha hL,
      refine spec.atom_cond.all N (or.inl ha)
        (λ x, dite ((inl x.val, A) ∈ σ.val.domain)
          (λ hx, atom_value σ A x hx)
          (λ hx, (atom_map σ a A N hsmall ha ⟨x.val, x.prop, hx⟩).val))
        (λ y hy, _) (ext $ λ x, ⟨λ hx, _, λ hx, _⟩),
      { by_cases (inl y, A) ∈ σ.val.domain,
        { rw dif_pos h,
          exact or.inl (atom_value_spec σ A y h) },
        { rw dif_neg h,
          exact or.inr ⟨⟨y, hy, h⟩, rfl⟩ } },
      { by_cases (inl x, A) ∈ σ.val.range,
        { rw spec.mem_range at h, obtain ⟨⟨⟨y, _⟩ | _, _⟩, hin, hxy⟩ := h; cases hxy,
          have hya : y ∈ litter_set a.fst := (hmaps hin).2 hx,
          use ⟨y, hya⟩,
          dsimp only,
          have : (inl y, A) ∈ σ.val.domain := inl_mem_domain hin,
          rw dif_pos this,
          exact (σ.prop.backward.one_to_one A).atom y
            (atom_value_spec σ A y $ inl_mem_domain hin) hin },
        { obtain ⟨d, hd⟩ := exists_atom_to_cond σ a A N hsmall ha hx h,
          use ⟨coe d, d.prop.1⟩,
          dsimp only,
          rw dif_neg d.prop.2,
          simpa only [atom_to_cond, subtype.coe_eta, prod.mk.inj_iff,
                      eq_self_iff_true, true_and, and_true] using hd } },
      { obtain ⟨y, rfl⟩ := hx,
        by_cases (inl y.val, A) ∈ σ.val.domain,
        { simp_rw dif_pos h,
          exact (hmaps $ atom_value_spec σ A y.val h).1 y.prop },
        { simp_rw dif_neg h,
          obtain ⟨c, hcy, hcN, hcnin⟩ := atom_to_cond_spec σ a A N hsmall ha ⟨y.val, y.prop, h⟩,
          simp only [atom_to_cond, prod.mk.inj_iff, eq_self_iff_true, true_and, and_true] at hcy,
          rw ← hcy at hcN,
          exact hcN } } } },
end

lemma atom_union_atom_cond_backward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) (L C) :
  spec.atom_cond (σ.val ⊔ new_atom_conds σ a A N hsmall ha)⁻¹ L C :=
begin
  obtain ⟨L', hL, atom_map, hin, himg⟩ | ⟨hL, hLsmall⟩ | ⟨L', hL, hLsmall, hmaps⟩ :=
    σ.prop.backward.atom_cond L C,
  { exact spec.atom_cond.all L' (or.inl hL) atom_map (λ a H, or.inl $ hin a H) himg },
  { by_cases N.fst = L,
    { subst h,
      refine spec.atom_cond.small_out _ _,
      sorry, sorry -- weird stuff with that rintro that i don't understand now
      /- { rintro ⟨⟨_ | ⟨x, y⟩, D⟩, hb | hb, ⟨⟩⟩,
        { exact hL ⟨_, hb, rfl⟩ },
        cases hb.some_spec },
        rw spec.domain_inv at hLsmall ⊢,
        rw spec.range_sup,
        have : {a_1 ∈ litter_set N.fst | (inl a_1, C) ∈ σ.val.range ∪
          spec.range (range (atom_to_cond σ a A N hsmall ha))} =
            {a_1 ∈ litter_set N.fst | (inl a_1, C) ∈
            binary_condition.range '' σ.val} ∪ {a_1 ∈ litter_set N.fst | (inl a_1, C) ∈
              binary_condition.range '' range (atom_to_cond σ a A N hsmall ha)},
        { ext,
          simp only [spec.range, subtype.val_eq_coe, mem_sep_eq, mem_union_eq, mem_image, mem_range,
            set_coe.exists],
          split,
          { rintro ⟨hL, h | h⟩,
            { exact or.inl ⟨hL, h⟩ },
            { exact or.inr ⟨hL, h⟩ } },
          { rintro (⟨hL, h⟩ | ⟨hL, h⟩),
            { exact ⟨hL, or.inl h⟩ },
            { exact ⟨hL, or.inr h⟩ } } },
        rw this,
        by_cases A = C,
        { subst h,
          refine (cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt κ_regular.aleph_0_le
            hLsmall _),
          unfold atom_to_cond,
          cases hL ⟨_, (σ.prop.backward.near_litter_cond N a.fst.to_near_litter A ha).some_spec.1,
            rfl⟩ },
        { convert (cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt κ_regular.aleph_0_le
              hLsmall $ (cardinal.mk_emptyc _).trans_lt κ_regular.pos),
          refine ext (λ x, ⟨_, λ hx, hx.rec _⟩),
          rintro ⟨-, ⟨_, _⟩, ⟨_, ⟨⟩⟩, ⟨⟩⟩,
          cases h rfl } -/ },
    { sorry } },
  { sorry }
end

lemma atom_union_near_litter_cond_forward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  ∀ N₁ N₂ C,
    spec.near_litter_cond (σ.val ⊔ new_atom_conds σ a A N hsmall ha) N₁ N₂ C :=
begin
  rintro N₁ N₂ C (h | h),
  { obtain ⟨M, hM₁, sd, hsd₁, hsd₂⟩ := σ.property.forward.near_litter_cond N₁ N₂ C h,
    exact ⟨M, or.inl hM₁, sd, λ a, or.inl (hsd₁ a), hsd₂⟩ },
  obtain ⟨d, hd⟩ := h,
  cases hd,
end

lemma atom_union_near_litter_cond_backward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  ∀ N₁ N₂ C,
    spec.near_litter_cond (σ.val ⊔ new_atom_conds σ a A N hsmall ha)⁻¹ N₁ N₂ C :=
begin
  rintro N₁ N₂ C (h | h),
  { obtain ⟨M, hM₁, sd, hsd₁, hsd₂⟩ := σ.property.backward.near_litter_cond N₁ N₂ C h,
    exact ⟨M, or.inl hM₁, sd, λ a, or.inl (hsd₁ a), hsd₂⟩ },
  obtain ⟨d, hd⟩ := h,
  cases hd,
end

lemma atom_union_non_flexible_cond_forward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  spec.non_flexible_cond B (σ.val ⊔ new_atom_conds σ a A N hsmall ha) :=
begin
  rintro β δ γ hγ hδ hγδ N₁ C t (ht | ht) ρ hρ,
  { exact σ.property.forward.non_flexible_cond hγ hδ hγδ N₁ C t ht ρ
      (hρ.mono $ subset_union_left _ _) },
  obtain ⟨d, hd⟩ := ht,
  cases hd,
end

lemma atom_union_non_flexible_cond_backward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  spec.non_flexible_cond B (σ.val ⊔ new_atom_conds σ a A N hsmall ha)⁻¹ :=
begin
  rintro β δ γ hγ hδ hγδ N₁ C t (ht | ⟨d, ⟨⟩⟩) ρ hρ,
  exact σ.property.backward.non_flexible_cond hγ hδ hγδ N₁ C t ht ρ
      (hρ.mono $ subset_union_left _ _),
end

lemma atom_union_support_closed_forward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  (σ.val ⊔ new_atom_conds σ a A N hsmall ha).domain.support_closed B :=
begin
  intros β δ γ hγ hδ hγδ C t ht,
  rw spec.domain_sup at ht ⊢,
  rw unary_spec.lower_union,
  obtain (ht | ⟨_, ⟨_, ⟨⟩⟩, ⟨⟩⟩) := ht,
  exact (σ.property.forward.support_closed hγ hδ hγδ C t ht).mono (subset_union_left _ _),
end

lemma atom_union_support_closed_backward (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  (σ.val ⊔ new_atom_conds σ a A N hsmall ha).range.support_closed B :=
begin
  intros β δ γ hγ hδ hγδ C t ht,
  rw spec.range_sup at ht ⊢,
  rw unary_spec.lower_union,
  obtain (ht | ⟨_, ⟨_, ⟨⟩⟩, ⟨⟩⟩) := ht,
  convert (σ.property.backward.support_closed hγ hδ hγδ C t $ by rwa spec.domain_inv).mono
    (subset_union_left _ _),
end

lemma atom_union_flexible_cond (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) (C) :
  spec.flexible_cond B (σ.val ⊔ new_atom_conds σ a A N hsmall ha) C :=
begin
  obtain (⟨hdom, hrge⟩ | ⟨hdom, hrge⟩) := σ.property.flexible_cond C,
  { refine spec.flexible_cond.co_large _ _,
    { convert hdom,
      ext L,
      rw spec.domain_sup,
      refine and_congr_right' ⟨λ hC h, hC $ mem_union_left _ h, λ hC, _⟩,
      rintro (h | ⟨_, ⟨_, ⟨⟩⟩, ⟨⟩⟩),
      exact hC h },
    { convert hrge,
      ext L,
      rw spec.range_sup,
      refine and_congr_right' ⟨λ hC h, hC $ mem_union_left _ h, λ hC, _⟩,
      rintro (h | ⟨_, ⟨_, ⟨⟩⟩, ⟨⟩⟩),
      exact hC h } },
  { refine spec.flexible_cond.all (λ L hL, _) (λ L hL, _),
    { rw spec.domain_sup,
      exact or.inl (hdom L hL) },
    { rw spec.range_sup,
      exact or.inl (hrge L hL) } }
end

/-- When we add the provided atoms from the atom map, we preserve allowability.

This lemma is going to be work, and we have three others just like it later.
Is there a way to unify all of the cases somehow, or at least avoid duplicating code?
At the moment, I can't see a way to use any less than eleven lemmas here, since the symmetry is
broken. -/
lemma atom_union_allowable (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  spec.allowable B (σ.val ⊔ new_atom_conds σ a A N hsmall ha) :=
{ forward :=
  { one_to_one := atom_union_one_to_one_forward σ a A N hc hsmall ha,
    atom_cond := atom_union_atom_cond_forward σ a A N hc hsmall ha,
    near_litter_cond := atom_union_near_litter_cond_forward σ a A N hc hsmall ha,
    non_flexible_cond := atom_union_non_flexible_cond_forward σ a A N hc hsmall ha,
    support_closed := atom_union_support_closed_forward σ a A N hc hsmall ha },
  backward :=
  { one_to_one := atom_union_one_to_one_backward σ a A N hc hsmall ha,
    atom_cond := atom_union_atom_cond_backward σ a A N hc hsmall ha,
    near_litter_cond := atom_union_near_litter_cond_backward σ a A N hc hsmall ha,
    non_flexible_cond := atom_union_non_flexible_cond_backward σ a A N hc hsmall ha,
    support_closed := by { rw spec.domain_inv,
      exact atom_union_support_closed_backward σ a A N hc hsmall ha } },
  flexible_cond := atom_union_flexible_cond σ a A N hc hsmall ha }

lemma atom_union_all_atoms_domain (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) (b₁ b₂ : atom)
  (L : litter) (hb₁ : b₁ ∈ litter_set L) (C : extended_index B)
  (hσ : (⟨inl ⟨b₁, b₂⟩, C⟩ : binary_condition B) ∈
    range (atom_to_cond σ a A N hsmall ha)) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨c, d⟩, C⟩ : binary_condition B) ∈
    σ.val ⊔ new_atom_conds σ a A N hsmall ha :=
begin
  intros c hc,
  by_cases (⟨inl c, C⟩ : support_condition B) ∈ σ.val.domain,
  { exact ⟨atom_value σ C c h, or.inl (atom_value_spec σ C c h)⟩ },
  obtain ⟨d, hd⟩ := hσ,
  have hd : b₁ = d,
  { unfold atom_to_cond at hd,
    have hd' := congr_arg prod.fst hd, have := congr_arg prod.fst (inl.inj hd'),
    cases this, refl },
  subst hd,
  have hL : L = a.fst := by { cases hb₁, obtain ⟨d, hd₁, hd₂⟩ := d, exact hd₁ },
  subst hL,
  have hC : A = C := by { cases hd, refl },
  subst hC,
  generalize he : atom_to_cond σ a A N hsmall ha ⟨c, hc, h⟩ = e,
  obtain ⟨⟨e₁, e₂⟩ | Ns, E⟩ := e,
  { refine ⟨e₂, or.inr ⟨⟨c, hc, h⟩, _⟩⟩,
    cases he, exact he },
  { unfold atom_to_cond at he, simpa only [prod.mk.inj_iff, false_and] using he }
end

/-- The image of an element of a near-litter lies in the resulting near-litter. -/
lemma atom_union_mem (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (b₁ b₂ : atom) (C : extended_index B)
  (hσ : (⟨inl ⟨b₁, b₂⟩, C⟩ : binary_condition B) ∈
    range (atom_to_cond σ a A N hsmall ha)) :
  b₂ ∈ (N.snd : set atom) :=
begin
  obtain ⟨d, hd⟩ := hσ,
  have : b₁ = d,
  { unfold atom_to_cond at hd,
    have hd' := congr_arg prod.fst hd, have := congr_arg prod.fst (inl.inj hd'),
    cases this, refl },
  subst this,
  obtain ⟨N', h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N', h₁, h₂, h₃⟩ :=
    atom_union_atom_cond_forward σ a A N hc hsmall ha a.fst A,
  { obtain this | ⟨e, he⟩ := h₂ d d.property.left,
    { cases d.property.right (inl_mem_domain this) },
    rw (atom_to_cond_eq σ a A N hsmall ha hd he).left,
    rw (atom_union_one_to_one_backward σ a A N hc hsmall ha A).near_litter
      a.fst.to_near_litter (or.inl hc) h₁,
    exact ((range_eq_iff _ _).mp h₃.symm).left _ },
  { cases h₁ _,
    rw spec.domain_sup,
    exact or.inl (inr_mem_domain ha) },
  { have : A = C,
    { cases hd, refl },
    subst this,
    have := (h₃ (or.inr ⟨d, hd⟩)).1 d.property.left,
    rwa (atom_union_one_to_one_backward σ a A N hc hsmall ha A).near_litter
       a.fst.to_near_litter (or.inl hc) h₁
  }
end

/-- The atom map only ever maps to the intersection of `N` with its corresponding litter, `N.fst`.
In particular, we prove that if some atom `c` lies in the litter we're mapping to, it lies in the
precise near-litter we are mapping to as well. -/
lemma atom_union_mem' (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (b₁ b₂ : atom) (C : extended_index B)
  (hσ : (⟨inl ⟨b₁, b₂⟩, C⟩ : binary_condition B) ∈ range (atom_to_cond σ a A N hsmall ha))
  (c : atom) (hc₁ : c ∈ litter_set b₂.fst) (hc₂ : (inl c, A) ∉ σ.val.range) :
  c ∈ (N.snd : set atom) :=
begin
  contrapose hc₂,
  rw not_not_mem,

  suffices hb₂ : b₂.fst = N.fst,
  { rw hb₂ at hc₁,
    obtain ⟨M, hM, symm_diff, hS₁, hS₂⟩ :=
      σ.property.backward.near_litter_cond N a.fst.to_near_litter A hc,
    exact inl_mem_domain (hS₁ ⟨c, or.inl ⟨hc₁, hc₂⟩⟩), },

  obtain ⟨d, hd⟩ := hσ,
  have : b₁ = d,
  { unfold atom_to_cond at hd,
    have hd' := congr_arg prod.fst hd, have := congr_arg prod.fst (inl.inj hd'),
    cases this, refl },
  subst this,

  obtain ⟨M, hM, symm_diff, hS₁, hS₂⟩ :=
    σ.property.backward.near_litter_cond N a.fst.to_near_litter A hc,
  by_contradiction hb₂,
  have := hS₁ ⟨b₂, or.inr ⟨atom_union_mem σ a A N hc hsmall ha d b₂ C ⟨d, hd⟩, hb₂⟩⟩,
  obtain ⟨e, he₁, he₂, he₃⟩ := atom_to_cond_spec σ a A N hsmall ha d,
  rw hd at he₁,
  cases he₁,
  exact he₃ (inl_mem_domain this),
end

lemma atom_union_all_atoms_range (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) (b₁ b₂ : atom)
  (L : litter) (hb₂ : b₂ ∈ litter_set L) (C : extended_index B)
  (hσ : (⟨inl ⟨b₁, b₂⟩, C⟩ : binary_condition B) ∈
    range (atom_to_cond σ a A N hsmall ha)) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨d, c⟩, C⟩ : binary_condition B) ∈
    σ.val ⊔ new_atom_conds σ a A N hsmall ha :=
begin
  have b₂_mem := atom_union_mem σ a A N hc hsmall ha _ _ _ hσ,
  obtain ⟨d, hd⟩ := hσ,
  have : b₁ = d,
  { unfold atom_to_cond at hd,
    have hd' := congr_arg prod.fst hd, have := congr_arg prod.fst (inl.inj hd'),
    cases this, refl },
  subst this,
  have : A = C,
  { cases hd, refl },
  subst this,
  have : N.fst = L,
  { cases hb₂,
    by_contradiction,
    obtain ⟨M, hM, symm_diff, hS₁, hS₂⟩ :=
      σ.property.backward.near_litter_cond N a.fst.to_near_litter A ‹_›,
    rw spec.inr_mem_inv at hM,
    have mem_symm_diff : b₂ ∈ litter_set N.fst ∆ N.snd := or.inr ⟨b₂_mem, ne.symm h⟩,
    have hS₁' := hS₁ ⟨b₂, mem_symm_diff⟩,
    rw spec.inl_mem_inv at hS₁',
    have : symm_diff ⟨b₂, mem_symm_diff⟩ = d :=
      (atom_union_one_to_one_forward σ a A N hc hsmall ha A).atom b₂
        (or.inl hS₁') (or.inr ⟨_, hd⟩),
    refine d.property.right _,
    rw [subtype.val_eq_coe, ← this],
    exact inl_mem_domain hS₁', },
  subst this,

  intros c hc,
  by_cases (⟨inl c, A⟩ : support_condition B) ∈ σ.val.range,
  { rw spec.mem_range at h, obtain ⟨⟨⟨d₁, d₂⟩ | Ns, D⟩, hc₁, hc₂⟩ := h; cases hc₂,
    exact ⟨d₁, or.inl hc₁⟩ },
  have : c ∈ N.snd.val,
  { convert atom_union_mem' σ a A N ‹_› hsmall ha d b₂ A ⟨d, hd⟩ _ _ h, convert hc },
  refine ⟨(atom_map σ a A N hsmall ha).inv_fun ⟨c, this, h⟩,
    or.inr ⟨(atom_map σ a A N hsmall ha).inv_fun ⟨c, this, h⟩, _⟩⟩,
  unfold atom_to_cond,
  rw ← equiv.to_fun_as_coe,
  rw equiv.right_inv _,
  refl,
end

/-- When we add the atoms from the atom map, the resulting permutation "carefully extends" `σ`.
The atom conditions hold because `σ` is allowable and the `near_litter_cond` is satisfied - in
particular, the atoms in the symmetric difference between `N` and `N.fst.to_near_litter` are already
given in `σ`, so do not appear in the `atom_to_cond` map. -/
lemma le_atom_union (hc : (inr (a.fst.to_near_litter, N), A) ∈ σ.val)
  (hsmall : small {a ∈ litter_set a.fst | (inl a, A) ∈ σ.val.domain})
  (ha : (inr (a.fst.to_near_litter, N), A) ∈ σ.val) :
  σ ≤ ⟨σ.val ⊔ new_atom_conds σ a A N hsmall ha, atom_union_allowable σ a A N hc hsmall ha⟩ := {
  le := subset_union_left _ _,
  all_flex_domain := begin
    intros L N' C hN' hσ₁ hσ₂,
    cases mem_or_mem_of_mem_union hσ₂,
    { cases hσ₁ h },
    simpa only [new_atom_conds, atom_to_cond, spec.coe_mk, prod.mk.inj_iff, exists_false,
      set.mem_range, false_and] using h,
  end,
  all_flex_range := begin
    intros L N' C hN' hσ₁ hσ₂,
    cases mem_or_mem_of_mem_union hσ₂,
    { cases hσ₁ h },
    simpa only [new_atom_conds, atom_to_cond, spec.coe_mk, prod.mk.inj_iff, exists_false,
      set.mem_range, false_and] using h,
  end,
  all_atoms_domain := begin
    intros b₁ b₂ L hb₁ C hC₁ hC₂ c hc',
    cases hC₂,
    { cases hC₁ hC₂ },
    exact atom_union_all_atoms_domain σ a A N hc hsmall ha b₁ b₂ L hb₁ C hC₂ c hc',
  end,
  all_atoms_range := begin
    intros b₁ b₂ L hb₁ C hC₁ hC₂ c hc',
    cases hC₂,
    { cases hC₁ hC₂ },
    exact atom_union_all_atoms_range σ a A N hc hsmall ha b₁ b₂ L hb₁ C hC₂ c hc',
  end,
}

/-- If everything that constrains an atom lies in `σ`, we can add the atom to `σ`, giving a new
allowable partial permutation `ρ ≥ σ`. -/
lemma exists_ge_atom (hσ : ∀ c, c ≺ (⟨inl a, A⟩ : support_condition B) → c ∈ σ.val.domain) :
  ∃ ρ, σ ≤ ρ ∧ (⟨inl a, A⟩ : support_condition B) ∈ ρ.val.domain :=
begin
  by_cases haσ : (⟨inl a, A⟩ : support_condition B) ∈ σ.val.domain,
  { exact ⟨σ, le_rfl, haσ⟩ },
  have h := hσ (⟨inr a.fst.to_near_litter, A⟩ : support_condition B)
    (constrains.mem_litter a.fst a rfl _),
  rw mem_domain at h,
  obtain ⟨⟨_ | ⟨_, N⟩, A⟩, hc₁, hc₂⟩ := h; cases hc₂,
  sorry
  -- obtain hsmall | ⟨N', atom_map, hσ₁, hσ₂, hN'⟩ := σ.property.forward.atom_cond a.fst A,
  -- swap, { cases haσ ⟨_, hσ₂ a rfl, rfl⟩ },
  -- have := equiv_not_mem_atom σ a A N hsmall hc₁,
  -- exact ⟨_, le_atom_union σ a A N hc₁ hsmall hc₁, _, mem_union_right _ ⟨⟨a, rfl, haσ⟩, rfl⟩, rfl⟩,
end

end exists_ge_atom

section exists_ge_near_litter

/-!
Suppose that for a near-litter, its associated litter is already defined in `σ`, along with all of
the atoms in the symmetric difference with that litter. Then, the place the litter is supposed to
map to is already defined, and we simply add that to `σ`.
-/

variables (σ : allowable_partial_perm B) (N : near_litter) (A : extended_index B)

private def near_litter_image (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
    near_litter :=
  ⟨(near_litter_value σ A N.fst.to_near_litter hNL).fst,
    (near_litter_value σ A N.fst.to_near_litter hNL).snd.val ∆
      range (λ (a : {a // a ∈ litter_set N.fst ∆ ↑(N.snd)}),
        atom_value σ A a (ha a a.property)),
    begin
      rw [is_near_litter, is_near, small, ← symm_diff_assoc],
      exact (mk_union_le _ _).trans_lt
        (add_lt_of_lt κ_regular.aleph_0_le
          (lt_of_le_of_lt (mk_le_mk_of_subset $ diff_subset _ _)
            (near_litter_value σ A N.fst.to_near_litter hNL).snd.property)
          (lt_of_le_of_lt (mk_le_mk_of_subset $ diff_subset _ _)
            (lt_of_le_of_lt mk_range_le N.snd.property))),
    end⟩

lemma near_litter_image_spec (hNin : (inr N, A) ∈ σ.val.domain)
  (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  (inr (N, near_litter_image σ N A hN hNL ha), A) ∈ σ.val :=
begin
  unfold near_litter_image,
  rw mem_domain at hNin hNL,
  obtain ⟨⟨_ | ⟨N, N'⟩, C⟩, hNN', ⟨⟩⟩ := hNin,
  obtain ⟨⟨_ | ⟨L, M⟩, A⟩, hL, ⟨⟩⟩ := hNL,
  obtain ⟨M', hM, symm, hsy, hsd⟩ := σ.prop.forward.near_litter_cond N N' A hNN',
  have := (σ.prop.backward.one_to_one A).near_litter _ hL hM,
  subst this,
  have : ∀ a, symm a = atom_value σ A a (inl_mem_domain (hsy a))
    := λ b, (σ.prop.backward.one_to_one A).atom _ (hsy b)
      (atom_value_spec σ A b (inl_mem_domain (hsy b))),
  have that := congr_arg range (funext this).symm,
  convert hNN',
  obtain ⟨N', atoms, hN'⟩ := N',
  dsimp only at hsd, subst hsd,
  have key : near_litter_value σ A N.fst.to_near_litter (inr_mem_domain hL) = M :=
    (σ.prop.backward.one_to_one A).near_litter _
      (near_litter_value_spec σ A N.fst.to_near_litter (inr_mem_domain hL)) hL,
  have : (near_litter_value σ A N.fst.to_near_litter (inr_mem_domain hL)).fst = N',
  { rw key,
    refine is_near_litter.unique M.2.2 _,
    unfold is_near_litter is_near small at hN' ⊢,
    rw ← symm_diff_assoc at hN',
    have : ∀ (S T : set atom), # (S ∆ T : set atom) ≤ # (S ∪ T : set atom),
    { unfold symm_diff,
      intros S T,
      refine cardinal.mk_le_mk_of_subset _,
      simp only [sup_eq_union, union_subset_iff],
      exact ⟨λ x hx, or.inl hx.1, λ x hx, or.inr hx.1⟩ },
    specialize this (litter_set N' ∆ M.snd.val ∆ range symm) (range symm),
    rw [symm_diff_assoc, symm_diff_self, symm_diff_bot] at this,
    exact (this.trans $ cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt
      κ_regular.aleph_0_le hN' $ cardinal.mk_range_le.trans_lt N.2.2) },
  subst this,
  exact sigma.mk.inj_iff.2 ⟨rfl, heq_of_eq $ subtype.mk_eq_mk.2 $
    congr_arg2 _ (by { rw ←key, refl }) that⟩
end

lemma near_litter_image_spec_reverse (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (hNin : (inr (near_litter_image σ N A hN hNL ha), A) ∈
    σ.val.range) : (inr (N, near_litter_image σ N A hN hNL ha), A) ∈ σ.val :=
begin
  refine near_litter_image_spec σ N A _ hN hNL ha,
  rw mem_domain at hNL, rw spec.mem_range at hNin,
  obtain ⟨⟨_ | ⟨M, M'⟩, A⟩, hM, hMr⟩ := hNin,
  { cases hMr },
  simp only [binary_condition.range, sum.elim_inr, prod.mk.inj_iff] at hMr,
  obtain ⟨rfl, rfl⟩ := hMr, clear hMr,
  convert inr_mem_domain hM,
  -- simp only [binary_condition.domain, sum.elim_inr, prod.mk.inj_iff, eq_self_iff_true, and_true],
  obtain ⟨P, hP, symm, hsy, hsd⟩ := σ.prop.forward.near_litter_cond M _ A hM,
  have := (σ.prop.backward.one_to_one A).near_litter M hM
    (near_litter_image_spec σ M A (inr_mem_domain hM) _ (inr_mem_domain hP) $
      λ a ha, inl_mem_domain (hsy ⟨a, ha⟩)),
  { sorry },
  { /- intro H,
    have : near_litter_image σ N A hN hNL ha = near_litter_value σ A M (inr_mem_domain hM) :=
      (σ.prop.backward.one_to_one A).near_litter M hM
        (near_litter_value_spec σ A M (inr_mem_domain hM)),
    unfold near_litter_image at this,
    rw [← sigma.eta (near_litter_value σ A M ⟨_, hM, rfl⟩), sigma.mk.inj_iff] at this,
    obtain ⟨h1, h2⟩ := this, -/
    sorry }
end

def new_near_litter_cond
  (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) : spec B :=
{(inr (N, near_litter_image σ N A hN hNL ha), A)}

@[simp] lemma mem_new_near_litter_cond_iff
  (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (c : binary_condition B) :
  c ∈ σ.val ⊔ new_near_litter_cond σ N A hN hNL ha ↔
    c ∈ σ.val ∨ c = (inr (N, near_litter_image σ N A hN hNL ha), A) :=
by simp only [new_near_litter_cond, mem_sup, mem_mk, spec.mem_singleton]

@[simp] lemma mem_new_near_litter_cond_inv_iff
  (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (c : binary_condition B) :
  c ∈ (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha)⁻¹ ↔
    c ∈ σ.val⁻¹ ∨ c = (inr (near_litter_image σ N A hN hNL ha, N), A) :=
begin
  simp only [new_near_litter_cond, subtype.val_eq_coe, spec.mem_inv, mem_sup,
    mem_mk, mem_singleton_iff],
  rw [spec.mem_singleton, inv_eq_iff_inv_eq, binary_condition.inv_mk, sum.map_inr, prod.swap],
  exact ⟨λ h, or.elim h or.inl (λ h, or.inr h.symm), λ h, or.elim h or.inl (λ h, or.inr h.symm)⟩,
end

lemma near_litter_union_one_to_one_forward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  spec.one_to_one_forward (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) :=
begin
  refine λ C, ⟨λ a b hb c hc, _, λ M P hP Q hQ, _⟩,
  { rw [mem_set_of, mem_new_near_litter_cond_iff] at hb hc,
    simp only [subtype.val_eq_coe, prod.mk.inj_iff, false_and, or_false] at hb hc,
    exact (σ.prop.forward.one_to_one C).atom a hb hc },
  { simp only [new_near_litter_cond, spec.mem_mk, subtype.val_eq_coe, mem_set_of_eq, mem_sup,
      mem_singleton_iff, prod.mk.inj_iff] at hP hQ,
    obtain hP | ⟨⟨rfl, rfl⟩, rfl⟩ := hP; obtain hQ | ⟨⟨rfl, h₂⟩, h₃⟩ := hQ,
    { exact (σ.prop.forward.one_to_one C).near_litter M hP hQ },
    { sorry /- exact (σ.prop.forward.one_to_one C).near_litter _
        (near_litter_image_spec_reverse σ P C hN hNL ha (inr_mem_domain hP)) hP -/ },
    { sorry /- exact (σ.prop.forward.one_to_one C).near_litter _
        hP (near_litter_image_spec_reverse σ Q C hN hNL ha ⟨_, hP, rfl⟩) -/ },
    { refl }, }
end

lemma near_litter_union_one_to_one_backward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  spec.one_to_one_forward (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha)⁻¹ :=
begin
  refine λ C, ⟨λ a b hb c hc, _, λ M P hP Q hQ, _⟩,
  { rw [mem_set_of, mem_new_near_litter_cond_inv_iff] at hb hc,
    simp only [mem_set_of, mem_new_near_litter_cond_inv_iff, subtype.val_eq_coe, inl_mem_inv,
      prod.swap_prod_mk, prod.mk.inj_iff, false_and, or_false] at hb hc,
    exact (σ.prop.backward.one_to_one C).atom a hb hc },
  { rw [mem_set_of, mem_new_near_litter_cond_inv_iff] at hP hQ,
    sorry
    /- obtain ⟨⟨h1, h2⟩, h3⟩ | hP := hP; obtain ⟨⟨h1', h2'⟩, h3'⟩ | hQ := hQ,
    { simp at hP },
    { exact (σ.prop.backward.one_to_one A).near_litter N
        (near_litter_image_spec σ N A ⟨_, hQ, rfl⟩ hN hNL ha) hQ },
    { exact (σ.prop.backward.one_to_one A).near_litter N hP
        (near_litter_image_spec σ N A ⟨_, hP, rfl⟩ hN hNL ha) },
    { exact (σ.prop.backward.one_to_one C).near_litter M hP hQ } -/ }
end

lemma near_litter_union_atom_cond_forward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  ∀ L C, spec.atom_cond (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) L C :=
begin
  intros L C,
  obtain ⟨L', hL, atom_map, hin, himg⟩ | ⟨hL, hLsmall⟩ | ⟨L', hL, hLsmall, hmaps⟩ := σ.prop.forward.atom_cond L C,
  { exact spec.atom_cond.all L' (or.inl hL) atom_map (λ a H, or.inl $ hin a H) himg },
  refine spec.atom_cond.small_out _ _,
  { rw mem_domain,
    rintro ⟨⟨_ | ⟨N, M⟩, _⟩, hb, hdom⟩; cases hdom,
    refine or.rec (hL ∘ inr_mem_domain) (λ h, _) hb,
    cases mem_singleton_iff.1 h,
    simpa only using hN },
  swap,
  refine spec.atom_cond.small_in L' (or.inl hL) _
      (λ a b hab, or.rec (λ h, hmaps h) (λ h, by cases h) hab),
  all_goals { convert hLsmall using 1,
    refine ext (λ x, ⟨λ hx, ⟨hx.1, _⟩, λ hx, ⟨hx.1, _⟩⟩),
    { have := hx.2,
      rw mem_domain at this,
      obtain ⟨b, hb, hdom⟩ := this,
      rw mem_new_near_litter_cond_iff at hb,
      cases hb,
      { obtain ⟨as | Ns, C⟩ := b; cases hdom, convert inl_mem_domain hb, },
      { cases hb, cases hdom, } },
    { have := hx.2,
      rw mem_domain at this,
      obtain ⟨⟨as | Ns, C⟩, hb, hdom⟩ := this; cases hdom,
      exact or.inl (mem_domain_of_mem hb), } }
end

lemma near_litter_union_atom_cond_backward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  ∀ L C, spec.atom_cond (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha)⁻¹ L C :=
begin
  intros L C,
  obtain ⟨L', hL, atom_map, hin, himg⟩ | ⟨hL, hLsmall⟩ | ⟨L', hL, hLsmall, hmaps⟩ := σ⁻¹.prop.forward.atom_cond L C,
  { exact spec.atom_cond.all L' (or.inl hL) atom_map (λ a H, or.inl $ hin a H) himg },
  sorry {
    refine spec.atom_cond.small_out _ _,
    { rintro ⟨⟨_ | ⟨N, M⟩, _⟩, hb, hdom⟩; cases hdom,
      refine or.rec (λ h, hL ⟨_, h, rfl⟩) (λ h, _) hb,
      simp only [has_inv.inv, mem_singleton_iff, sum.elim_inr, prod.mk.inj_iff] at h,
      obtain ⟨⟨rfl, hLM : L.to_near_litter = near_litter_image σ M A hN hNL ha⟩, rfl⟩ := h,
      rw hLM at hL,
      sorry },
    convert hLsmall using 1,
    refine ext (λ x, ⟨λ hx, ⟨hx.1, _⟩, λ hx, ⟨hx.1, _⟩⟩),
    { obtain ⟨b, hb, hdom⟩ := hx.2,
      refine ⟨b, or.rec id (λ h, _) hb, hdom⟩,
      obtain ⟨⟨_, _⟩ | ⟨_, _⟩, _⟩ := b;
      simp only [mem_singleton_iff, has_inv.inv, sum.elim_inl, sum.elim_inr] at h; cases h,
      cases hdom },
    { obtain ⟨-, b, hb, hdom⟩ := hx,
      refine ⟨b, or.inl hb, hdom⟩ } },
  sorry { refine spec.atom_cond.small_in L' (or.inl hL) _
      (λ a b hab, or.rec (λ h, hmaps h) (λ h, by cases h) hab),
    convert hLsmall using 1,
    refine ext (λ x, ⟨λ hx, ⟨hx.1, _⟩, λ hx, ⟨hx.1, _⟩⟩),
    { obtain ⟨b, hb, hdom⟩ := hx.2,
      refine ⟨b, or.rec id (λ h, _) hb, hdom⟩,
      obtain ⟨⟨_, _⟩ | ⟨_, _⟩, _⟩ := b;
      simp only [mem_singleton_iff, has_inv.inv, sum.elim_inl, sum.elim_inr] at h; cases h,
      cases hdom },
    { obtain ⟨-, b, hb, hdom⟩ := hx,
      refine ⟨b, or.inl hb, hdom⟩ } }
end

lemma near_litter_union_near_litter_cond_forward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  ∀ N₁ N₂ C, spec.near_litter_cond
    (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) N₁ N₂ C :=
begin
  rintro N₁ N₂ C (h | h),
  { obtain ⟨M, hM₁, sd, hsd₁, hsd₂⟩ := σ.property.forward.near_litter_cond N₁ N₂ C h,
    exact ⟨M, or.inl hM₁, sd, λ a, or.inl (hsd₁ a), hsd₂⟩ },
  cases h,
  rw mem_domain at hNL,
  obtain ⟨⟨atoms | ⟨N₃, N₄⟩, C⟩, hc₁, hc₂⟩ := hNL; cases hc₂,
  refine ⟨N₄, or.inl hc₁, λ a, atom_value σ A a (ha a a.property), _, _⟩,
  { exact λ a, or.inl (atom_value_spec σ A a (ha a a.property)) },
  { suffices : near_litter_value σ A N.fst.to_near_litter (inr_mem_domain hc₁) = N₄,
    { convert rfl; rw ←this; refl },
    have := near_litter_value_spec σ A N.fst.to_near_litter (inr_mem_domain hc₁),
    exact (σ.property.backward.one_to_one A).near_litter N.fst.to_near_litter this hc₁ }
end

lemma near_litter_union_near_litter_cond_backward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  ∀ N₁ N₂ C, spec.near_litter_cond
    (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha)⁻¹ N₁ N₂ C :=
begin
  rintro N₁ N₂ C (h | h),
  { obtain ⟨M, hM₁, sd, hsd₁, hsd₂⟩ := σ.property.backward.near_litter_cond N₁ N₂ C h,
    exact ⟨M, or.inl hM₁, sd, λ a, or.inl (hsd₁ a), hsd₂⟩ },
  sorry
end

lemma near_litter_union_non_flexible_cond_forward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  spec.non_flexible_cond B (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) :=
begin
  rintro β δ γ hγ hδ hγδ N₁ C t (ht | ht) ρ hρ,
  { exact σ.property.forward.non_flexible_cond hγ hδ hγδ N₁ C t ht ρ
      (hρ.mono $ subset_union_left _ _) },
  cases ht, cases hN rfl,
end

lemma near_litter_union_non_flexible_cond_backward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  spec.non_flexible_cond B (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha)⁻¹ :=
begin
  rintro β δ γ hγ hδ hγδ N₁ C t (ht | ht) ρ hρ,
  { exact σ.property.backward.non_flexible_cond hγ hδ hγδ N₁ C t ht ρ
      (hρ.mono $ subset_union_left _ _) },
  simp only [binary_condition.inv_mk, sum.map_inr, prod.swap_prod_mk, mem_singleton_iff,
    prod.mk.inj_iff] at ht,
  exfalso, -- This isn't true because N is never a litter.
  sorry
end

lemma near_litter_union_support_closed_forward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha).domain.support_closed B :=
begin
  intros β δ γ hγ hδ hγδ C t ht,
  rw spec.domain_sup at ht ⊢,
  rw unary_spec.lower_union,
  cases ht,
  { exact (σ.property.forward.support_closed hγ hδ hγδ C t ht).mono (subset_union_left _ _) },
  simp only [mem_domain, prod.exists, prod.mk.inj_iff, binary_condition.domain_mk,
    exists_eq_right_right, sum.exists, exists_false, sum.map_inr, exists_and_distrib_right,
    exists_eq_right, false_or, map_inl, and_false] at ht,
  obtain ⟨N', ht⟩ := ht, cases ht,
  cases hN rfl,
end

lemma near_litter_union_support_closed_backward (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain) :
  (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha).range.support_closed B :=
sorry

lemma near_litter_union_flexible_cond (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (image_not_flexible :
    ∀ L, litter_set L = (near_litter_image σ N A hN hNL ha).snd.val → ¬ flexible L A) (C) :
  spec.flexible_cond B (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) C :=
begin
  obtain (⟨hdom, hrge⟩ | ⟨hdom, hrge⟩) := σ.property.flexible_cond C,
  { refine spec.flexible_cond.co_large _ _,
    { convert hdom, ext L, split; rintro ⟨hC₁, hC₂⟩; refine ⟨hC₁, λ h, _⟩,
      { rw spec.domain_sup at hC₂, exact hC₂ (or.inl h) },
      { rw spec.domain_sup at h,
        cases h,
        { exact hC₂ h },
        { rw spec.mem_domain at h,
          obtain ⟨c, hc₁, hc₂⟩ := h,
          cases hc₁, cases hc₂,
          exact hN rfl } } },
    { convert hrge, ext L, split; rintro ⟨hC₁, hC₂⟩; refine ⟨hC₁, λ h, _⟩,
      { rw spec.range_sup at hC₂, exact hC₂ (or.inl h) },
      { simp only [subtype.val_eq_coe, spec.mem_range, prod.exists, binary_condition.range_mk,
          prod.mk.inj_iff, exists_eq_right_right, sum.exists, sum.map_inl, and_false, exists_false,
          sum.map_inr, exists_eq_right, false_or, mem_sup] at h,
        obtain ⟨N', (h | h)⟩ := h,
        { exact hC₂ (inr_mem_range h) },
        unfold new_near_litter_cond at h,
        simp only [mem_mk, spec.mem_singleton, prod.mk.inj_iff] at h,
        cases h.2,
        refine image_not_flexible L _ hC₁,
        rw ←h.1.2,
        refl, } } },
  { refine spec.flexible_cond.all (λ L hL, _) (λ L hL, _),
    { rw spec.domain_sup, exact or.inl (hdom L hL) },
    { rw spec.range_sup, exact or.inl (hrge L hL) } }
end

lemma near_litter_union_allowable (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (image_not_flexible :
    ∀ L, litter_set L = (near_litter_image σ N A hN hNL ha).snd.val → ¬ flexible L A) :
  spec.allowable B (σ.val ⊔ new_near_litter_cond σ N A hN hNL ha) :=
{ forward :=
  { one_to_one := near_litter_union_one_to_one_forward σ N A hN hNL ha,
    atom_cond := near_litter_union_atom_cond_forward σ N A hN hNL ha,
    near_litter_cond := near_litter_union_near_litter_cond_forward σ N A hN hNL ha,
    non_flexible_cond := near_litter_union_non_flexible_cond_forward σ N A hN hNL ha,
    support_closed := near_litter_union_support_closed_forward σ N A hN hNL ha },
  backward :=
  { one_to_one := near_litter_union_one_to_one_backward σ N A hN hNL ha,
    atom_cond := near_litter_union_atom_cond_backward σ N A hN hNL ha,
    near_litter_cond := near_litter_union_near_litter_cond_backward σ N A hN hNL ha,
    non_flexible_cond := near_litter_union_non_flexible_cond_backward σ N A hN hNL ha,
    support_closed := by { rw spec.domain_inv,
      exact near_litter_union_support_closed_backward σ N A hN hNL ha } },
  flexible_cond := near_litter_union_flexible_cond σ N A hN hNL ha image_not_flexible }

/-- We take the additional hypothesis that the near-litter that we're mapping do does not happen
to be a flexible litter. This will always be true, but it is convenient to assume at this point. -/
lemma le_near_litter_union (hN : litter_set N.fst ≠ N.snd)
  (hNL : (inr N.fst.to_near_litter, A) ∈ σ.val.domain)
  (ha : ∀ (a : atom), a ∈ litter_set N.fst ∆ ↑(N.snd) → (inl a, A) ∈ σ.val.domain)
  (image_not_flexible :
    ∀ L, litter_set L = (near_litter_image σ N A hN hNL ha).snd.val → ¬ flexible L A) :
  σ ≤ ⟨σ.val ⊔ new_near_litter_cond σ N A hN hNL ha,
    near_litter_union_allowable σ N A hN hNL ha image_not_flexible⟩ := {
  le := subset_union_left _ _,
  all_flex_domain := begin
    rintro L N' C hN' hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { cases hσ₂, cases hN rfl }
  end,
  all_flex_range := begin
    rintro L N' C hN' hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { simp only [new_near_litter_cond, coe_singleton, mem_singleton_iff, prod.mk.inj_iff] at hσ₂,
      obtain ⟨⟨rfl, hσ₂⟩, rfl⟩ := hσ₂,
      cases image_not_flexible L _ hN',
      rw ←hσ₂,
      refl }
  end,
  all_atoms_domain := begin
    intros b₁ b₂ L hb₁ C hC₁ hC₂ c hc',
    cases hC₂,
    { cases hC₁ hC₂ },
    { exfalso, simpa only [new_near_litter_cond, coe_singleton, mem_singleton_iff,
        prod.mk.inj_iff, false_and] using hC₂ },
  end,
  all_atoms_range := begin
    intros b₁ b₂ L hb₁ C hC₁ hC₂ c hc',
    cases hC₂,
    { cases hC₁ hC₂ },
    { exfalso, simpa only [new_near_litter_cond, coe_singleton, mem_singleton_iff,
        prod.mk.inj_iff, false_and] using hC₂ },
  end }

/-- If everything that constrains a near litter lies in `σ`, we can add the near litter to `σ`,
giving a new allowable partial permutation `ρ ≥ σ`. -/
lemma exists_ge_near_litter (hN : litter_set N.fst ≠ N.snd)
  (hσ : ∀ c, c ≺ (⟨inr N, A⟩ : support_condition B) → c ∈ σ.val.domain) :
  ∃ ρ ≥ σ, (⟨inr N, A⟩ : support_condition B) ∈ ρ.val.domain :=
begin
  have hNL := hσ (inr N.fst.to_near_litter, A) (constrains.near_litter N hN A),
  have ha := λ a ha, hσ (inl a, A) (constrains.symm_diff N a ha A),
  by_cases image_not_flexible :
    ∀ L, litter_set L = (near_litter_image σ N A hN hNL ha).snd.val → ¬ flexible L A,
  { refine ⟨_, le_near_litter_union σ N A hN hNL ha image_not_flexible, _⟩,
    rw mem_domain,
    refine ⟨_, mem_union_right _ rfl, rfl⟩, },
  { -- Seek a contradiction (discuss this with Peter).
    push_neg at image_not_flexible,
    obtain ⟨L, hL₁, hL₂⟩ := image_not_flexible,
    sorry }
end

end exists_ge_near_litter

section exists_ge_flexible

/-!
When we want to add an `A`-flexible litter to `σ`, we will just add all of them in an arbitrary
bijection. This will always exist because the sets are both of size `μ`. This will create a
*rough bijection*. This is not necessarily compatible with `σ`, because we may already have
specified where certain atoms in these litters are mapped to or from.

To remedy this, for each `A`-flexible litter we create a *precise atom bijection* mapping all of the
unassigned atoms in the domain of `σ` to all of the unassigned atoms in the range of `σ` in the
litter obtained under the rough bijection.

We extend `σ` by saying that each `A`-flexible litter is mapped to the image of the precise atom
bijection map, together with the image of all of the atoms that were already specified. This is a
near-litter, which is near to the litter obtained using the rough bijection. The same procedure is
done in the reverse direction with the same bijections, so that all of the `A`-flexible litters are
now defined in this new allowable partial permutation.
-/

variables {B} (A : extended_index B) {σ : allowable_partial_perm B} {dom rge : unary_spec B}

/-- A bijection of the remaining `A`-flexible litters in an allowable partial permutation `σ`.
This is a bijection of *rough images*; we have to then take into account all of the exceptions that
have already been established in `σ`. -/
abbreviation rough_bijection (dom rge : unary_spec B) :=
{L : litter // flexible L A ∧ (inr L.to_near_litter, A) ∉ dom} ≃
{L : litter // flexible L A ∧ (inr L.to_near_litter, A) ∉ rge}

variables {A}

namespace rough_bijection
variables {bij : rough_bijection A σ.val.domain σ.val.range}

def inv' (bij : rough_bijection A σ.val.domain σ.val.range) :
  rough_bijection A σ⁻¹.val.domain σ⁻¹.val.range :=
{ to_fun := λ L, ⟨bij.inv_fun ⟨L, L.2.1, by simpa only [val_inv, spec.domain_inv] using L.2.2⟩,
    (bij.inv_fun _).2.1,
    (by simpa only [val_inv, spec.range_inv] using (bij.inv_fun _).2.2)⟩,
  inv_fun := λ L, ⟨bij ⟨L, L.2.1, by simpa only [val_inv, spec.range_inv] using L.2.2⟩, (bij _).2.1,
    (by simpa only [val_inv, spec.domain_inv] using (bij _).2.2)⟩,
  left_inv := begin
    rintro ⟨L, hL₁, hL₂⟩,
    refine coe_injective _,
    simp only [subtype.coe_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.apply_symm_apply],
  end,
  right_inv := begin
    rintro ⟨L, hL₁, hL₂⟩,
    refine coe_injective _,
    simp only [subtype.coe_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply],
  end }

@[simp] lemma inv'_to_fun {L} :
  (bij.inv'.to_fun L : litter) =
    bij.inv_fun ⟨L, L.2.1, by simpa only [val_inv, spec.domain_inv] using L.2.2⟩ :=
coe_injective rfl

@[simp] lemma inv'_to_fun_mk {L hL} :
  (bij.inv' ⟨L, hL⟩ : litter) =
    bij.inv_fun ⟨L, hL.1, by simpa only [val_inv, spec.domain_inv] using hL.2⟩ :=
coe_injective rfl

lemma inv'_inv : bij.inv'.symm == bij := sorry

end rough_bijection

lemma small_of_not_mem_spec
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain}) :
  small {a ∈ litter_set L | (inl a, A) ∈ σ.val.domain} :=
begin
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ := σ.property.forward.atom_cond L A,
  { cases L.property.2 ⟨_, h₁, rfl⟩ },
  { exact h₂ },
  { exact h₁ },
end

lemma small_of_rough_bijection (bij : rough_bijection A σ.val.domain σ.val.range)
  (L : {L : litter // flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain}) :
  small {a ∈ litter_set (bij L) | (inl a, A) ∈ σ.val.range} :=
begin
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ := σ.property.backward.atom_cond
    (bij L) A,
  { exfalso, rw spec.inr_mem_inv at h₁,
    obtain ⟨hC, hn⟩ := (bij L).property, exact hn ⟨_, h₁, rfl⟩ },
  { rw spec.domain_inv at h₂, exact h₂ },
  { rw spec.domain_inv at h₁, exact h₁ }
end

namespace rough_bijection

/-- Suppose a flexible litter `L` is mapped to another flexible litter `L₁` under the rough
bijection defined above. We construct a bijection between the atoms not yet specified in `L` and
`L₁`. This yields a precise near-litter image of each flexible litter `L`. -/
def precise_atom_bijection (bij : rough_bijection A dom rge)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ dom}) :=
↥{a ∈ litter_set L | (inl a, A) ∉ dom} ≃
  ↥{a ∈ litter_set (bij L) | (inl a, A) ∉ rge}

namespace precise_atom_bijection

/-- The inverse of a rough bijection is a rough bijection for the inverse permutation. -/
def symm {bij : rough_bijection A dom rge} {L} (abij : bij.precise_atom_bijection L) :
  precise_atom_bijection bij.symm (bij L) :=
{ to_fun := λ a, ⟨abij.inv_fun a,
    (by simpa only [equiv.symm_apply_apply] using (abij.inv_fun a).2.1), (abij.inv_fun a).2.2⟩,
  inv_fun := λ a, abij.to_fun ⟨a, (by simpa only [equiv.symm_apply_apply] using a.2.1), a.2.2⟩,
  left_inv := begin
    rintro ⟨a, ha₁, ha₂⟩,
    simp only [equiv.inv_fun_as_coe, subtype.coe_mk, subtype.coe_eta, equiv.to_fun_as_coe,
      equiv.apply_symm_apply],
  end,
  right_inv := begin
    rintro ⟨a, ha₁, ha₂⟩,
    simp only [subtype.coe_mk, equiv.to_fun_as_coe, equiv.inv_fun_as_coe, equiv.symm_apply_apply,
      subtype.mk_eq_mk],
  end }

def inv {σ : allowable_partial_perm B} {bij : rough_bijection A σ.val.domain σ.val.range} {L}
  (abij : bij.precise_atom_bijection (bij.inv_fun L)) :
    bij.inv'.precise_atom_bijection
      ⟨L, L.2.1, by simpa only [val_inv, spec.domain_inv] using L.2.2⟩ := {
  to_fun := λ a, ⟨abij.inv_fun ⟨a,
    by simpa only [equiv.inv_fun_as_coe, equiv.to_fun_as_coe, equiv.apply_symm_apply] using a.2.1,
    by simpa only [val_inv, spec.domain_inv] using a.2.2⟩,
    begin
      convert (abij.inv_fun ⟨a, _, _⟩).2.1 using 2,
      simp only [equiv.inv_fun_as_coe, subtype.coe_eta, rough_bijection.inv'_to_fun_mk],
    end, by { convert (abij.inv_fun ⟨a, _, _⟩).2.2 using 2, rw [val_inv, spec.range_inv] }⟩,
  inv_fun := λ a, ⟨abij.to_fun ⟨a,
    by simpa only [rough_bijection.inv'_to_fun_mk, subtype.coe_eta] using a.2.1,
    by simpa only [val_inv, spec.range_inv] using a.2.2⟩,
    begin
      convert (abij.to_fun ⟨a, _, _⟩).2.1 using 2,
      simp only [subtype.coe_mk, equiv.inv_fun_as_coe, equiv.apply_symm_apply],
    end, by { convert (abij.to_fun ⟨a, _, _⟩).2.2 using 2, rw [val_inv, spec.domain_inv] }⟩,
  left_inv := begin
    rintro ⟨a, ha₁, ha₂⟩,
    simp only [subtype.coe_eta, subtype.coe_mk, equiv.inv_fun_as_coe, equiv.to_fun_as_coe,
      equiv.apply_symm_apply, subtype.mk_eq_mk],
  end,
  right_inv := begin
    rintro ⟨a, ha₁, ha₂⟩,
    simp only [equiv.inv_fun_as_coe, equiv.to_fun_as_coe, subtype.coe_eta, subtype.coe_mk,
      equiv.symm_apply_apply, subtype.mk_eq_mk],
  end }

end precise_atom_bijection

/-- If the image of this atom has already been specified by `σ`, return the value that was already
given. Otherwise, return the image generated by `precise_image_bijection`. -/
private def precise_atom_image {dom rge} (bij : rough_bijection A dom rge)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ dom})
  (abij : bij.precise_atom_bijection L)
  (atom_value : {a : litter_set L // (inl a.val, A) ∈ dom} → atom)
  (a : atom) (ha : a ∈ litter_set L) : atom :=
@dite _ ((inl a, A) ∈ dom) (classical.dec _)
  (λ h, atom_value ⟨⟨a, ha⟩, h⟩)
  (λ h, abij.to_fun ⟨a, ha, h⟩)

lemma precise_atom_image_range {dom rge} (bij : rough_bijection A dom rge)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ dom})
  (abij : bij.precise_atom_bijection L)
  (atom_value : {a : litter_set L // (inl a.val, A) ∈ dom} → atom) :
  range (λ a : litter_set L, precise_atom_image bij L abij atom_value a a.property) =
    (litter_set (bij L) ∩ {a | (inl a, A) ∉ rge}) ∪ range atom_value :=
begin
  unfold precise_atom_image,
  ext a,
  split,
  { rintro ⟨b, hb⟩, dsimp only at hb,
    split_ifs at hb,
    { simp_rw subtype.coe_eta at hb, exact or.inr ⟨⟨b, h⟩, hb⟩ },
    { rw ← hb,
      exact or.inl (abij.to_fun ⟨b, _⟩).property } },
  rintro (⟨ha₁, ha₂⟩ | ⟨b, hb⟩),
  { rw mem_set_of at ha₂,
    set b := abij.inv_fun ⟨a, ha₁, ha₂⟩ with hb,
    refine ⟨⟨b, b.property.left⟩, _⟩,
    dsimp only,
    split_ifs,
    { cases b.property.right h },
    { simp only [hb, equiv.inv_fun_as_coe, subtype.coe_mk,
        subtype.coe_eta, equiv.to_fun_as_coe, equiv.apply_symm_apply] } },
  { refine ⟨b, _⟩,
    dsimp only,
    split_ifs,
    { simp_rw subtype.coe_eta, exact hb },
    { cases h b.property } }
end

/-- The precise image of a flexible litter under the new allowable permutation. -/
private def precise_litter_image_aux {dom rge} (bij : rough_bijection A dom rge)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ dom})
  (abij : bij.precise_atom_bijection L)
  (atom_value : {a : litter_set L // (inl a.val, A) ∈ dom} → atom)
  (h₁ : # ↥(litter_set ↑(bij L) \ {a : atom | (inl a, A) ∉ rge}) < # κ)
  (h₂ : # {a : litter_set L // (inl a.val, A) ∈ dom} < # κ) : near_litter :=
⟨(bij L),
  range (λ (a : litter_set L), precise_atom_image bij L abij atom_value a a.property),
  begin
    rw precise_atom_image_range,
    unfold is_near_litter is_near small symm_diff,
    refine (cardinal.mk_union_le _ _).trans_lt (cardinal.add_lt_of_lt κ_regular.aleph_0_le _ _),
    { rw [← sup_eq_union, sdiff_sup, ← inf_eq_inter, sdiff_inf_self_left],
      exact lt_of_le_of_lt (cardinal.mk_le_mk_of_subset $ inter_subset_left _ _) h₁ },
    { rw [← sup_eq_union, sup_sdiff, ← inf_eq_inter, inf_sdiff, sdiff_self, bot_inf_eq,
        bot_sup_eq],
      refine lt_of_le_of_lt (cardinal.mk_le_mk_of_subset $ @sdiff_le _ _ (litter_set _) _) _,
      exact lt_of_le_of_lt cardinal.mk_range_le h₂ },
end⟩

private lemma precise_litter_image_aux_inj {bij : rough_bijection A σ.val.domain σ.val.range}
  {L₁ L₂ : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain}}
  {abij₁ : bij.precise_atom_bijection L₁} {abij₂ : bij.precise_atom_bijection L₂}
  {atom_value₁ : {a : litter_set L₁ // (inl a.val, A) ∈ σ.val.domain} → atom}
  {atom_value₂ : {a : litter_set L₂ // (inl a.val, A) ∈ σ.val.domain} → atom}
  {h₁ h₂ h₃ h₄} :
  precise_litter_image_aux bij L₁ abij₁ atom_value₁ h₁ h₂ =
  precise_litter_image_aux bij L₂ abij₂ atom_value₂ h₃ h₄ →
    L₁ = L₂ :=
begin
  intro h,
  have := congr_arg sigma.fst h,
  simpa only [precise_litter_image_aux, subtype.coe_inj, equiv.to_fun_as_coe,
    embedding_like.apply_eq_iff_eq] using this,
end

def precise_litter_image (bij : rough_bijection A σ.val.domain σ.val.range)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain})
  (abij : bij.precise_atom_bijection L) : near_litter :=
precise_litter_image_aux bij L abij (λ a, atom_value σ A a.1 a.2)
  (begin
    convert small_of_rough_bijection bij L,
    ext a,
    split,
    { rintro ⟨ha₁, ha₂⟩, simp only [mem_set_of_eq, not_not_mem] at ha₂, exact ⟨ha₁, ha₂⟩ },
    { rintro ⟨ha₁, ha₂⟩, exact ⟨ha₁, function.eval ha₂⟩ }
  end)
  (by { convert small_of_not_mem_spec L using 1, rw cardinal.mk_sep, refl })

def precise_litter_inverse_image (bij : rough_bijection A σ.val.domain σ.val.range)
  (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.range})
  (abij : precise_atom_bijection bij.symm L) :
  near_litter :=
precise_litter_image_aux bij.symm L abij
  (λ a, atom_value σ⁻¹ A a.1 (by simpa only [val_inv, spec.domain_inv] using a.2))
  (begin
    convert small_of_rough_bijection bij.inv'
      ⟨L.1, L.2.1, by simpa only [val_inv, spec.domain_inv] using L.2.2⟩,
    ext a, split,
    { rintro ⟨ha₁, ha₂⟩, simp only [mem_set_of_eq, not_not_mem] at ha₂,
      refine ⟨_, by rwa [val_inv, spec.range_inv]⟩,
      rw [← equiv.symm_symm bij.inv'],
      convert ha₁ using 2,
      sorry },
    { rintro ⟨ha₁, ha₂⟩,
      sorry /- exact ⟨ha₁, function.eval ha₂⟩, -/ }
  end)
  (begin
    convert small_of_not_mem_spec ⟨L.1, L.2.1, _⟩ using 1,
    sorry, sorry, sorry
  end)

lemma precise_litter_image_inj {bij : rough_bijection A σ.val.domain σ.val.range}
  {L₁ L₂ : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain}}
  (abij₁ : bij.precise_atom_bijection L₁) (abij₂ : bij.precise_atom_bijection L₂) :
  precise_litter_image bij L₁ abij₁ = precise_litter_image bij L₂ abij₂ → L₁ = L₂ :=
precise_litter_image_aux_inj

lemma precise_litter_inverse_image_inj {bij : rough_bijection A σ.val.domain σ.val.range}
  {L₁ L₂ : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.range}}
  (abij₁ : precise_atom_bijection bij.symm L₁) (abij₂ : precise_atom_bijection bij.symm L₂) :
  precise_litter_inverse_image bij L₁ abij₁ = precise_litter_inverse_image bij L₂ abij₂ → L₁ = L₂ :=
sorry

def new_flexible_litters (bij : rough_bijection A σ.val.domain σ.val.range)
  (abij : ∀ L, bij.precise_atom_bijection L) :
  spec B :=
{c | ∃ (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ.val.domain}),
  c = (inr (L.1.to_near_litter, precise_litter_image bij L (abij L)), A)}

def new_inverse_flexible_litters (bij : rough_bijection A σ.val.domain σ.val.range)
  (abij : ∀ L, bij.precise_atom_bijection L) :
  spec B :=
{c | ∃ L, c = (inr (precise_litter_inverse_image bij _ (abij L).symm, (bij L).1.to_near_litter),
  A)}

end rough_bijection

open rough_bijection

variables (bij : rough_bijection A σ.val.domain σ.val.range)
  (abij : ∀ L, bij.precise_atom_bijection L)

lemma flexible_union_one_to_one :
  spec.one_to_one_forward
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) :=
begin
  refine λ C, ⟨_, _⟩,
  { rintro b a₁ ((ha₁ | ha₁) | ha₁) a₂ ha₂,
    { obtain ((ha₂ | ha₂) | ha₂) := ha₂,
      { exact (σ.property.forward.one_to_one C).atom b ha₁ ha₂ },
      { simpa only [new_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and,
          exists_false] using ha₂ },
      { simpa only [new_inverse_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and,
          exists_false] using ha₂ } },
    { simpa only [new_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and,
          exists_false] using ha₁ },
    { simpa only [new_inverse_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and,
        exists_false] using ha₁ } },
  rintro N M₁ ((hM₁ | hM₁) | hM₁) M₂ ((hM₂ | hM₂) | hM₂),
  { exact (σ.property.forward.one_to_one C).near_litter N hM₁ hM₂ },
  { obtain ⟨N', hN'₁, hN'₂⟩ := σ.property.backward.near_litter_cond _ _ C hM₁,
    obtain ⟨L', hL'⟩ := hM₂, cases hL',
    cases (bij L').property.right ⟨_, hN'₁, _⟩,
    congr' },
  { obtain ⟨L', hL'⟩ := hM₂, cases hL',
    cases (bij L').property.right ⟨_, hM₁, _⟩,
    congr' },
  { exfalso,
    sorry },
  { obtain ⟨L₁, hL₁⟩ := hM₁, obtain ⟨L₂, hL₂⟩ := hM₂,
    cases precise_litter_image_inj _ _
      ((prod.ext_iff.1 $ inr_injective (prod.ext_iff.1 hL₁).1).2.symm.trans
        (prod.ext_iff.1 $ inr_injective (prod.ext_iff.1 hL₂).1).2),
    cases hL₁, cases hL₂, refl },
  { obtain ⟨L₁, hL₁⟩ := hM₁, obtain ⟨L₂, hL₂⟩ := hM₂,
    sorry },
  { obtain ⟨L₁, hL₁⟩ := hM₁,
    obtain ⟨N', hN'₁, hN'₂⟩ := σ.property.backward.near_litter_cond _ _ C hM₂,
    sorry },
  { sorry },
  obtain ⟨L₁, hL₁⟩ := hM₁, obtain ⟨L₂, hL₂⟩ := hM₂,
  unfold precise_litter_inverse_image at hL₁ hL₂,
  have := precise_litter_inverse_image_inj (abij L₁).symm (abij L₂).symm _,
  rw embedding_like.apply_eq_iff_eq at this,
  cases this, cases hL₁, cases hL₂, refl,
  have := litter.to_near_litter_injective
    ((prod.ext_iff.1 $ inr_injective (prod.ext_iff.1 hL₁).1).2.symm.trans
      (prod.ext_iff.1 $ inr_injective (prod.ext_iff.1 hL₂).1).2),
  rw [subtype.val_inj, embedding_like.apply_eq_iff_eq] at this,
  cases this,
  refl,
end

lemma flexible_union_atoms_eq (L : litter) (C : extended_index B) :
  {a ∈ litter_set L | (inl a, C) ∈
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij).domain} =
  {a ∈ litter_set L | (inl a, C) ∈ σ.val.domain} :=
begin
  ext a,
  simp only [spec.domain_sup, new_flexible_litters, new_inverse_flexible_litters,
    subtype.val_eq_coe, mem_set_of_eq, set_coe.exists, subtype.coe_mk, equiv.to_fun_as_coe,
    mem_union_eq, mem_sep_iff],
  refine and_congr_right (λ ha, ⟨_, λ h, or.inl $ or.inl h⟩),
  rintro ((h | ⟨⟨as | Ns, C⟩, ⟨L, hL, hc⟩, h⟩) | ⟨⟨as | Ns, C⟩, ⟨L, hL, hc⟩, h⟩),
  { exact h },
  { cases hc },
  { cases h },
  { cases hc },
  { cases h }
end

lemma flexible_union_atom_cond (L C) :
  spec.atom_cond
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) L C :=
begin
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ := σ.prop.forward.atom_cond L C,
  { exact spec.atom_cond.all N
      (or.inl $ or.inl h₁) atom_map (λ a H, or.inl $ or.inl $ h₂ a H) h₃ },
  { obtain rfl | h := eq_or_ne A C,
    { by_cases flexible L A,
      { refine spec.atom_cond.small_in _ (or.inl $ or.inr ⟨⟨L, h, h₁⟩, rfl⟩) _ _,
        { rwa flexible_union_atoms_eq },
        rintro a b ((hab | ⟨L', ⟨⟩⟩) | ⟨L', ⟨⟩⟩),
        sorry
        -- refine ⟨⟨a, ha⟩, _⟩,
        -- unfold precise_atom_image,
        -- rw dif_pos _,
        -- exact atom_value_eq_of_mem _ _ _ _ _ hab
         },
      refine spec.atom_cond.small_out _ (by rwa flexible_union_atoms_eq),
      contrapose! h₁, rw [spec.domain_sup, spec.domain_sup] at h₁,
      obtain ((_ | _) | _) := h₁,
      { exact h₁ },
      { obtain ⟨_, ⟨L', rfl⟩, h₁⟩ := h₁, cases h₁, cases h L'.2.1 },
      obtain ⟨_, ⟨L', rfl⟩, h₁⟩ := h₁,
      simp only [binary_condition.domain_mk, sum.map_inr, prod.mk.inj_iff, eq_self_iff_true,
        and_true] at h₁,
      suffices : L = L',
      { subst this, cases h L'.2.1 },
      convert (congr_arg sigma.fst h₁).symm,
      simp only [equiv.symm_apply_apply] },
    { refine spec.atom_cond.small_out _ _,
      { contrapose! h₁, rw [spec.domain_sup, spec.domain_sup] at h₁,
        obtain ((_ | _) | _) := h₁,
        { exact h₁ },
        { obtain ⟨_, ⟨L', rfl⟩, ⟨⟩⟩ := h₁, cases h rfl },
        { obtain ⟨_, ⟨L', rfl⟩, h₁⟩ := h₁, cases congr_arg prod.snd h₁, cases h rfl } },
      convert h₂ using 1,
      refine ext (λ a, ⟨_, λ ha, ⟨ha.1, _⟩⟩),
      { rintro ⟨hL, ⟨⟨x, y⟩ | _, b⟩, (hxy | hxy) | hxy, ha⟩; cases ha,
        { exact ⟨hL, _, hxy, rfl⟩ },
        all_goals { obtain ⟨_, _, _, _, h⟩ := hxy } },
      { simp only [spec.domain_sup, mem_union_eq],
        exact or.inl (or.inl ha.2) } } },
  { refine spec.atom_cond.small_in N (or.inl $ or.inl hN) _ _,
    { rw flexible_union_atoms_eq, exact h₁ },
    rintro a b ((hab | ⟨L', ⟨⟩⟩) | ⟨L', ⟨⟩⟩),
    exact h₂ hab }
end

lemma flexible_union_near_litter_cond :
  ∀ N₁ N₂ C, spec.near_litter_cond
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) N₁ N₂ C :=
sorry

-- lemma unpack_coh_cond ⦃β : Λ⦄
--   ⦃γ : type_index⦄
--   ⦃δ : Λ⦄
--   (hγβ : γ < ↑β)
--   (hδβ : δ < β)
--   (hδγ : γ ≠ ↑δ)
--   (p : path ↑B ↑β)
--   (t : tangle_path ↑(lt_index.mk' hγβ (B.path.comp p)))
--   (π : allowable_path B) :
--   derivative ((p.cons $ coe_lt_coe.mpr hδβ).cons (bot_lt_coe _)) π.to_struct_perm •
--       (f_map_path hγβ hδβ t).to_near_litter =
--     (f_map_path hγβ hδβ $ (π.derivative_comp B p).derivative hγβ
--       {index := ↑β, path := B.path.comp p} • t).to_near_litter :=
-- begin
--   sorry,
-- end

lemma flexible_union_non_flexible_cond :
  spec.non_flexible_cond B
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) :=
begin
  unfold spec.non_flexible_cond,
  intros hb hg hd hgb hdb hdg hNl hp ht hf π h1,
  unfold struct_perm.satisfies struct_perm.satisfies_cond at h1,
  have h := h1 hf,
  dsimp at h,
  rw ← h,
  sorry
  -- exact unpack_coh_cond hgb hdb hdg hp ht π,
end

lemma flexible_union_support_closed :
  (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij)
    .domain.support_closed B :=
sorry

lemma flexible_union_flexible_cond (C) :
  spec.flexible_cond B
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) C :=
begin
  obtain rfl | h := eq_or_ne C A,
  { refine spec.flexible_cond.all (λ L hL, _) (λ L hL, _),
    { by_cases h : ((inr L.to_near_litter, C) ∈ σ.val.domain);
        rw [spec.domain_sup, spec.domain_sup, mem_union, mem_union]; left,
      { left, exact h },
      right,
      refine ⟨(inr (L.to_near_litter, precise_litter_image bij ⟨L, hL, h⟩ (abij ⟨L, hL, h⟩)), C),
        _, rfl⟩,
      simp only [new_flexible_litters, subtype.val_eq_coe, mem_set_of_eq, set_coe.exists,
        subtype.coe_mk, prod.mk.inj_iff, eq_self_iff_true, and_true, exists_and_distrib_left],
      exact ⟨L, rfl, ⟨⟨hL, h⟩, rfl⟩⟩ },
    { -- might want to switch naming around if it doesn't shorten code
      by_cases h : ((inr L.to_near_litter, C) ∈ σ.val.range);
      rw [spec.range_sup, spec.range_sup, mem_union, mem_union],
      { left, left, exact h },
      { right,
        refine ⟨_, _, _⟩,
        { exact (inr (precise_litter_inverse_image bij (bij (bij.inv_fun ⟨L, hL, h⟩))
            (abij (bij.inv_fun ⟨L, hL, h⟩)).symm, (bij (bij.inv_fun ⟨L, hL, h⟩)).1.to_near_litter),
              C) },
        { simp only [new_inverse_flexible_litters, subtype.val_eq_coe, mem_set_of_eq,
          equiv.to_fun_as_coe, set_coe.exists, prod.mk.inj_iff, eq_self_iff_true, and_true],
          refine ⟨(bij.inv_fun ⟨L, hL, h⟩), ⟨(bij.inv_fun ⟨L, hL, h⟩).prop, _⟩⟩,
          rw subtype.coe_eta,
          exact ⟨rfl, rfl⟩ },
        { simp only [equiv.inv_fun_as_coe, equiv.apply_symm_apply, binary_condition.range_mk,
            sum.map_inr] } } } },
  { obtain ⟨hdom, hrge⟩ := σ.prop.flexible_cond C,
    { refine spec.flexible_cond.co_large _ _,
      { convert hdom, ext,
        rw and.congr_right_iff,
        intro hx,
        rw not_iff_not,
        rw [spec.domain_sup, spec.domain_sup, mem_union, mem_union],
        split,
        { rintro ((h | ⟨b, hb₁, hb₂⟩) | h),
          { exact h },
          { unfold new_flexible_litters at hb₁,
            rw mem_set_of at hb₁,
            obtain ⟨⟨L, hL₁, hL₂⟩, beq⟩ := hb₁,
            subst beq,
            cases hb₂,
            cases h rfl },
          { sorry } },
        { sorry } },
      { sorry } },
    { sorry } }
end

def abij_inv :
  Π (L : {L : litter | flexible L A ∧ (inr L.to_near_litter, A) ∉ σ⁻¹.val.domain}),
    bij.inv'.precise_atom_bijection L :=
λ L, (abij (bij.inv_fun ⟨L, by simpa only [val_inv, spec.domain_inv] using L.property⟩)).inv

-- There absolutely needs to be a better way to prove this.
lemma new_flexible_litters_inv :
  (bij.new_flexible_litters abij)⁻¹ = bij.inv'.new_inverse_flexible_litters (abij_inv bij abij) :=
begin
  ext ⟨_ | ⟨N₁, N₂⟩, C⟩,
  { simp [binary_condition.inv_mk, new_flexible_litters, new_inverse_flexible_litters,
      mem_set_of_eq, prod.mk.inj_iff, sum.elim_inl, exists_false, false_and] },
  split,
  { rintro ⟨L, ⟨⟩⟩,
    refine ⟨⟨bij L, (bij L).2.1, by simpa only [val_inv, spec.domain_inv] using (bij L).2.2⟩, _⟩,
    congr' 3,
    { unfold precise_litter_inverse_image,
      refine near_litter.val_injective _, dsimp only,
      rw range_eq_iff,
      refine ⟨λ a, ⟨⟨a, _⟩, _⟩, _⟩,
      { simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply,
          subtype.coe_prop] },
      dsimp only, congr' 1,
      { rw [val_inv, spec.range_inv] },
      { rw [val_inv, spec.domain_inv] },
      { exact rough_bijection.inv'_inv },
      { rw subtype.heq_iff_coe_eq,
        { simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe,
            equiv.symm_apply_apply] },
        { intro, rw [val_inv, spec.range_inv], refl } },
      { sorry },
      refine hfunext _ (λ a₁ a₂ h, _),
      { sorry },
      suffices : (a₁.val : atom) = a₂.val,
      { simp_rw [this, inv_inv],
        refl },
      rwa [subtype.heq_iff_coe_heq, subtype.heq_iff_coe_eq] at h,
      { intro,
        simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply] },
      { simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply] },
      refine hfunext _ (λ b₁ b₂ hb, _),
      { simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply] },
      have : b₁.val = b₂.val,
      { rwa subtype.heq_iff_coe_eq at hb,
        intro,
        simp only [inv'_to_fun_mk, subtype.coe_eta, equiv.inv_fun_as_coe, equiv.symm_apply_apply] },
      rw this,
      rw [val_inv, spec.range_inv],
      sorry },
    sorry },
  sorry,
end

lemma new_inverse_flexible_litters_inv :
  (bij.new_inverse_flexible_litters abij)⁻¹ = bij.inv'.new_flexible_litters (abij_inv bij abij) :=
sorry

lemma forward_eq_backward :
  (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij)⁻¹ =
  σ⁻¹.val ∪ bij.inv'.new_flexible_litters (abij_inv bij abij) ∪
    bij.inv'.new_inverse_flexible_litters (abij_inv bij abij) :=
begin
  rw [union_inv, union_inv, val_inv, union_assoc, union_assoc, new_flexible_litters_inv,
    new_inverse_flexible_litters_inv],
  congr' 1,
  rw union_comm,
end

lemma flexible_union_allowable :
  spec.allowable B
    (σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij) :=
{ forward :=
  { one_to_one := flexible_union_one_to_one bij abij,
    atom_cond := flexible_union_atom_cond bij abij,
    near_litter_cond := flexible_union_near_litter_cond bij abij,
    non_flexible_cond := flexible_union_non_flexible_cond bij abij,
    support_closed := flexible_union_support_closed bij abij },
  backward :=
  { one_to_one :=
      by { convert flexible_union_one_to_one bij.inv' (abij_inv bij abij),
        rw forward_eq_backward bij abij },
    atom_cond :=
      by { convert flexible_union_atom_cond bij.inv' (abij_inv bij abij),
        rw forward_eq_backward bij abij },
    near_litter_cond :=
      by { convert flexible_union_near_litter_cond bij.inv' (abij_inv bij abij),
        rw forward_eq_backward bij abij },
    non_flexible_cond :=
      by { convert flexible_union_non_flexible_cond bij.inv' (abij_inv bij abij),
        rw forward_eq_backward bij abij },
    support_closed :=
      by { convert flexible_union_support_closed bij.inv' (abij_inv bij abij),
        rw forward_eq_backward bij abij },
  },
  flexible_cond := flexible_union_flexible_cond bij abij,
}

lemma le_flexible_union :
  σ ≤ ⟨σ.val ∪ bij.new_flexible_litters abij ∪ bij.new_inverse_flexible_litters abij,
    flexible_union_allowable bij abij⟩ :=
{ subset := by { simp_rw union_assoc, exact subset_union_left _ _ },
  all_flex_domain := λ L N' C hN' hσ₁ hσ₂ L' hL', begin
    split,
    { rw [spec.domain_sup, spec.domain_sup],
      by_cases (inr L'.to_near_litter, C) ∈ σ.val.domain,
      { exact or.inl (or.inl h) },
      { have : A = C,
        { obtain ((_ | ⟨L₁, hL₁⟩) | ⟨L₁, hL₁⟩) := hσ₂,
          { cases hσ₁ hσ₂ },
          { exact (congr_arg prod.snd hL₁).symm },
          { exact (congr_arg prod.snd hL₁).symm } },
        subst this,
        exact or.inl (or.inr ⟨_, ⟨⟨L', hL', h⟩, rfl⟩, rfl⟩) } },
    { sorry }
  end,
  all_flex_range := λ L N' C hN' hσ₁ hσ₂ L' hL', begin
    split,
    { rw [spec.domain_sup, spec.domain_sup],
      by_cases (inr L'.to_near_litter, C) ∈ σ.val.domain,
      { exact or.inl (or.inl h) },
      { have : A = C,
        { obtain ((_ | ⟨L₁, hL₁⟩) | ⟨L₁, hL₁⟩) := hσ₂,
          { cases hσ₁ hσ₂ },
          { exact (congr_arg prod.snd hL₁).symm },
          { exact (congr_arg prod.snd hL₁).symm } },
        subst this,
        exact or.inl (or.inr ⟨_, ⟨⟨L', hL', h⟩, rfl⟩, rfl⟩) } },
    { sorry }
  end,
  all_atoms_domain := begin
    rintro a b L ha C hσ₁ ((hσ₂ | hσ₂) | hσ₂),
    { cases hσ₁ hσ₂ },
    { simpa only [new_flexible_litters, mem_set_of_eq, prod.mk.inj_iff,
        false_and, exists_false] using hσ₂ },
    { simpa only [new_inverse_flexible_litters, mem_set_of_eq, prod.mk.inj_iff,
        false_and, exists_false] using hσ₂ }
  end,
  all_atoms_range := begin
    rintro a b L ha C hσ₁ ((hσ₂ | hσ₂) | hσ₂),
    { cases hσ₁ hσ₂ },
    { simpa only [new_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and, exists_false]
        using hσ₂ },
    { simpa only [new_inverse_flexible_litters, mem_set_of_eq, prod.mk.inj_iff, false_and,
      exists_false] using hσ₂ }
  end }

/-- Nothing constrains a flexible litter, so we don't have any hypothesis about the fact that all
things that constrain it lie in `σ` already. -/
lemma exists_ge_flexible (σ : allowable_partial_perm B) {L : litter} (hL : flexible L A) :
  ∃ ρ, σ ≤ ρ ∧ (⟨inr L.to_near_litter, A⟩ : support_condition B) ∈ ρ.val.domain :=
begin
  by_cases (inr L.to_near_litter, A) ∈ σ.val.domain,
  { exact ⟨σ, le_rfl, h⟩ },
  obtain ⟨hdom, hrge⟩ | ⟨hdom, hrge⟩ := σ.property.flexible_cond A,
  swap, { cases h (hdom L hL) },
  have bij : rough_bijection A σ.val.domain σ.val.range :=
    (cardinal.eq.mp $ eq.trans hdom.symm hrge).some,
  have abij : ∀ L, bij.precise_atom_bijection L,
  { refine λ L, (cardinal.eq.mp _).some,
    rw [cardinal.mk_sep, cardinal.mk_sep],
    transitivity #κ,
    { have := cardinal.mk_sum_compl {a : litter_set L | (inl a.val, A) ∈ σ.val.domain},
      rw mk_litter_set at this,
      refine cardinal.eq_of_add_eq_of_aleph_0_le this _ κ_regular.aleph_0_le,
      convert (small_of_not_mem_spec L) using 1, rw cardinal.mk_sep },
    { have := cardinal.mk_sum_compl
        {a : litter_set (bij L) | (inl a.val, A) ∈ σ.val.range},
      rw mk_litter_set at this, symmetry,
      refine cardinal.eq_of_add_eq_of_aleph_0_le this _ κ_regular.aleph_0_le,
      convert (small_of_rough_bijection bij L) using 1, rw cardinal.mk_sep } },
  refine ⟨_, le_flexible_union bij abij, _⟩,
  rw [spec.domain_sup, spec.domain_sup],
  left, right,
  unfold new_flexible_litters,
  refine ⟨_, ⟨⟨L, hL, ‹_›⟩, rfl⟩, rfl⟩,
end

end exists_ge_flexible

section exists_ge_non_flexible

/-!
For a non-flexible litter `L = f_{γδ}^A(t)`, assume the designated support for `t` already lies in
`σ`. Then, look at `σ` restricted to `γ` - this is allowable by the restriction lemma, and by the
inductive freedom of action assumption extends to `π'`, a `γ`-allowable permutation. We can map `t`
using `π'` to find where `L` is supposed to be sent under `π`. We then add this result to `σ`.
-/

variables {B} {σ : allowable_partial_perm B} ⦃β : Λ⦄ ⦃γ : type_index⦄ ⦃δ : Λ⦄

/-- Since the designated support of `t` is included in `σ`, any allowable permutation `π'` that
satisfies `σ` at the lower level gives the same result for the image of `f_map_path hγ hδ t`.
This means that although `π` was chosen arbitrarily, its value is not important, and we could have
chosen any other permutation and arrived at the same value for the image of `f_map_path hγ hδ t`.

Don't prove this unless we need it - it sounds like an important mathematical point but potentially
not for the formalisation itself. -/
lemma non_flexible_union_unique (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ)
  (C : path (B : type_index) β)
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp C)) : le_index α))
  (π : allowable_path (lt_index.mk' (coe_lt_coe.mpr hδ) (B.path.comp C) : le_index α))
  (hπ : π.to_struct_perm.satisfies $ σ.val.lower (C.cons $ coe_lt_coe.mpr hδ)) :
  ∀ (π' : allowable_path (lt_index.mk' (coe_lt_coe.mpr hδ) (B.path.comp C) : le_index α))
    (hπ' : π'.to_struct_perm.satisfies $ σ.val.lower (C.cons $ coe_lt_coe.mpr hδ)),
    struct_perm.derivative (path.nil.cons $ bot_lt_coe _) π.to_struct_perm •
      (f_map_path hγ hδ t).to_near_litter = struct_perm.derivative (path.nil.cons $ bot_lt_coe _)
        π.to_struct_perm • (f_map_path hγ hδ t).to_near_litter :=
sorry

private def new_non_flexible_constraint (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ)
  {C : path (B : type_index) β}
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp C)) : le_index α))
  {π : allowable_path (lt_index.mk' (coe_lt_coe.mpr hδ) (B.path.comp C) : le_index α)}
  (hπ : π.to_struct_perm.satisfies $ σ.val.lower (C.cons $ coe_lt_coe.mpr hδ)) :
    binary_condition B :=
  (inr ((f_map_path hγ hδ t).to_near_litter,
      struct_perm.derivative (path.nil.cons $ bot_lt_coe _)
        π.to_struct_perm • (f_map_path hγ hδ t).to_near_litter),
      (C.cons $ coe_lt_coe.mpr hδ).cons (bot_lt_coe _))

variables (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ) {C : path (B : type_index) β}
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp C)) : le_index α))
  {π : allowable_path (lt_index.mk' (coe_lt_coe.mpr hδ) (B.path.comp C) : le_index α)}
  (hπ : π.to_struct_perm.satisfies $ σ.val.lower (C.cons $ coe_lt_coe.mpr hδ))

lemma non_flexible_union_one_to_one_forward :
  spec.one_to_one_forward (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) :=
sorry

lemma non_flexible_union_one_to_one_backward :
  spec.one_to_one_forward (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ})⁻¹ :=
sorry

lemma non_flexible_union_atom_cond_forward :
  ∀ L C, spec.atom_cond (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) L C :=
sorry

lemma non_flexible_union_atom_cond_backward :
  ∀ L C, spec.atom_cond (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ})⁻¹ L C :=
sorry

lemma non_flexible_union_near_litter_cond_forward :
  ∀ N₁ N₂ C, spec.near_litter_cond (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) N₁ N₂ C :=
sorry

lemma non_flexible_union_near_litter_cond_backward :
  ∀ N₁ N₂ C,
    spec.near_litter_cond (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ})⁻¹ N₁ N₂ C :=
sorry

lemma non_flexible_union_non_flexible_cond_forward :
  spec.non_flexible_cond B (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) :=
begin
  intros hb hg hd hgb hdb hdg hNl hp ht hf π h1,
  unfold struct_perm.satisfies at h1,
  unfold struct_perm.satisfies_cond at h1,
  have h := h1 hf,
  dsimp at h,
  rw ← h,
  sorry
  -- exact unpack_coh_cond hgb hdb hdg hp ht π,
end

lemma non_flexible_union_non_flexible_cond_backward :
  spec.non_flexible_cond B (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ})⁻¹ :=
sorry

lemma non_flexible_union_support_closed_forward :
  (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}).domain.support_closed B :=
sorry

lemma non_flexible_union_support_closed_backward :
  (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}).range.support_closed B :=
sorry

lemma non_flexible_union_flexible_cond :
  ∀ C, spec.flexible_cond B (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) C :=
sorry

lemma non_flexible_union_allowable :
  spec.allowable B (σ.val ∪ {new_non_flexible_constraint hγ hδ hγδ t hπ}) :=
{ forward :=
  { one_to_one := non_flexible_union_one_to_one_forward hγ hδ hγδ t hπ,
    atom_cond := non_flexible_union_atom_cond_forward hγ hδ hγδ t hπ,
    near_litter_cond := non_flexible_union_near_litter_cond_forward hγ hδ hγδ t hπ,
    non_flexible_cond := non_flexible_union_non_flexible_cond_forward hγ hδ hγδ t hπ,
    support_closed := non_flexible_union_support_closed_forward hγ hδ hγδ t hπ },
  backward :=
  { one_to_one := non_flexible_union_one_to_one_backward hγ hδ hγδ t hπ,
    atom_cond := non_flexible_union_atom_cond_backward hγ hδ hγδ t hπ,
    near_litter_cond := non_flexible_union_near_litter_cond_backward hγ hδ hγδ t hπ,
    non_flexible_cond := non_flexible_union_non_flexible_cond_backward hγ hδ hγδ t hπ,
    support_closed := by { rw spec.domain_inv,
      exact non_flexible_union_support_closed_backward hγ hδ hγδ t hπ } },
  flexible_cond := non_flexible_union_flexible_cond hγ hδ hγδ t hπ }

lemma le_non_flexible_union : σ ≤ ⟨_, non_flexible_union_allowable hγ hδ hγδ t hπ⟩ :=
{ subset := subset_union_left _ _,
  all_flex_domain := begin
    rintro L N' C' hN' hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { simp only [new_non_flexible_constraint, mem_singleton_iff, prod.mk.inj_iff] at hσ₂,
      exfalso,
      cases hN' hγ hδ hγδ C t,
      { exact h (litter.to_near_litter_injective hσ₂.left.left) },
      { exact h hσ₂.right } }
  end,
  all_flex_range := begin
    rintro L N' C' hN' hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { simp only [new_non_flexible_constraint, mem_singleton_iff, prod.mk.inj_iff] at hσ₂,
      exfalso,
      cases hN' hγ hδ hγδ C t,
      { -- This is the unpacked coherence condition on L and f.
        -- We need to change C and t to be the correct parameters here.
        sorry },
      { exact h hσ₂.right } }
  end,
  all_atoms_domain := begin
    rintro a b L ha C hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { simpa only [new_non_flexible_constraint, mem_singleton_iff, prod.mk.inj_iff,
        false_and] using hσ₂ }
  end,
  all_atoms_range := begin
    rintro a b L ha C hσ₁ (hσ₂ | hσ₂),
    { cases hσ₁ hσ₂ },
    { simpa only [new_non_flexible_constraint, mem_singleton_iff, prod.mk.inj_iff,
        false_and] using hσ₂ }
  end }

lemma exists_ge_non_flexible (hγ : γ < β) (hδ : δ < β) (hγδ : γ ≠ δ) {C : path (B : type_index) β}
  (t : tangle_path ((lt_index.mk' hγ (B.path.comp C)) : le_index α))
  (hσ : ∀ c, c ≺ (inr (f_map_path hγ hδ t).to_near_litter,
    (C.cons $ coe_lt_coe.mpr hδ).cons (bot_lt_coe _)) →
    c ∈ σ.val.domain)
  (foa : ∀ (B : lt_index α), freedom_of_action (B : le_index α)) :
  ∃ ρ ≥ σ, (inr (f_map_path hγ hδ t).to_near_litter,
    (C.cons $ coe_lt_coe.mpr hδ).cons (bot_lt_coe _)) ∈
    ρ.val.domain :=
begin
  have hS : ∀ (c : support_condition γ), c ∈ (designated_support_path t).carrier →
    (c.fst, (C.cons hγ).comp c.snd) ∈ σ.val.domain :=
  λ (c : support_condition γ) (hc : c ∈ (designated_support_path t).carrier),
    hσ ⟨c.fst, path.comp (path.cons C hγ) c.snd⟩ (constrains.f_map hγ hδ hγδ C t c hc),
  have := σ.2.lower (C.cons $ coe_lt_coe.2 hδ) ((coe_lt_coe.2 hδ).trans_le (le_of_path C)),
  obtain ⟨π, hπ⟩ := foa (lt_index.mk' (coe_lt_coe.mpr hδ) (B.path.comp C))
    ⟨σ.val.lower (C.cons $ coe_lt_coe.mpr hδ), this⟩,
  have := struct_perm.derivative (path.nil.cons $ bot_lt_coe _) π.to_struct_perm
     • (f_map_path hγ hδ t).to_near_litter,
  refine ⟨_, le_non_flexible_union hγ hδ hγδ t hπ, _⟩,
  rw spec.domain_sup,
  right, simpa only [spec.domain, image_singleton, mem_singleton_iff],
end

end exists_ge_non_flexible

lemma total_of_is_max_aux (σ : allowable_partial_perm B) (hσ : is_max σ)
  (foa : ∀ (B : lt_index α), freedom_of_action (B : le_index α)) :
  Π (c : support_condition B), c ∈ σ.val.domain
| ⟨inl a, A⟩ := begin
    obtain ⟨ρ, hρ, b, hb, hdom⟩ := exists_ge_atom σ a A (λ c hc, total_of_is_max_aux c),
    exact ⟨b, (hσ hρ).subset hb, hdom⟩
  end
| ⟨inr N, A⟩ := begin
    by_cases hnl : litter_set N.fst = N.snd,
    { -- This is a litter.
      have hind : ∀ c (hc : c ≺ ⟨inr N, A⟩), c ∈ σ.val.domain := λ c hc, total_of_is_max_aux c,
      obtain ⟨L, N, hN⟩ := N,
      dsimp only at hnl, rw subtype.coe_mk at hnl, subst hnl,
      by_cases flexible L A,
      { -- This litter is flexible.
        obtain ⟨ρ, hρ₁, hρ₂⟩ := exists_ge_flexible σ h,
        sorry
        -- rw hσ ρ hρ₁ at hρ₂,
        -- exact hρ₂
        },
      { -- This litter is non-flexible.
        unfold flexible at h,
        push_neg at h,
        obtain ⟨β, δ, γ, hγ, hδ, hγδ, C, t, hL, hA⟩ := h,
        cases hA,
        cases hL,
        obtain ⟨ρ, hρ₁, hρ₂⟩ := exists_ge_non_flexible hγ hδ hγδ t hind foa,
        sorry
        -- rw hσ ρ hρ₁ at hρ₂,
        -- exact hρ₂
        } },
    { -- This is a near-litter.
      obtain ⟨ρ, hρ₁, hρ₂⟩ := exists_ge_near_litter σ N A hnl (λ c hc, total_of_is_max_aux c),
      sorry
      -- rw hσ ρ hρ₁ at hρ₂,
      -- exact hρ₂
    }
  end
using_well_founded { dec_tac := `[assumption] }

/-- Any maximal allowable partial permutation under `≤` is total. -/
lemma total_of_is_max (σ : allowable_partial_perm B) (hσ : is_max σ)
  (foa : ∀ (B : lt_index α), freedom_of_action (B : le_index α)) : σ.val.total :=
eq_univ_of_forall (total_of_is_max_aux σ hσ foa)

/-- Any maximal allowable partial permutation under `≤` is co-total. -/
lemma co_total_of_is_max (σ : allowable_partial_perm B) (hσ : is_max σ)
  (foa : ∀ B : lt_index α, freedom_of_action (B : le_index α)) : σ.val.co_total :=
(total_of_is_max σ⁻¹ (λ ρ hρ, by { rw [←inv_le_inv, inv_inv] at ⊢ hρ, exact hσ hρ }) foa).of_inv

variables (α)

/-- The hypothesis that we are in the synthesised context at `α`.
This allows us to combine a set of allowable permutations at all lower paths into an allowable
permutation at level `α`
This may not be the best way to phrase the assumption - the definition is subject to change when
we actually create a proof of the proposition. -/
def synthesised_context : Prop := Π (σ : allowable_partial_perm ⟨α, path.nil⟩)
  (hσ₁ : σ.val.total)
  (hσ₂ : σ.val.co_total)
  (foa : ∀ (B : lt_index α), freedom_of_action (B : le_index α))
  (lower_allowable : ∀ B : proper_lt_index α, (σ.val.lower B.path).allowable (B : le_index α))
  (exists_lower_allowable :
    ∀ (B : proper_lt_index α), ∃ (π : allowable_path (B : le_index α)),
      π.to_struct_perm.satisfies (σ.val.lower B.path)),
  ∃ π : allowable_path ⟨α, path.nil⟩, π.to_struct_perm.satisfies σ.val

variables {α}

/-- Any allowable partial permutation extends to an allowable permutation at level `α`, given that
it is total and co-total. This is `total-allowable-partial-perm-actual` in the blueprint. -/
lemma extends_to_allowable_of_total (σ : allowable_partial_perm ⟨α, path.nil⟩)
  (hσ₁ : σ.val.total) (hσ₂ : σ.val.co_total)
  (foa : ∀ (B : lt_index α), freedom_of_action (B : le_index α)) (syn : synthesised_context α) :
  ∃ π : allowable_path ⟨α, path.nil⟩, π.to_struct_perm.satisfies σ.val :=
begin
  have lower_allowable : ∀ B : proper_lt_index α, (σ.val.lower B.path).allowable (B : le_index α),
  { intro B,
    have := σ.2.lower B.path (coe_lt_coe.2 $ B.index_lt.trans_le $ le_rfl),
    rw path.nil_comp at this,
    exact this },
  have exists_lower_allowable : ∀ (B : proper_lt_index α), ∃ (π : allowable_path (B : le_index α)),
    π.to_struct_perm.satisfies (σ.val.lower B.path) :=
    λ B, foa B ⟨σ.val.lower B.path, lower_allowable _⟩,
  exact syn σ hσ₁ hσ₂ foa lower_allowable exists_lower_allowable,
end

end allowable_partial_perm

/-- The *freedom of action theorem*. If freedom of action holds at all lower levels and paths (all
`B : lt_index` in our formulation), it holds at level `α`. -/
theorem freedom_of_action_propagates (foa : ∀ B : lt_index α, freedom_of_action (B : le_index α))
  (syn : allowable_partial_perm.synthesised_context α) :
  freedom_of_action ⟨α, path.nil⟩ :=
begin
  intro σ,
  obtain ⟨ρ, -, hσρ, hρ⟩ := σ.maximal_perm,
  have : is_max ρ := λ τ hτ, hρ τ (hσρ.trans hτ) hτ,
  have ρ_total := allowable_partial_perm.total_of_is_max ρ this foa,
  have ρ_co_total := allowable_partial_perm.co_total_of_is_max ρ this foa,
  obtain ⟨π, hπ⟩ := ρ.extends_to_allowable_of_total ρ_total ρ_co_total foa syn,
  exact ⟨π, hπ.mono hσρ.subset⟩,
end

end con_nf
