; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=7 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM

;
; This is an evolved example to stress test SCC parameter attribute propagation.
; The SCC in this test is made up of the following six function, three of which
; are internal and three externally visible:
;
; static int *internal_ret0_nw(int *n0, int *w0);
; static int *internal_ret1_rw(int *r0, int *w0);
; static int *internal_ret1_rrw(int *r0, int *r1, int *w0);
;        int *external_ret2_nrw(int *n0, int *r0, int *w0);
;        int *external_sink_ret2_nrw(int *n0, int *r0, int *w0);
;        int *external_source_ret2_nrw(int *n0, int *r0, int *w0);
;
; The top four functions call each other while the "sink" function will not
; call anything and the "source" function will not be called in this module.
; The names of the functions define the returned parameter (X for "_retX_"),
; as well as how the parameters are (transitively) used (n = readnone,
; r = readonly, w = writeonly).
;
; What we should see is something along the lines of:
;   1 - Number of functions marked as norecurse
;   6 - Number of functions marked argmemonly
;   6 - Number of functions marked as nounwind
;  16 - Number of arguments marked nocapture
;   4 - Number of arguments marked readnone
;   6 - Number of arguments marked writeonly
;   6 - Number of arguments marked readonly
;   6 - Number of arguments marked returned
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define i32* @external_ret2_nrw(i32* %n0, i32* %r0, i32* %w0) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind
; IS__TUNIT____-LABEL: define {{[^@]+}}@external_ret2_nrw
; IS__TUNIT____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[R0:%.*]], i32* nofree returned [[W0:%.*]]) #[[ATTR0:[0-9]+]] {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret0_nw(i32* nofree [[N0]], i32* nofree [[W0]]) #[[ATTR3:[0-9]+]]
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret1_rrw(i32* nofree align 4 [[R0]], i32* nofree align 4 [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL2:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree readonly align 4 [[R0]], i32* nofree writeonly "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL3:%.*]] = call i32* @internal_ret1_rw(i32* nofree align 4 [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    ret i32* [[W0]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree nosync nounwind
; IS__CGSCC____-LABEL: define {{[^@]+}}@external_ret2_nrw
; IS__CGSCC____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[R0:%.*]], i32* nofree returned [[W0:%.*]]) #[[ATTR0:[0-9]+]] {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret0_nw(i32* nofree [[N0]], i32* nofree [[W0]]) #[[ATTR2:[0-9]+]]
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret1_rrw(i32* nofree align 4 [[R0]], i32* nofree align 4 [[R0]], i32* nofree [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL2:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree readonly align 4 [[R0]], i32* nofree writeonly [[W0]]) #[[ATTR3:[0-9]+]]
; IS__CGSCC____-NEXT:    [[CALL3:%.*]] = call i32* @internal_ret1_rw(i32* nofree align 4 [[R0]], i32* nofree [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    ret i32* [[W0]]
;
entry:
  %call = call i32* @internal_ret0_nw(i32* %n0, i32* %w0)
  %call1 = call i32* @internal_ret1_rrw(i32* %r0, i32* %r0, i32* %w0)
  %call2 = call i32* @external_sink_ret2_nrw(i32* %n0, i32* %r0, i32* %w0)
  %call3 = call i32* @internal_ret1_rw(i32* %r0, i32* %w0)
  ret i32* %call3
}

define internal i32* @internal_ret0_nw(i32* %n0, i32* %w0) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind
; IS__TUNIT____-LABEL: define {{[^@]+}}@internal_ret0_nw
; IS__TUNIT____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[R0:%.*]] = alloca i32, align 4
; IS__TUNIT____-NEXT:    [[R1:%.*]] = alloca i32, align 4
; IS__TUNIT____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32* [[N0]], null
; IS__TUNIT____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__TUNIT____:       if.then:
; IS__TUNIT____-NEXT:    br label [[RETURN:%.*]]
; IS__TUNIT____:       if.end:
; IS__TUNIT____-NEXT:    store i32 3, i32* [[R0]], align 4
; IS__TUNIT____-NEXT:    store i32 5, i32* [[R1]], align 4
; IS__TUNIT____-NEXT:    store i32 1, i32* [[W0]], align 4
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL2:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL3:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL4:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R1]], i32* nofree nonnull writeonly align 4 dereferenceable(4) "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL5:%.*]] = call i32* @internal_ret0_nw(i32* nofree [[N0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    br label [[RETURN]]
; IS__TUNIT____:       return:
; IS__TUNIT____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL5]], [[IF_END]] ], [ [[N0]], [[IF_THEN]] ]
; IS__TUNIT____-NEXT:    ret i32* [[RETVAL_0]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree nosync nounwind
; IS__CGSCC____-LABEL: define {{[^@]+}}@internal_ret0_nw
; IS__CGSCC____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[R0:%.*]] = alloca i32, align 4
; IS__CGSCC____-NEXT:    [[R1:%.*]] = alloca i32, align 4
; IS__CGSCC____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32* [[N0]], null
; IS__CGSCC____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__CGSCC____:       if.then:
; IS__CGSCC____-NEXT:    br label [[RETURN:%.*]]
; IS__CGSCC____:       if.end:
; IS__CGSCC____-NEXT:    store i32 3, i32* [[R0]], align 4
; IS__CGSCC____-NEXT:    store i32 5, i32* [[R1]], align 4
; IS__CGSCC____-NEXT:    store i32 1, i32* [[W0]], align 4
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL2:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL3:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    [[CALL4:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R1]], i32* nofree nonnull writeonly align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    [[CALL5:%.*]] = call i32* @internal_ret0_nw(i32* nofree [[N0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    br label [[RETURN]]
; IS__CGSCC____:       return:
; IS__CGSCC____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL5]], [[IF_END]] ], [ [[N0]], [[IF_THEN]] ]
; IS__CGSCC____-NEXT:    ret i32* [[RETVAL_0]]
;
entry:
  %r0 = alloca i32, align 4
  %r1 = alloca i32, align 4
  %tobool = icmp ne i32* %n0, null
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  br label %return

if.end:                                           ; preds = %entry
  store i32 3, i32* %r0, align 4
  store i32 5, i32* %r1, align 4
  store i32 1, i32* %w0, align 4
  %call = call i32* @internal_ret1_rrw(i32* %r0, i32* %r1, i32* %w0)
  %call1 = call i32* @external_ret2_nrw(i32* %n0, i32* %r0, i32* %w0)
  %call2 = call i32* @external_ret2_nrw(i32* %n0, i32* %r1, i32* %w0)
  %call3 = call i32* @external_sink_ret2_nrw(i32* %n0, i32* %r0, i32* %w0)
  %call4 = call i32* @external_sink_ret2_nrw(i32* %n0, i32* %r1, i32* %w0)
  %call5 = call i32* @internal_ret0_nw(i32* %n0, i32* %w0)
  br label %return

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32* [ %call5, %if.end ], [ %n0, %if.then ]
  ret i32* %retval.0
}

define internal i32* @internal_ret1_rrw(i32* %r0, i32* %r1, i32* %w0) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind
; IS__TUNIT____-LABEL: define {{[^@]+}}@internal_ret1_rrw
; IS__TUNIT____-SAME: (i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0:%.*]], i32* nofree align 4 [[R1:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[TMP0:%.*]] = load i32, i32* [[R0]], align 4
; IS__TUNIT____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32 [[TMP0]], 0
; IS__TUNIT____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__TUNIT____:       if.then:
; IS__TUNIT____-NEXT:    br label [[RETURN:%.*]]
; IS__TUNIT____:       if.end:
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[TMP1:%.*]] = load i32, i32* [[R0]], align 4
; IS__TUNIT____-NEXT:    [[TMP2:%.*]] = load i32, i32* [[R1]], align 4
; IS__TUNIT____-NEXT:    [[ADD:%.*]] = add nsw i32 [[TMP1]], [[TMP2]]
; IS__TUNIT____-NEXT:    store i32 [[ADD]], i32* [[W0]], align 4
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret1_rw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL2:%.*]] = call i32* @internal_ret0_nw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL3:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[W0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL4:%.*]] = call i32* @external_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL5:%.*]] = call i32* @external_ret2_nrw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL6:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nocapture nofree nonnull readonly align 4 dereferenceable(4) [[R1]], i32* nofree nonnull writeonly align 4 dereferenceable(4) "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL7:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL8:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    br label [[RETURN]]
; IS__TUNIT____:       return:
; IS__TUNIT____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL8]], [[IF_END]] ], [ [[R1]], [[IF_THEN]] ]
; IS__TUNIT____-NEXT:    ret i32* undef
;
; IS__CGSCC____: Function Attrs: argmemonly nofree nosync nounwind
; IS__CGSCC____-LABEL: define {{[^@]+}}@internal_ret1_rrw
; IS__CGSCC____-SAME: (i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0:%.*]], i32* nofree align 4 [[R1:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[TMP0:%.*]] = load i32, i32* [[R0]], align 4
; IS__CGSCC____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32 [[TMP0]], 0
; IS__CGSCC____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__CGSCC____:       if.then:
; IS__CGSCC____-NEXT:    br label [[RETURN:%.*]]
; IS__CGSCC____:       if.end:
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[TMP1:%.*]] = load i32, i32* [[R0]], align 4
; IS__CGSCC____-NEXT:    [[TMP2:%.*]] = load i32, i32* [[R1]], align 4
; IS__CGSCC____-NEXT:    [[ADD:%.*]] = add nsw i32 [[TMP1]], [[TMP2]]
; IS__CGSCC____-NEXT:    store i32 [[ADD]], i32* [[W0]], align 4
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret1_rw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL2:%.*]] = call i32* @internal_ret0_nw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL3:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[W0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL4:%.*]] = call i32* @external_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL5:%.*]] = call i32* @external_ret2_nrw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL6:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nocapture nofree nonnull readonly align 4 dereferenceable(4) [[R1]], i32* nofree nonnull writeonly align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    [[CALL7:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    [[CALL8:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[R1]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    br label [[RETURN]]
; IS__CGSCC____:       return:
; IS__CGSCC____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL8]], [[IF_END]] ], [ [[R1]], [[IF_THEN]] ]
; IS__CGSCC____-NEXT:    ret i32* undef
;
entry:
  %0 = load i32, i32* %r0, align 4
  %tobool = icmp ne i32 %0, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  br label %return

if.end:                                           ; preds = %entry
  %call = call i32* @internal_ret1_rw(i32* %r0, i32* %w0)
  %1 = load i32, i32* %r0, align 4
  %2 = load i32, i32* %r1, align 4
  %add = add nsw i32 %1, %2
  store i32 %add, i32* %w0, align 4
  %call1 = call i32* @internal_ret1_rw(i32* %r1, i32* %w0)
  %call2 = call i32* @internal_ret0_nw(i32* %r0, i32* %w0)
  %call3 = call i32* @internal_ret0_nw(i32* %w0, i32* %w0)
  %call4 = call i32* @external_ret2_nrw(i32* %r0, i32* %r1, i32* %w0)
  %call5 = call i32* @external_ret2_nrw(i32* %r1, i32* %r0, i32* %w0)
  %call6 = call i32* @external_sink_ret2_nrw(i32* %r0, i32* %r1, i32* %w0)
  %call7 = call i32* @external_sink_ret2_nrw(i32* %r1, i32* %r0, i32* %w0)
  %call8 = call i32* @internal_ret0_nw(i32* %r1, i32* %w0)
  br label %return

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32* [ %call8, %if.end ], [ %r1, %if.then ]
  ret i32* %retval.0
}

define i32* @external_sink_ret2_nrw(i32* %n0, i32* %r0, i32* %w0) {
; CHECK: Function Attrs: argmemonly nofree norecurse nosync nounwind willreturn
; CHECK-LABEL: define {{[^@]+}}@external_sink_ret2_nrw
; CHECK-SAME: (i32* nofree [[N0:%.*]], i32* nocapture nofree readonly [[R0:%.*]], i32* nofree returned writeonly "no-capture-maybe-returned" [[W0:%.*]]) #[[ATTR1:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TOBOOL:%.*]] = icmp ne i32* [[N0]], null
; CHECK-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    br label [[RETURN:%.*]]
; CHECK:       if.end:
; CHECK-NEXT:    [[TMP0:%.*]] = load i32, i32* [[R0]], align 4
; CHECK-NEXT:    store i32 [[TMP0]], i32* [[W0]], align 4
; CHECK-NEXT:    br label [[RETURN]]
; CHECK:       return:
; CHECK-NEXT:    ret i32* [[W0]]
;
entry:
  %tobool = icmp ne i32* %n0, null
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  br label %return

if.end:                                           ; preds = %entry
  %0 = load i32, i32* %r0, align 4
  store i32 %0, i32* %w0, align 4
  br label %return

return:                                           ; preds = %if.end, %if.then
  ret i32* %w0
}

define internal i32* @internal_ret1_rw(i32* %r0, i32* %w0) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind
; IS__TUNIT____-LABEL: define {{[^@]+}}@internal_ret1_rw
; IS__TUNIT____-SAME: (i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[TMP0:%.*]] = load i32, i32* [[R0]], align 4
; IS__TUNIT____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32 [[TMP0]], 0
; IS__TUNIT____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__TUNIT____:       if.then:
; IS__TUNIT____-NEXT:    br label [[RETURN:%.*]]
; IS__TUNIT____:       if.end:
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[TMP1:%.*]] = load i32, i32* [[R0]], align 4
; IS__TUNIT____-NEXT:    store i32 [[TMP1]], i32* [[W0]], align 4
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret0_nw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL2:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[W0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL3:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) "no-capture-maybe-returned" [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    [[CALL4:%.*]] = call i32* @external_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    br label [[RETURN]]
; IS__TUNIT____:       return:
; IS__TUNIT____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL4]], [[IF_END]] ], [ [[W0]], [[IF_THEN]] ]
; IS__TUNIT____-NEXT:    ret i32* [[RETVAL_0]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree nosync nounwind
; IS__CGSCC____-LABEL: define {{[^@]+}}@internal_ret1_rw
; IS__CGSCC____-SAME: (i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[TMP0:%.*]] = load i32, i32* [[R0]], align 4
; IS__CGSCC____-NEXT:    [[TOBOOL:%.*]] = icmp ne i32 [[TMP0]], 0
; IS__CGSCC____-NEXT:    br i1 [[TOBOOL]], label [[IF_END:%.*]], label [[IF_THEN:%.*]]
; IS__CGSCC____:       if.then:
; IS__CGSCC____-NEXT:    br label [[RETURN:%.*]]
; IS__CGSCC____:       if.end:
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32* @internal_ret1_rrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[TMP1:%.*]] = load i32, i32* [[R0]], align 4
; IS__CGSCC____-NEXT:    store i32 [[TMP1]], i32* [[W0]], align 4
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32* @internal_ret0_nw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL2:%.*]] = call i32* @internal_ret0_nw(i32* nofree nonnull align 4 dereferenceable(4) [[W0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    [[CALL3:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nocapture nofree noundef nonnull readonly align 4 dereferenceable(4) [[R0]], i32* nofree nonnull writeonly align 4 dereferenceable(4) [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    [[CALL4:%.*]] = call i32* @external_ret2_nrw(i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree noundef nonnull align 4 dereferenceable(4) [[R0]], i32* nofree nonnull align 4 dereferenceable(4) [[W0]]) #[[ATTR2]]
; IS__CGSCC____-NEXT:    br label [[RETURN]]
; IS__CGSCC____:       return:
; IS__CGSCC____-NEXT:    [[RETVAL_0:%.*]] = phi i32* [ [[CALL4]], [[IF_END]] ], [ [[W0]], [[IF_THEN]] ]
; IS__CGSCC____-NEXT:    ret i32* [[RETVAL_0]]
;
entry:
  %0 = load i32, i32* %r0, align 4
  %tobool = icmp ne i32 %0, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  br label %return

if.end:                                           ; preds = %entry
  %call = call i32* @internal_ret1_rrw(i32* %r0, i32* %r0, i32* %w0)
  %1 = load i32, i32* %r0, align 4
  store i32 %1, i32* %w0, align 4
  %call1 = call i32* @internal_ret0_nw(i32* %r0, i32* %w0)
  %call2 = call i32* @internal_ret0_nw(i32* %w0, i32* %w0)
  %call3 = call i32* @external_sink_ret2_nrw(i32* %r0, i32* %r0, i32* %w0)
  %call4 = call i32* @external_ret2_nrw(i32* %r0, i32* %r0, i32* %w0)
  br label %return

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32* [ %call4, %if.end ], [ %w0, %if.then ]
  ret i32* %retval.0
}

define i32* @external_source_ret2_nrw(i32* %n0, i32* %r0, i32* %w0) {
; IS__TUNIT____: Function Attrs: argmemonly nofree norecurse nosync nounwind
; IS__TUNIT____-LABEL: define {{[^@]+}}@external_source_ret2_nrw
; IS__TUNIT____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[R0:%.*]], i32* nofree returned [[W0:%.*]]) #[[ATTR2:[0-9]+]] {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree readonly [[R0]], i32* nofree writeonly "no-capture-maybe-returned" [[W0]]) #[[ATTR4:[0-9]+]]
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__TUNIT____-NEXT:    ret i32* [[W0]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree nosync nounwind
; IS__CGSCC____-LABEL: define {{[^@]+}}@external_source_ret2_nrw
; IS__CGSCC____-SAME: (i32* nofree [[N0:%.*]], i32* nofree [[R0:%.*]], i32* nofree [[W0:%.*]]) #[[ATTR0]] {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32* @external_sink_ret2_nrw(i32* nofree [[N0]], i32* nocapture nofree readonly [[R0]], i32* nofree writeonly [[W0]]) #[[ATTR4:[0-9]+]]
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32* @external_ret2_nrw(i32* nofree [[N0]], i32* nofree [[R0]], i32* nofree [[W0]]) #[[ATTR3]]
; IS__CGSCC____-NEXT:    ret i32* [[CALL1]]
;
entry:
  %call = call i32* @external_sink_ret2_nrw(i32* %n0, i32* %r0, i32* %w0)
  %call1 = call i32* @external_ret2_nrw(i32* %n0, i32* %r0, i32* %w0)
  ret i32* %call1
}

; Verify that we see only expected attribute sets, the above lines only check
; for a subset relation.
;.
; IS__TUNIT____: attributes #[[ATTR0]] = { argmemonly nofree nosync nounwind }
; IS__TUNIT____: attributes #[[ATTR1]] = { argmemonly nofree norecurse nosync nounwind willreturn }
; IS__TUNIT____: attributes #[[ATTR2]] = { argmemonly nofree norecurse nosync nounwind }
; IS__TUNIT____: attributes #[[ATTR3]] = { nofree nosync nounwind }
; IS__TUNIT____: attributes #[[ATTR4]] = { nofree nosync nounwind willreturn }
;.
; IS__CGSCC____: attributes #[[ATTR0]] = { argmemonly nofree nosync nounwind }
; IS__CGSCC____: attributes #[[ATTR1]] = { argmemonly nofree norecurse nosync nounwind willreturn }
; IS__CGSCC____: attributes #[[ATTR2]] = { nofree nosync nounwind }
; IS__CGSCC____: attributes #[[ATTR3]] = { nounwind }
; IS__CGSCC____: attributes #[[ATTR4]] = { nounwind willreturn }
;.
