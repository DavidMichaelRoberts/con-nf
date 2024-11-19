import Mathlib.Logic.Equiv.TransferInstance
import ConNF.Basic.Ordinal

universe u v

namespace Equiv

variable {α : Type u} {β : Type v} (e : α ≃ β)

protected def le [LE β] : LE α where
  le := InvImage (· ≤ ·) e

theorem le_def [LE β] (x y : α) :
    letI := e.le
    x ≤ y ↔ e x ≤ e y :=
  Iff.rfl

protected def lt [LT β] : LT α where
  lt := InvImage (· < ·) e

theorem lt_def [LT β] (x y : α) :
    letI := e.lt
    x < y ↔ e x < e y :=
  Iff.rfl

protected def min [Min β] : Min α where
  min x y := e.symm (e x ⊓ e y)

theorem min_def [Min β] (x y : α) :
    letI := e.min
    x ⊓ y = e.symm (e x ⊓ e y) :=
  rfl

theorem apply_min [Min β] (x y : α) :
    letI := e.min
    e (x ⊓ y) = e x ⊓ e y := by
  rw [min_def, apply_symm_apply]

protected def max [Max β] : Max α where
  max x y := e.symm (e x ⊔ e y)

theorem max_def [Max β] (x y : α) :
    letI := e.max
    x ⊔ y = e.symm (e x ⊔ e y) :=
  rfl

theorem apply_max [Max β] (x y : α) :
    letI := e.max
    e (x ⊔ y) = e x ⊔ e y := by
  rw [max_def, apply_symm_apply]

protected def compare [Ord β] : Ord α where
  compare x y := compare (e x) (e y)

theorem compare_def [Ord β] (x y : α) :
    letI := e.compare
    compare x y = compare (e x) (e y) :=
  rfl

protected def decidableLE [LE β] [DecidableRel ((· ≤ ·) : β → β → Prop)] :
    letI := e.le
    DecidableRel ((· ≤ ·) : α → α → Prop) :=
  λ x y ↦ inferInstanceAs (Decidable (e x ≤ e y))

protected def decidableLT [LT β] [DecidableRel ((· < ·) : β → β → Prop)] :
    letI := e.lt
    DecidableRel ((· < ·) : α → α → Prop) :=
  λ x y ↦ inferInstanceAs (Decidable (e x < e y))

protected def leIso [LE β] :
    letI := e.le
    ((· ≤ ·) : α → α → Prop) ≃r ((· ≤ ·) : β → β → Prop) where
  map_rel_iff' := Iff.rfl
  __ := e

protected def orderIso [LE β] :
    letI := e.le
    α ≃o β :=
  e.leIso

protected def ltIso [LT β] :
    letI := e.lt
    ((· < ·) : α → α → Prop) ≃r ((· < ·) : β → β → Prop) where
  map_rel_iff' := Iff.rfl
  __ := e

protected def preorder [Preorder β] : Preorder α :=
  Preorder.lift e

protected def partialOrder [PartialOrder β] : PartialOrder α :=
  PartialOrder.lift e e.injective

protected def linearOrder [LinearOrder β] : LinearOrder α :=
  letI := e.max
  letI := e.min
  letI := e.compare
  LinearOrder.liftWithOrd e e.injective e.apply_max e.apply_min e.compare_def

protected def ltWellOrder [LtWellOrder β] : LtWellOrder α where
  wf := InvImage.wf e (inferInstanceAs <| IsWellFounded β (· < ·)).wf
  __ := e.linearOrder

theorem ltWellOrder_type [LtWellOrder β] :
    letI := e.ltWellOrder
    Ordinal.lift.{max u v, u} (Ordinal.type ((· < ·) : α → α → Prop)) =
    Ordinal.lift.{max u v, v} (Ordinal.type ((· < ·) : β → β → Prop)) := by
  rw [Ordinal.lift_type_eq.{u, v, max u v}]
  exact ⟨e.ltIso⟩

theorem ltWellOrder_typein [i : LtWellOrder β] (x : α) :
    letI := e.ltWellOrder.toLT
    Ordinal.lift.{max u v, v} (Ordinal.typein ((· < ·) : β → β → Prop) (e x)) =
    Ordinal.lift.{max u v, u} (Ordinal.typein ((· < ·) : α → α → Prop) x) := by
  letI := e.ltWellOrder
  refine Ordinal.lift_typein_apply (r := (· < ·)) (s := (· < ·)) (f := ⟨⟨e.toEmbedding, ?_⟩, ?_⟩) x
  · rfl
  · simp only [RelEmbedding.coe_mk, coe_toEmbedding]
    intro a b _
    use e.symm b
    exact apply_symm_apply e b

protected theorem noMaxOrder [LT β] [NoMaxOrder β] :
    letI := e.lt
    NoMaxOrder α := by
  letI := e.lt
  constructor
  intro x
  obtain ⟨y, hy⟩ := exists_gt (e x)
  use e.symm y
  rw [lt_def, apply_symm_apply]
  exact hy

protected def ofNat (n : ℕ) [OfNat β n] : OfNat α n where
  ofNat := e.symm (OfNat.ofNat n)

theorem apply_add [Add β] (x y : α) :
    letI := e.add
    e (x + y) = e x + e y := by
  rw [add_def, apply_symm_apply]

theorem apply_sub [Sub β] (x y : α) :
    letI := e.sub
    e (x - y) = e x - e y := by
  rw [sub_def, apply_symm_apply]

theorem apply_zero [Zero β] :
    letI := e.zero
    e 0 = 0 := by
  rw [zero_def, apply_symm_apply]

end Equiv
