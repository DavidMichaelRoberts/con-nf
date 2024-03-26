import ConNF.Structural.Support
import ConNF.Fuzz.Position

/-!
# Hypotheses for constructing the `fuzz` map

This file contains the inductive hypotheses required for constructing the `fuzz` map.
Even though not everything defined here is strictly necessary for this construction, we bundle
it here for more convenient use later.

## Main declarations

* `ConNF.TangleData`: Data about the model elements at level `α`.
* `ConNF.PositionedTangles`: A function that gives each `α`-tangle a unique position `ν : μ`.
* `ConNF.TypedObjects`: Allows us to encode atoms and near-litters as `α`-tangles.
* `ConNF.BasePositions`: The position of typed atoms and typed near-litters in the position function
    at any level.
-/

open Function Set WithBot

open scoped Pointwise symmDiff

universe u

namespace ConNF

variable [Params.{u}]

/-- Data about the model elements at level `α`. This class asserts the existence of a type of
tangles at level `α`, and a group of allowable permutations at level `α` that act on the
`α`-tangles. We also stipulate that each tangle has a prescribed small support, called its
designated support. -/
class TangleData (α : TypeIndex) where
  /-- The type of tangles that we assume were constructed at stage `α`.
  Later in the recursion, we will construct this type explicitly, but for now, we will just assume
  that it exists. -/
  (Tangle : Type u)
  /-- The type of allowable permutations that we assume exists on `α`-tangles. -/
  (Allowable : Type u)
  [allowableGroup : Group Allowable]
  allowableToStructPerm : Allowable →* StructPerm α
  [allowableAction : MulAction Allowable Tangle]
  support : Tangle → Support α
  support_supports (t : Tangle) :
    haveI : MulAction Allowable (Address α) :=
      MulAction.compHom _ allowableToStructPerm
    MulAction.Supports Allowable (support t : Set (Address α)) t
  toPretangle : Tangle → Pretangle α
  toPretangle_smul (ρ : Allowable) (t : Tangle) :
    haveI : MulAction Allowable (Pretangle α) :=
      MulAction.compHom _ allowableToStructPerm
    toPretangle (ρ • t) = ρ • toPretangle t

export TangleData (Tangle Allowable toPretangle toPretangle_smul)

attribute [instance] TangleData.allowableGroup TangleData.allowableAction

namespace Allowable

variable {α : TypeIndex} [TangleData α] {X : Type _} [MulAction (StructPerm α) X]

/-- Allowable permutations can be considered a subtype of structural permutations.
This map can be thought of as an inclusion that preserves the group structure. -/
def toStructPerm : Allowable α →* StructPerm α :=
  TangleData.allowableToStructPerm

/-- Allowable permutations act on anything that structural permutations do. -/
instance : MulAction (Allowable α) X :=
  MulAction.compHom _ toStructPerm

theorem toStructPerm_smul (ρ : Allowable α) (x : X) : ρ • x = Allowable.toStructPerm ρ • x :=
  rfl

@[simp]
theorem smul_support_max (ρ : Allowable α) (S : Support α) :
    (ρ • S).max = S.max :=
  rfl

@[simp]
theorem smul_support_f (ρ : Allowable α) (S : Support α) (i : κ) (hi : i < S.max) :
    (ρ • S).f i hi = ρ • S.f i hi :=
  rfl

@[simp]
theorem smul_support_coe (ρ : Allowable α) (S : Support α) :
    (ρ • S : Support α) = ρ • (S : Set (Address α)) :=
  Enumeration.smul_coe _ _

theorem smul_mem_smul_support {S : Support α} {c : Address α}
    (h : c ∈ S) (ρ : Allowable α) : ρ • c ∈ ρ • S :=
  Enumeration.smul_mem_smul h _

theorem smul_eq_of_smul_support_eq {S : Support α} {ρ : Allowable α}
    (hS : ρ • S = S) {c : Address α} (hc : c ∈ S) : ρ • c = c :=
  Enumeration.smul_eq_of_smul_eq hS hc

variable {ρ ρ' : Allowable α} {c : Address α}

theorem smul_address :
    ρ • c = ⟨c.path, Allowable.toStructPerm ρ c.path • c.value⟩ :=
  rfl

@[simp]
theorem smul_address_eq_iff :
    ρ • c = c ↔ Allowable.toStructPerm ρ c.path • c.value = c.value :=
  StructPerm.smul_address_eq_iff

@[simp]
theorem smul_address_eq_smul_iff :
    ρ • c = ρ' • c ↔
    Allowable.toStructPerm ρ c.path • c.value = Allowable.toStructPerm ρ' c.path • c.value :=
  StructPerm.smul_address_eq_smul_iff

end Allowable

/-- For each tangle, we provide a small support for it. This is known as the designated support of
the tangle. -/
def TangleData.Tangle.support {α : TypeIndex} [TangleData α] (t : Tangle α) : Support α :=
  TangleData.support t

theorem support_supports {α : TypeIndex} [TangleData α] (t : Tangle α) :
    MulAction.Supports (Allowable α) (t.support : Set (Address α)) t :=
  TangleData.support_supports t

class PositionedTangles (α : TypeIndex) [TangleData α] where
  /-- A position function, giving each tangle a unique position `ν : μ`.
  The existence of this injection proves that there are at most `μ` tangles at level `α`.
  Since `μ` has a well-ordering, this induces a well-ordering on `α`-tangles: to compare two
  tangles, simply compare their images under this map. -/
  pos : Tangle α ↪ μ

instance {α : TypeIndex} [TangleData α] [PositionedTangles α] : Position (Tangle α) μ where
  pos := PositionedTangles.pos

variable (α : Λ) [TangleData α]

/-- Allows us to encode atoms and near-litters as `α`-tangles. These maps are expected to cohere
with the conditions given in `BasePositions`, but this requirement is expressed later. -/
class TypedObjects where
  /-- Encode an atom as an `α`-tangle. The resulting model element has a `⊥`-extension which
  contains only this atom. -/
  typedAtom : Atom ↪ Tangle α
  /-- Encode a near-litter as an `α`-tangle. The resulting model element has a `⊥`-extension which
  contains only this near-litter. -/
  typedNearLitter : NearLitter ↪ Tangle α
  smul_typedNearLitter :
    ∀ (ρ : Allowable α) (N : NearLitter),
    ρ • typedNearLitter N =
    typedNearLitter ((Allowable.toStructPerm ρ) (Quiver.Hom.toPath <| bot_lt_coe α) • N)

export TypedObjects (typedAtom typedNearLitter)

class BasePositions where
  posAtom : Atom ↪ μ
  posNearLitter : NearLitter ↪ μ
  lt_pos_atom (a : Atom) :
    posNearLitter a.1.toNearLitter < posAtom a
  lt_pos_litter (N : NearLitter) (hN : ¬N.IsLitter) :
    posNearLitter N.1.toNearLitter < posNearLitter N
  lt_pos_symmDiff (a : Atom) (N : NearLitter) (h : a ∈ litterSet N.1 ∆ N) :
    posAtom a < posNearLitter N

/-- A position function for atoms. -/
instance [BasePositions] : Position Atom μ :=
  ⟨BasePositions.posAtom⟩

/-- A position function for near-litters. -/
instance [BasePositions] : Position NearLitter μ :=
  ⟨BasePositions.posNearLitter⟩

theorem lt_pos_atom [BasePositions] (a : Atom) : pos a.1.toNearLitter < pos a :=
  BasePositions.lt_pos_atom a

theorem lt_pos_litter [BasePositions] (N : NearLitter) (hN : ¬N.IsLitter) :
    pos N.1.toNearLitter < pos N :=
  BasePositions.lt_pos_litter N hN

theorem lt_pos_symmDiff [BasePositions] (a : Atom) (N : NearLitter) (h : a ∈ litterSet N.1 ∆ N) :
    pos a < pos N :=
  BasePositions.lt_pos_symmDiff a N h

class PositionedObjects [BasePositions] [PositionedTangles α] [TypedObjects α] where
  pos_typedAtom (a : Atom) : pos (typedAtom a : Tangle α) = pos a
  pos_typedNearLitter (N : NearLitter) : pos (typedNearLitter N : Tangle α) = pos N

export PositionedObjects (pos_typedAtom pos_typedNearLitter)

attribute [simp] pos_typedAtom pos_typedNearLitter

namespace Allowable

variable {α}
variable [TypedObjects α]

/-- The action of allowable permutations on tangles commutes with the `typedNearLitter` function
mapping near-litters to typed near-litters. This can be seen by representing tangles as codes. -/
theorem smul_typedNearLitter (ρ : Allowable α) (N : NearLitter) :
    (ρ • typedNearLitter N : Tangle α) =
    typedNearLitter ((Allowable.toStructPerm ρ) (Quiver.Hom.toPath <| bot_lt_coe α) • N) :=
  TypedObjects.smul_typedNearLitter _ _

end Allowable

/-- The tangle data at level `⊥` is constructed by taking the tangles to be the atoms, the allowable
permutations to be near-litter permutations, and the designated supports to be singletons. -/
instance Bot.tangleData : TangleData ⊥
    where
  Tangle := Atom
  Allowable := NearLitterPerm
  allowableToStructPerm := Tree.toBotIso.toMonoidHom
  allowableAction := inferInstance
  support a := ⟨1, fun _ _ => ⟨Quiver.Path.nil, Sum.inl a⟩⟩
  support_supports a π h := by
    simp only [Enumeration.mem_carrier_iff, κ_lt_one_iff, exists_prop, exists_eq_left,
      NearLitterPerm.smul_address_eq_iff, forall_eq, Sum.smul_inl, Sum.inl.injEq] at h
    exact h
  toPretangle := Pretangle.ofBot
  toPretangle_smul _ _ := rfl

/-- The position function at level `⊥`, taken from the `BasePositions`. -/
instance Bot.positionedTangles [BasePositions] : PositionedTangles ⊥ :=
  ⟨BasePositions.posAtom⟩

/-- The identity equivalence between `⊥`-allowable permutations and near-litter permutations.
This equivalence is a group isomorphism. -/
def _root_.NearLitterPerm.ofBot : Allowable ⊥ ≃ NearLitterPerm :=
  Equiv.refl _

@[simp]
theorem _root_.NearLitterPerm.ofBot_smul {X : Type _} [MulAction NearLitterPerm X]
    (π : Allowable ⊥) (x : X) :
    NearLitterPerm.ofBot π • x = π • x :=
  rfl

end ConNF
