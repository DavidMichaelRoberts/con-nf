import ConNF.FOA.Complete

open Equiv Function Quiver Set Sum WithBot

open scoped Classical Pointwise

universe u

namespace ConNF

namespace StructApprox

variable [Params.{u}] [BasePositions] [Level] [FOAAssumptions] {β : Λ} [LeLevel β]
  [FreedomOfActionHypothesis β]

def transConstrained (c d : SupportCondition β) : Set (SupportCondition β) :=
  {e | e < c} ∪ {e | e < d}

def reflTransConstrained (c d : SupportCondition β) : Set (SupportCondition β) :=
  {e | e ≤ c} ∪ {e | e ≤ d}

theorem transConstrained_symm (c d : SupportCondition β) :
    transConstrained c d = transConstrained d c :=
  union_comm _ _

theorem reflTransConstrained_symm (c d : SupportCondition β) :
    reflTransConstrained c d = reflTransConstrained d c :=
  union_comm _ _

@[simp]
theorem transConstrained_self (c : SupportCondition β) : transConstrained c c = {e | e < c} :=
  union_self _

@[simp]
theorem reflTransConstrained_self (c : SupportCondition β) :
    reflTransConstrained c c = {e | e ≤ c} :=
  union_self _

theorem mem_reflTransConstrained_of_mem_transConstrained {c d e : SupportCondition β}
    (he : e ∈ transConstrained c d) : e ∈ reflTransConstrained c d := by
  obtain he | he := he
  exact Or.inl he.to_reflTransGen
  exact Or.inr he.to_reflTransGen

theorem transConstrained_trans {c d e f : SupportCondition β} (he : e ∈ transConstrained c d)
    (hf : f ≤ e) : f ∈ transConstrained c d := by
  obtain he | he := he
  exact Or.inl (Relation.TransGen.trans_right hf he)
  exact Or.inr (Relation.TransGen.trans_right hf he)

theorem reflTransConstrained_trans {c d e f : SupportCondition β}
    (he : e ∈ reflTransConstrained c d) (hf : f ≤ e) : f ∈ reflTransConstrained c d := by
  obtain he | he := he
  exact Or.inl (hf.trans he)
  exact Or.inr (hf.trans he)

theorem transConstrained_of_reflTransConstrained_of_trans_constrains {c d e f : SupportCondition β}
    (he : e ∈ reflTransConstrained c d) (hf : f < e) : f ∈ transConstrained c d := by
  obtain he | he := he
  exact Or.inl (hf.trans_left he)
  exact Or.inr (hf.trans_left he)

theorem transConstrained_of_constrains {c d e f : SupportCondition β}
    (he : e ∈ transConstrained c d) (hf : f ≺ e) : f ∈ transConstrained c d :=
  transConstrained_trans he (Relation.ReflTransGen.single hf)

theorem reflTransConstrained_of_constrains {c d e f : SupportCondition β}
    (he : e ∈ reflTransConstrained c d) (hf : f ≺ e) : f ∈ reflTransConstrained c d :=
  reflTransConstrained_trans he (Relation.ReflTransGen.single hf)

theorem transConstrained_of_reflTransConstrained_of_constrains {c d e f : SupportCondition β}
    (he : e ∈ reflTransConstrained c d) (hf : f ≺ e) : f ∈ transConstrained c d :=
  transConstrained_of_reflTransConstrained_of_trans_constrains he (Relation.TransGen.single hf)

theorem fst_transConstrained {c d : SupportCondition β} {A : ExtendedIndex β} {a : Atom}
    (hac : ⟨A, inl a⟩ ∈ reflTransConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ transConstrained c d :=
  transConstrained_of_reflTransConstrained_of_constrains hac (Constrains.atom A a)

theorem fst_mem_trans_constrained' {c d : SupportCondition β} {A : ExtendedIndex β} {a : Atom}
    (h : ⟨A, inl a⟩ ∈ transConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ transConstrained c d :=
  transConstrained_of_constrains h (Constrains.atom A a)

theorem fst_mem_transConstrained {c d : SupportCondition β} {A : ExtendedIndex β} {N : NearLitter}
    (hN : ⟨A, inr N⟩ ∈ transConstrained c d) :
    ⟨A, inr N.fst.toNearLitter⟩ ∈ transConstrained c d := by
  obtain hN | hN := hN
  exact Or.inl (lt_nearLitter' hN)
  exact Or.inr (lt_nearLitter' hN)

theorem fst_mem_refl_trans_constrained' {c d : SupportCondition β} {A : ExtendedIndex β} {a : Atom}
    (h : ⟨A, inl a⟩ ∈ reflTransConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ reflTransConstrained c d :=
  reflTransConstrained_of_constrains h (Constrains.atom A a)

theorem fst_mem_reflTransConstrained {c d : SupportCondition β} {A : ExtendedIndex β}
    {N : NearLitter} (hN : ⟨A, inr N⟩ ∈ reflTransConstrained c d) :
    ⟨A, inr N.fst.toNearLitter⟩ ∈ reflTransConstrained c d := by
  obtain hN | hN := hN
  exact Or.inl (le_nearLitter hN)
  exact Or.inr (le_nearLitter hN)

theorem fst_mem_transConstrained_of_mem_symmDiff {c d : SupportCondition β} {A : ExtendedIndex β}
    {N : NearLitter} {a : Atom} (h : a ∈ litterSet N.1 ∆ N)
    (hN : ⟨A, inr N⟩ ∈ transConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ transConstrained c d := by
  obtain ⟨h₁, h₂⟩ | ⟨h₁, h₂⟩ := h
  · rw [mem_litterSet] at h₁
    rw [h₁]
    exact fst_mem_transConstrained hN
  · obtain hN | hN := hN
    · refine' fst_mem_trans_constrained' (Or.inl _)
      exact Relation.TransGen.head (Constrains.symmDiff A N a (Or.inr ⟨h₁, h₂⟩)) hN
    · refine' fst_mem_trans_constrained' (Or.inr _)
      exact Relation.TransGen.head (Constrains.symmDiff A N a (Or.inr ⟨h₁, h₂⟩)) hN

theorem fst_mem_reflTransConstrained_of_mem_symmDiff {c d : SupportCondition β}
    {A : ExtendedIndex β} {N : NearLitter} {a : Atom} (h : a ∈ litterSet N.1 ∆ N)
    (hN : ⟨A, inr N⟩ ∈ reflTransConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ reflTransConstrained c d := by
  obtain ⟨h₁, h₂⟩ | ⟨h₁, h₂⟩ := h
  · rw [mem_litterSet] at h₁
    rw [h₁]
    exact fst_mem_reflTransConstrained hN
  · obtain hN | hN := hN
    · refine' fst_mem_refl_trans_constrained' (Or.inl _)
      exact Relation.ReflTransGen.head (Constrains.symmDiff A N a (Or.inr ⟨h₁, h₂⟩)) hN
    · refine' fst_mem_refl_trans_constrained' (Or.inr _)
      exact Relation.ReflTransGen.head (Constrains.symmDiff A N a (Or.inr ⟨h₁, h₂⟩)) hN

theorem fst_mem_transConstrained_of_mem {c d : SupportCondition β} {A : ExtendedIndex β}
    {N : NearLitter} {a : Atom} (h : a ∈ N) (hN : ⟨A, inr N⟩ ∈ transConstrained c d) :
    ⟨A, inr a.fst.toNearLitter⟩ ∈ transConstrained c d := by
  by_cases ha : a.1 = N.1
  · rw [ha]
    exact fst_mem_transConstrained hN
  · exact fst_mem_transConstrained_of_mem_symmDiff (Or.inr ⟨h, ha⟩) hN

theorem eq_of_sublitter_bijection_apply_eq {π : NearLitterApprox} {L₁ L₂ L₃ L₄ : Litter} {a b} :
    ((π.largestSublitter L₁).equiv (π.largestSublitter L₂) a : Atom) =
        (π.largestSublitter L₃).equiv (π.largestSublitter L₄) b →
      L₁ = L₃ → L₂ = L₄ → (a : Atom) = b := by
  rintro h₁ rfl rfl
  simp only [NearLitterApprox.coe_largestSublitter, SetLike.coe_eq_coe,
    EmbeddingLike.apply_eq_iff_eq] at h₁
  rw [h₁]

noncomputable def constrainedAction (π : StructApprox β) (s : Set (SupportCondition β))
    (hs : Small s) : StructAction β := fun B =>
  { atomMap := fun a =>
      ⟨∃ c : SupportCondition β, c ∈ s ∧ ⟨B, inl a⟩ ≤ c,
        fun _ => π.completeAtomMap B a⟩
    litterMap := fun L =>
      ⟨∃ c : SupportCondition β, c ∈ s ∧ ⟨B, inr L.toNearLitter⟩ ≤ c,
        fun _ => π.completeNearLitterMap B L.toNearLitter⟩
    atomMap_dom_small := by
      change Small ((fun a : Atom => ⟨B, inl a⟩) ⁻¹'
        {c : SupportCondition β | ∃ d : SupportCondition β, d ∈ s ∧ c ≤ d})
      refine' Small.preimage _ (reflTransClosure_small hs)
      intro a b h
      cases h
      rfl
    litterMap_dom_small := by
      change Small ((fun L : Litter => ⟨B, inr L.toNearLitter⟩) ⁻¹'
        {c : SupportCondition β | ∃ d : SupportCondition β, d ∈ s ∧ c ≤ d})
      refine' Small.preimage _ (reflTransClosure_small hs)
      intro a b h
      cases h
      rfl }

-- TODO: Why is `by exact` needed?
/-- An object like `ih_action` that can take two support conditions. -/
noncomputable def ihsAction (π : StructApprox β) (c d : SupportCondition β) : StructAction β :=
  fun B =>
  { atomMap := fun a => ⟨⟨B, inl a⟩ ∈ transConstrained c d,
      fun _ => π.completeAtomMap B a⟩
    litterMap := fun L => ⟨⟨B, inr L.toNearLitter⟩ ∈ transConstrained c d,
      fun _ => π.completeNearLitterMap B L.toNearLitter⟩
    atomMap_dom_small := by
      exact Small.union (ihAction π.foaHypothesis B).atomMap_dom_small
        (ihAction π.foaHypothesis B).atomMap_dom_small
    litterMap_dom_small := by
      exact Small.union (ihAction π.foaHypothesis B).litterMap_dom_small
        (ihAction π.foaHypothesis B).litterMap_dom_small }

@[simp]
theorem constrainedAction_atomMap {π : StructApprox β} {s : Set (SupportCondition β)} {hs : Small s}
    {B : ExtendedIndex β} {a : Atom} :
    (constrainedAction π s hs B).atomMap a =
      ⟨∃ c : SupportCondition β, c ∈ s ∧ ⟨B, inl a⟩ ≤ c,
        fun _ => completeAtomMap π B a⟩ :=
  rfl

@[simp]
theorem constrainedAction_litterMap {π : StructApprox β} {s : Set (SupportCondition β)}
    {hs : Small s} {B : ExtendedIndex β} {L : Litter} :
    (constrainedAction π s hs B).litterMap L =
      ⟨∃ c : SupportCondition β, c ∈ s ∧ ⟨B, inr L.toNearLitter⟩ ≤ c,
        fun _ => π.completeNearLitterMap B L.toNearLitter⟩ :=
  rfl

@[simp]
theorem ihsAction_atomMap {π : StructApprox β} {c d : SupportCondition β} {B : ExtendedIndex β}
    {a : Atom} :
    (ihsAction π c d B).atomMap a =
      ⟨⟨B, inl a⟩ ∈ transConstrained c d,
        fun _ => completeAtomMap π B a⟩ :=
  rfl

@[simp]
theorem ihsAction_litterMap {π : StructApprox β} {c d : SupportCondition β} {B : ExtendedIndex β}
    {L : Litter} :
    (ihsAction π c d B).litterMap L =
      ⟨⟨B, inr L.toNearLitter⟩ ∈ transConstrained c d,
        fun _ => π.completeNearLitterMap B L.toNearLitter⟩ :=
  rfl

theorem ihsAction_symm (π : StructApprox β) (c d : SupportCondition β) :
    ihsAction π c d = ihsAction π d c := by
  funext
  ext
  · funext
    rw [ihsAction_atomMap, ihsAction_atomMap, transConstrained_symm]
  · funext
    rw [ihsAction_litterMap, ihsAction_litterMap, transConstrained_symm]

@[simp]
theorem ihsAction_self (π : StructApprox β) (c : SupportCondition β) :
    ihsAction π c c = ihAction (π.foaHypothesis : HypAction c) := by
  funext
  ext
  · funext
    rw [ihsAction_atomMap, ihAction_atomMap, transConstrained_self]
    rfl
  · funext
    rw [ihsAction_litterMap, ihAction_litterMap, transConstrained_self]
    rfl

theorem constrainedAction_mono {π : StructApprox β} {s t : Set (SupportCondition β)} {hs : Small s}
    {ht : Small t} (h : s ⊆ t) : constrainedAction π s hs ≤ constrainedAction π t ht :=
  fun _ =>
  ⟨⟨fun _ ha => ⟨ha.choose, h ha.choose_spec.1, ha.choose_spec.2⟩, fun _ _ => rfl⟩,
    ⟨fun _ hL => ⟨hL.choose, h hL.choose_spec.1, hL.choose_spec.2⟩, fun _ _ => rfl⟩⟩

theorem ihAction_le_constrainedAction {π : StructApprox β} {s : Set (SupportCondition β)}
    {hs : Small s} (c : SupportCondition β) (hc : ∃ d : SupportCondition β, d ∈ s ∧ c ≤ d) :
    ihAction (π.foaHypothesis : HypAction c) ≤ constrainedAction π s hs :=
  fun _ =>
  ⟨⟨fun _ ha => ⟨hc.choose, hc.choose_spec.1, _root_.trans ha.to_reflTransGen hc.choose_spec.2⟩,
    fun _ _ => rfl⟩,
  ⟨fun _ hL => ⟨hc.choose, hc.choose_spec.1, _root_.trans hL.to_reflTransGen hc.choose_spec.2⟩,
    fun _ _ => rfl⟩⟩

theorem ihAction_eq_constrainedAction (π : StructApprox β) (c : SupportCondition β) :
    ihAction (π.foaHypothesis : HypAction c) =
      constrainedAction π {d | d ≺ c} (small_constrains c) := by
  funext
  ext
  · funext
    ext
    simp only [ihAction_atomMap, foaHypothesis_atomImage, Part.mem_mk_iff, SupportCondition.lt_iff,
      Relation.TransGen.tail'_iff, exists_prop, constrainedAction_atomMap, mem_setOf_eq,
      SupportCondition.le_iff, and_congr_left_iff]
    intro
    simp_rw [and_comm]
  · funext
    ext
    simp only [ihAction_litterMap, foaHypothesis_nearLitterImage, Part.mem_mk_iff,
      SupportCondition.lt_iff, Relation.TransGen.tail'_iff, exists_prop,
      constrainedAction_litterMap, mem_setOf_eq, SupportCondition.le_iff, and_congr_left_iff]
    intro
    simp_rw [and_comm]

theorem ihsAction_eq_constrainedAction (π : StructApprox β) (c d : SupportCondition β) :
    ihsAction π c d =
      constrainedAction π ({e | e ≺ c} ∪ {e | e ≺ d})
        ((small_constrains c).union (small_constrains d)) := by
  funext
  ext
  · funext
    ext
    simp only [ihsAction_atomMap, transConstrained, Part.mem_mk_iff, mem_union, mem_setOf_eq,
      exists_prop, constrainedAction_atomMap, and_congr_left_iff]
    simp only [SupportCondition.lt_iff, SupportCondition.le_iff, Relation.TransGen.tail'_iff]
    rintro rfl
    constructor
    · rintro (⟨b, hb₁, hb₂⟩ | ⟨b, hb₁, hb₂⟩)
      · exact ⟨b, Or.inl hb₂, hb₁⟩
      · exact ⟨b, Or.inr hb₂, hb₁⟩
    · rintro ⟨b, hb₁ | hb₁, hb₂⟩
      · exact Or.inl ⟨b, hb₂, hb₁⟩
      · exact Or.inr ⟨b, hb₂, hb₁⟩
  · funext
    ext
    simp only [ihsAction_litterMap, transConstrained, Part.mem_mk_iff, mem_union, mem_setOf_eq,
      exists_prop, constrainedAction_litterMap, and_congr_left_iff]
    simp only [SupportCondition.lt_iff, SupportCondition.le_iff, Relation.TransGen.tail'_iff]
    intro
    constructor
    · rintro (⟨b, hb₁, hb₂⟩ | ⟨b, hb₁, hb₂⟩)
      · exact ⟨b, Or.inl hb₂, hb₁⟩
      · exact ⟨b, Or.inr hb₂, hb₁⟩
    · rintro ⟨b, hb₁ | hb₁, hb₂⟩
      · exact Or.inl ⟨b, hb₂, hb₁⟩
      · exact Or.inr ⟨b, hb₂, hb₁⟩

theorem ihAction_le_ihsAction (π : StructApprox β) (c d : SupportCondition β) :
    ihAction (π.foaHypothesis : HypAction c) ≤ ihsAction π c d :=
  fun _ => ⟨⟨fun _ => Or.inl, fun _ _ => rfl⟩, ⟨fun _ => Or.inl, fun _ _ => rfl⟩⟩

theorem ihAction_le {π : StructApprox β} {c d : SupportCondition β} (h : c ≤ d) :
    ihAction (π.foaHypothesis : HypAction c) ≤ ihAction (π.foaHypothesis : HypAction d) := by
  refine' fun B => ⟨⟨_, fun a h => rfl⟩, ⟨_, fun L h => rfl⟩⟩
  · intro a ha
    exact Relation.TransGen.trans_left ha h
  · intro a ha
    exact Relation.TransGen.trans_left ha h

theorem transGen_constrains_of_mem_designatedSupport {A : ExtendedIndex β} {L : Litter}
    {h : InflexibleCoe A L} {γ δ ε : Λ} [LeLevel γ] [LtLevel δ] [LtLevel ε]
    {hδ : (δ : TypeIndex) < γ} {hε : (ε : TypeIndex) < γ}
    (hδε : (δ : TypeIndex) ≠ ε) {C : Path (h.path.δ : TypeIndex) γ} {t : Tangle δ}
    {d : SupportCondition h.path.δ}
    (hd₂ : ⟨(C.cons hε).cons (bot_lt_coe _),
      inr (fuzz hδε t).toNearLitter⟩ ≤ d)
    (hd : ⟨(h.path.B.cons h.path.hδ).comp d.path, d.value⟩ ≺ ⟨A, inr L.toNearLitter⟩)
    {B : ExtendedIndex δ} {a : Atom} (hc : ⟨B, inl a⟩ ∈ (designatedSupport t).carrier) :
    (⟨(h.path.B.cons h.path.hδ).comp ((C.cons hδ).comp B), inl a⟩ : SupportCondition β) <
      ⟨A, inr L.toNearLitter⟩ := by
  refine' Relation.TransGen.tail' _ hd
  refine' le_comp (c := ⟨_, inl a⟩) _ (h.path.B.cons h.path.hδ)
  refine' Relation.ReflTransGen.trans _ hd₂
  exact Relation.ReflTransGen.single (Constrains.fuzz hδ hε hδε C t _ hc)

end StructApprox

end ConNF